import 'dart:math';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../dialogs/auto_planning_dialog.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/structs.dart' as structs;
import '../../../widgets/widgets.dart';
import '../../../helpers/time_utils.dart';
import '../../../services/db_service.dart';

class AutoSessionPlanner {
  // Configuration constants
  static const int maxDaysBeforeExam = 30;
  static const int minDaysBetweenSessions = 2;
  static const double idealSessionDuration = 1.0; // hours
  static const double minSessionDuration = 1.0; // hours
  static const double maxSessionDuration = 3.0; // hours

  static void debugPrint(String label, Map<String, dynamic> data) {
    print('=' * 50);
    print('DEBUG: $label');
    data.forEach((key, value) {
      print('  $key: $value');
    });
    print('=' * 50);
  }

  static Future<void> showAutoPlanningDialog(
      BuildContext context,
      structs.Candidate candidate,
      ) async {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;

    await showDialog(
      context: context,
      builder: (dialogContext) => AutoPlanningDialog(
        candidate: candidate,
        theme: theme,
        t: t,
        onPlan: (hours) => _executePlanning(context, candidate, hours),
      ),
    );
  }

  static Future<void> _executePlanning(
      BuildContext context,
      structs.Candidate candidate,
      double hours,
      ) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (loadingContext) => PopScope(
        canPop: false,
        child: Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(AppLocalizations.of(context)!.planningSessions),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    try {
      final result = await _planSessions(candidate, hours);

      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      await Future.delayed(Duration(milliseconds: 100));
      if (!context.mounted) return;

      if (result['success']) {
        // Show confirmation dialog instead of creating immediately
        await _showConfirmationDialog(context, candidate, result);
      } else {
        _showErrorDialog(context, result);
      }
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      await Future.delayed(Duration(milliseconds: 100));
      if (!context.mounted) return;

      showCustomSnackBar(
        context,
        'Error: $e',
        type: SnackBarType.error,
      );
    }
  }

  static Future<Map<String, dynamic>> _planSessions(
      structs.Candidate candidate,
      double requestedHours,
      ) async {
    final instructorId = candidate.assignedInstructorId;

    debugPrint('_planSessions - Initial Input', {
      'candidateId': candidate.id,
      'candidateName': candidate.name,
      'instructorId': instructorId,
      'requestedHours': requestedHours,
      'examDate': candidate.examDate?.toString() ?? 'null',
      'availabilityKeys': candidate.availability.keys.toList().toString(),
    });

    if (instructorId.isEmpty) {
      return {
        'success': false,
        'error': 'No instructor assigned to this candidate',
      };
    }

    if (candidate.availability.isEmpty) {
      return {
        'success': false,
        'error': 'Candidate has no availability configured. Please set up availability first.',
      };
    }

    // Calculate date range with max 30 days cap
    final now = DateTime.now();
    DateTime endDate;

    if (candidate.examDate != null) {
      endDate = candidate.examDate!;

    } else {
      endDate = now.add(Duration(days: maxDaysBeforeExam));
    }

    debugPrint('Date Range', {
      'now': now.toString(),
      'endDate': endDate.toString(),
      'daysDifference': endDate.difference(now).inDays,
      'maxDaysCap': maxDaysBeforeExam,
    });

    if (endDate.isBefore(now)) {
      return {
        'success': false,
        'error': 'Exam date has already passed',
      };
    }

    // Get existing sessions
    final instructorSessions = await FirebaseFirestore.instance
        .collection('sessions')
        .where('instructor_id', isEqualTo: instructorId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .get();

    final candidateSessions = await FirebaseFirestore.instance
        .collection('sessions')
        .where('candidate_id', isEqualTo: candidate.id)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .get();

    // Build schedule maps
    Map<String, List<structs.Session>> instructorSchedule = {};
    for (var doc in instructorSessions.docs) {
      final session = structs.Session.fromFirestore(doc);
      final dateKey = DateFormat('yyyy-MM-dd').format(session.date);
      instructorSchedule.putIfAbsent(dateKey, () => []);
      instructorSchedule[dateKey]!.add(session);
    }

    Map<String, List<structs.Session>> candidateSchedule = {};
    for (var doc in candidateSessions.docs) {
      final session = structs.Session.fromFirestore(doc);
      final dateKey = DateFormat('yyyy-MM-dd').format(session.date);
      candidateSchedule.putIfAbsent(dateKey, () => []);
      candidateSchedule[dateKey]!.add(session);
    }

    // Find all available slots
    final availableSlots = _findAllAvailableSlots(
      candidate,
      now,
      endDate,
      instructorSchedule,
      candidateSchedule,
    );

    debugPrint('Available Slots Found', {
      'totalSlots': availableSlots.length,
      'totalHoursAvailable': availableSlots.fold(0.0, (sumT, slot) => sumT + slot['duration']),
    });

    if (availableSlots.isEmpty) {
      return {
        'success': false,
        'error': 'No available time slots found matching candidate and instructor availability',
      };
    }

    // Use smart distribution algorithm
    final selectedSessions = _distributeSessionsSmartly(
      availableSlots,
      requestedHours,
      now,
      endDate,
    );

    if (selectedSessions.isEmpty) {
      return {
        'success': false,
        'error': 'Could not create a viable schedule with the requested hours',
      };
    }

    final hoursScheduled = selectedSessions.fold(0.0, (sumT, s) => sumT + s['duration']);

    if (hoursScheduled < requestedHours) {
      return {
        'success': false,
        'error': 'Not enough available hours until exam',
        'available_hours': hoursScheduled,
        'requested_hours': requestedHours,
      };
    }

    debugPrint('Planning Summary', {
      'sessionsCreated': selectedSessions.length,
      'hoursScheduled': hoursScheduled,
      'requestedHours': requestedHours,
    });

    return {
      'success': true,
      'sessions': selectedSessions,
      'hours_scheduled': hoursScheduled,
      'candidate': candidate,
      'instructor_id': instructorId,
      'all_available_slots': availableSlots,
      'instructor_schedule': instructorSchedule,
      'candidate_schedule': candidateSchedule,
    };
  }

  static List<Map<String, dynamic>> _findAllAvailableSlots(
      structs.Candidate candidate,
      DateTime startDate,
      DateTime endDate,
      Map<String, List<structs.Session>> instructorSchedule,
      Map<String, List<structs.Session>> candidateSchedule,
      ) {
    List<Map<String, dynamic>> availableSlots = [];

    DateTime currentDate = DateTime(startDate.year, startDate.month, startDate.day);
    final examDateDay = DateTime(endDate.year, endDate.month, endDate.day);

    while (currentDate.isBefore(examDateDay)) {
      final dayOfWeek = _getDayOfWeek(currentDate.weekday);
      final dateKey = DateFormat('yyyy-MM-dd').format(currentDate);

      final candidateAvailability = candidate.availability[dayOfWeek] ?? [];

      if (candidateAvailability.isNotEmpty) {
        final instructorDaySessions = instructorSchedule[dateKey] ?? [];
        final candidateDaySessions = candidateSchedule[dateKey] ?? [];

        for (var slot in candidateAvailability) {
          if (_isSlotFree(instructorDaySessions, slot.startTime, slot.endTime) &&
              _isSlotFree(candidateDaySessions, slot.startTime, slot.endTime)) {

            final startMinutes = TimeUtils.timeToMinutes(slot.startTime);
            final endMinutes = TimeUtils.timeToMinutes(slot.endTime);
            final duration = (endMinutes - startMinutes) / 60.0;

            availableSlots.add({
              'date': currentDate,
              'start_time': slot.startTime,
              'end_time': slot.endTime,
              'duration': duration,
              'start_minutes': startMinutes,
              'end_minutes': endMinutes,
            });
          }
        }
      }

      currentDate = currentDate.add(Duration(days: 1));
    }

    return availableSlots;
  }

  static List<Map<String, dynamic>> _distributeSessionsSmartly(
      List<Map<String, dynamic>> availableSlots,
      double requestedHours,
      DateTime startDate,
      DateTime endDate,
      ) {
    List<Map<String, dynamic>> selectedSessions = [];
    double hoursScheduled = 0.0;

    // Calculate ideal number of sessions
    int idealSessionCount = (requestedHours / idealSessionDuration).ceil();
    int totalDays = endDate.difference(startDate).inDays;

    // Calculate ideal spacing (in days)
    int idealSpacing = totalDays > idealSessionCount
        ? (totalDays / idealSessionCount).floor()
        : minDaysBetweenSessions;

    if (idealSpacing < minDaysBetweenSessions) {
      idealSpacing = minDaysBetweenSessions;
    }

    debugPrint('Distribution Strategy', {
      'requestedHours': requestedHours,
      'idealSessionCount': idealSessionCount,
      'totalDays': totalDays,
      'idealSpacing': idealSpacing,
      'idealSessionDuration': idealSessionDuration,
    });

    // Sort slots by date
    availableSlots.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));

    DateTime? lastSessionDate;
    int slotIndex = 0;

    while (hoursScheduled < requestedHours && slotIndex < availableSlots.length) {
      final slot = availableSlots[slotIndex];
      final slotDate = slot['date'] as DateTime;

      // Check spacing from last session
      if (lastSessionDate != null) {
        int daysSinceLastSession = slotDate.difference(lastSessionDate).inDays;
        if (daysSinceLastSession < minDaysBetweenSessions) {
          slotIndex++;
          continue;
        }

        // Try to maintain ideal spacing
        if (daysSinceLastSession < idealSpacing &&
            hoursScheduled < requestedHours * 0.7) { // More flexible toward the end
          slotIndex++;
          continue;
        }
      }

      // Calculate session duration for this slot
      double remainingHours = requestedHours - hoursScheduled;
      double slotDuration = slot['duration'];

      // Prefer IDEAL_SESSION_DURATION, but adjust based on needs
      double sessionDuration;
      if (remainingHours <= minSessionDuration) {
        sessionDuration = remainingHours;
      } else if (remainingHours <= idealSessionDuration) {
        sessionDuration = remainingHours;
      } else {
        sessionDuration = idealSessionDuration.clamp(
          minSessionDuration,
          min(maxSessionDuration, slotDuration),
        );
      }

      // Ensure we don't exceed slot duration
      sessionDuration = min(sessionDuration, slotDuration);

      // Calculate end time based on session duration
      int sessionMinutes = (sessionDuration * 60).round();
      int sessionEndMinutes = slot['start_minutes'] + sessionMinutes;
      String sessionEndTime = TimeUtils.minutesToTime(sessionEndMinutes);

      selectedSessions.add({
        'date': slotDate,
        'start_time': slot['start_time'],
        'end_time': sessionEndTime,
        'duration': sessionDuration,
      });

      hoursScheduled += sessionDuration;
      lastSessionDate = slotDate;
      slotIndex++;
    }

    return selectedSessions;
  }

  static bool _isSlotFree(List<structs.Session> sessions, String startTime, String endTime) {
    final startMinutes = TimeUtils.timeToMinutes(startTime);
    final endMinutes = TimeUtils.timeToMinutes(endTime);

    for (var session in sessions) {
      final sessionStart = TimeUtils.timeToMinutes(session.startTime);
      final sessionEnd = TimeUtils.timeToMinutes(session.endTime);

      if (startMinutes < sessionEnd && sessionStart < endMinutes) {
        return false;
      }
    }

    return true;
  }

  static String _getDayOfWeek(int weekday) {
    switch (weekday) {
      case DateTime.monday: return 'monday';
      case DateTime.tuesday: return 'tuesday';
      case DateTime.wednesday: return 'wednesday';
      case DateTime.thursday: return 'thursday';
      case DateTime.friday: return 'friday';
      case DateTime.saturday: return 'saturday';
      case DateTime.sunday: return 'sunday';
      default: return 'monday';
    }
  }

  // NEW: Confirmation dialog with schedule viewer
  static Future<void> _showConfirmationDialog(
      BuildContext context,
      structs.Candidate candidate,
      Map<String, dynamic> result,
      ) async {
    final sessions = result['sessions'] as List<Map<String, dynamic>>;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ScheduleConfirmationDialog(
        candidate: candidate,
        proposedSessions: sessions,
        allAvailableSlots: result['all_available_slots'],
        instructorSchedule: result['instructor_schedule'],
        candidateSchedule: result['candidate_schedule'],
        instructorId: result['instructor_id'],
        onConfirm: (finalSessions) => _createSessions(context, finalSessions, candidate, result['instructor_id']),
      ),
    );
  }

  static Future<void> _createSessions(
      BuildContext context,
      List<Map<String, dynamic>> sessions,
      structs.Candidate candidate,
      String instructorId,
      ) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (loadingContext) => PopScope(
        canPop: false,
        child: Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(AppLocalizations.of(context)!.creatingSessions),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    try {
      for (var sessionData in sessions) {
        final session = structs.Session(
          id: '',
          candidateId: candidate.id,
          instructorId: instructorId,
          date: sessionData['date'],
          startTime: sessionData['start_time'],
          endTime: sessionData['end_time'],
          status: 'scheduled',
          paymentStatus: 'unpaid',
        );

        await DatabaseService.createSession(session, checkOverlap: false);
      }

      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // Close loading

      _showSuccessDialog(context, {
        'sessions_created': sessions.length,
        'hours_scheduled': sessions.fold(0.0, (sumT, s) => sumT + s['duration']),
      });
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // Close loading

      showCustomSnackBar(
        context,
        'Error creating sessions: $e',
        type: SnackBarType.error,
      );
    }
  }

  static void _showSuccessDialog(BuildContext context, Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 12),
            Text(AppLocalizations.of(context)!.success),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.successfullyCreatedSessions
                  .replaceAll('{count}', '${result['sessions_created']}'),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.totalHoursScheduled
                  .replaceAll('{hours}', result['hours_scheduled'].toStringAsFixed(1)),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.ok),
          ),
        ],
      ),
    );
  }

  static void _showErrorDialog(BuildContext context, Map<String, dynamic> result) {
    String message = result['error'] ?? 'Unknown error';
    if (result.containsKey('available_hours')) {
      message += '\n\nAvailable hours: ${result['available_hours'].toStringAsFixed(1)}';
      message += '\nRequested hours: ${result['requested_hours'].toStringAsFixed(1)}';
    }
    if (result.containsKey('days_until_planning')) {
      message += '\n\nCome back in ${result['days_until_planning']} days to start planning.';
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: Theme.of(context).colorScheme.error),
            SizedBox(width: 12),
            Text(AppLocalizations.of(context)!.planningFailed),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.ok),
          ),
        ],
      ),
    );
  }
}

// NEW: Schedule Confirmation Dialog Widget
class ScheduleConfirmationDialog extends StatefulWidget {
  final structs.Candidate candidate;
  final List<Map<String, dynamic>> proposedSessions;
  final List<Map<String, dynamic>> allAvailableSlots;
  final Map<String, List<structs.Session>> instructorSchedule;
  final Map<String, List<structs.Session>> candidateSchedule;
  final String instructorId;
  final Function(List<Map<String, dynamic>>) onConfirm;

  const ScheduleConfirmationDialog({
    super.key,
    required this.candidate,
    required this.proposedSessions,
    required this.allAvailableSlots,
    required this.instructorSchedule,
    required this.candidateSchedule,
    required this.instructorId,
    required this.onConfirm,
  });

  @override
  State<ScheduleConfirmationDialog> createState() => _ScheduleConfirmationDialogState();
}

class _ScheduleConfirmationDialogState extends State<ScheduleConfirmationDialog> {
  late List<Map<String, dynamic>> editableSessions;

  @override
  void initState() {
    super.initState();
    editableSessions = List.from(widget.proposedSessions);
  }

  void _removeSession(int index) {
    setState(() {
      editableSessions.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalHours = editableSessions.fold(0.0, (sumT, s) => sumT + (s['duration'] as double));

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.calendar_month, color: theme.primaryColor),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Confirm Schedule',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${editableSessions.length} sessions • ${totalHours.toStringAsFixed(1)} hours',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Divider(height: 32),

            // Sessions List
            Expanded(
              child: ListView.builder(
                itemCount: editableSessions.length,
                itemBuilder: (context, index) {
                  final session = editableSessions[index];
                  final date = session['date'] as DateTime;
                  final dateStr = DateFormat('EEE, MMM d, yyyy').format(date);

                  return Card(
                    margin: EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text('${index + 1}'),
                      ),
                      title: Text(dateStr),
                      subtitle: Text(
                        '${session['start_time']} - ${session['end_time']} (${session['duration'].toStringAsFixed(1)}h)',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit, size: 20),
                            onPressed: () {
                              // TODO: Show edit dialog
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, size: 20, color: Colors.red),
                            onPressed: () => _removeSession(index),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            Divider(height: 32),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
                SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: editableSessions.isEmpty
                      ? null
                      : () {
                    Navigator.pop(context);
                    widget.onConfirm(editableSessions);
                  },
                  icon: Icon(Icons.check),
                  label: Text(AppLocalizations.of(context)!.confirmAndCreate),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}