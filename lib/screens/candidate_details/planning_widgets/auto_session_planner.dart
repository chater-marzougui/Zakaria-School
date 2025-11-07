import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/structs.dart' as structs;
import '../../../widgets/widgets.dart';
import '../../../helpers/time_utils.dart';
import '../../../services/db_service.dart';

class AutoSessionPlanner {
  static Future<void> showAutoPlanningDialog(
    BuildContext context,
    structs.Candidate candidate,
  ) async {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;
    final hoursController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.auto_awesome, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Auto Session Planning',
                style: theme.textTheme.titleLarge,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How many hours would you like to schedule for ${candidate.name}?',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: hoursController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Hours to Schedule',
                prefixIcon: Icon(Icons.access_time),
                suffixText: 'hours',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                hintText: 'e.g., 10',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            Text(
              'The system will try to fit sessions into the instructor\'s schedule based on the candidate\'s availability.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withAlpha(150),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(t.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final hoursText = hoursController.text.trim();
              final hours = double.tryParse(hoursText);

              if (hours == null || hours <= 0) {
                showCustomSnackBar(
                  dialogContext,
                  'Please enter a valid number of hours',
                  type: SnackBarType.error,
                );
                return;
              }

              Navigator.pop(dialogContext);
              
              // Show loading dialog
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (ctx) => AlertDialog(
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Planning sessions...'),
                    ],
                  ),
                ),
              );

              try {
                final result = await _planSessions(candidate, hours);
                
                if (!context.mounted) return;
                Navigator.pop(context); // Close loading dialog
                
                if (result['success']) {
                  _showSuccessDialog(context, result);
                } else {
                  _showErrorDialog(context, result);
                }
              } catch (e) {
                if (!context.mounted) return;
                Navigator.pop(context); // Close loading dialog
                
                showCustomSnackBar(
                  context,
                  'Error: $e',
                  type: SnackBarType.error,
                );
              }
            },
            child: Text('Plan Sessions'),
          ),
        ],
      ),
    ).then((_) {
      hoursController.dispose();
    });
  }

  static Future<Map<String, dynamic>> _planSessions(
    structs.Candidate candidate,
    double requestedHours,
  ) async {
    // Get instructor's existing sessions
    final instructorId = candidate.assignedInstructor;
    
    if (instructorId.isEmpty) {
      return {
        'success': false,
        'error': 'No instructor assigned to this candidate',
      };
    }

    // Get all sessions for this instructor from now until exam date (or 60 days if no exam)
    final now = DateTime.now();
    final endDate = candidate.examDate ?? now.add(Duration(days: 60));
    
    if (endDate.isBefore(now)) {
      return {
        'success': false,
        'error': 'Exam date has already passed',
      };
    }

    // Get instructor's sessions
    final instructorSessions = await FirebaseFirestore.instance
        .collection('sessions')
        .where('instructor_id', isEqualTo: instructorId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .get();

    // Get candidate's existing sessions
    final candidateSessions = await FirebaseFirestore.instance
        .collection('sessions')
        .where('candidate_id', isEqualTo: candidate.id)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .get();

    // Build a map of occupied time slots per day for instructor
    Map<String, List<structs.Session>> instructorSchedule = {};
    for (var doc in instructorSessions.docs) {
      final session = structs.Session.fromFirestore(doc);
      final dateKey = DateFormat('yyyy-MM-dd').format(session.date);
      instructorSchedule.putIfAbsent(dateKey, () => []);
      instructorSchedule[dateKey]!.add(session);
    }

    // Build a map of occupied time slots per day for candidate
    Map<String, List<structs.Session>> candidateSchedule = {};
    for (var doc in candidateSessions.docs) {
      final session = structs.Session.fromFirestore(doc);
      final dateKey = DateFormat('yyyy-MM-dd').format(session.date);
      candidateSchedule.putIfAbsent(dateKey, () => []);
      candidateSchedule[dateKey]!.add(session);
    }

    // Try to find available slots
    double hoursScheduled = 0.0;
    List<Map<String, dynamic>> newSessions = [];
    
    // Iterate through each day from now to exam date
    DateTime currentDate = DateTime(now.year, now.month, now.day);
    final examDateDay = DateTime(endDate.year, endDate.month, endDate.day);
    
    while (currentDate.isBefore(examDateDay) && hoursScheduled < requestedHours) {
      final dayOfWeek = _getDayOfWeek(currentDate.weekday);
      final dateKey = DateFormat('yyyy-MM-dd').format(currentDate);
      
      // Get candidate's availability for this day
      final candidateAvailability = candidate.availability[dayOfWeek] ?? [];
      
      if (candidateAvailability.isEmpty) {
        currentDate = currentDate.add(Duration(days: 1));
        continue;
      }

      // Get existing sessions for this day
      final instructorDaySessions = instructorSchedule[dateKey] ?? [];
      final candidateDaySessions = candidateSchedule[dateKey] ?? [];

      // Try to fit sessions in available slots
      for (var slot in candidateAvailability) {
        if (hoursScheduled >= requestedHours) break;
        
        // Check if this slot is free for both instructor and candidate
        final slotStartMinutes = TimeUtils.timeToMinutes(slot.startTime);
        final slotEndMinutes = TimeUtils.timeToMinutes(slot.endTime);
        
        bool instructorFree = _isSlotFree(instructorDaySessions, slot.startTime, slot.endTime);
        bool candidateFree = _isSlotFree(candidateDaySessions, slot.startTime, slot.endTime);
        
        if (instructorFree && candidateFree) {
          // Calculate session duration
          final duration = (slotEndMinutes - slotStartMinutes) / 60.0;
          final sessionHours = duration.clamp(0, requestedHours - hoursScheduled);
          
          // If we need less than the full slot, adjust end time
          String endTime = slot.endTime;
          if (sessionHours < duration) {
            final adjustedEndMinutes = slotStartMinutes + (sessionHours * 60).round();
            endTime = TimeUtils.minutesToTime(adjustedEndMinutes);
          }
          
          newSessions.add({
            'date': currentDate,
            'start_time': slot.startTime,
            'end_time': endTime,
            'duration': sessionHours,
          });
          
          hoursScheduled += sessionHours;
          
          // Add to candidate's schedule to avoid double-booking same day
          candidateDaySessions.add(structs.Session(
            id: 'temp',
            candidateId: candidate.id,
            instructorId: instructorId,
            date: currentDate,
            startTime: slot.startTime,
            endTime: endTime,
          ));
          
          if (hoursScheduled >= requestedHours) break;
        }
      }
      
      currentDate = currentDate.add(Duration(days: 1));
    }

    // Check if we could schedule all requested hours
    if (hoursScheduled < requestedHours) {
      final availableHours = hoursScheduled;
      return {
        'success': false,
        'error': 'Not enough available hours until exam',
        'available_hours': availableHours,
        'requested_hours': requestedHours,
      };
    }

    // Create the sessions in Firestore
    try {
      for (var sessionData in newSessions) {
        final session = structs.Session(
          id: '', // Will be set by Firestore
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
      
      return {
        'success': true,
        'sessions_created': newSessions.length,
        'hours_scheduled': hoursScheduled,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to create sessions: $e',
      };
    }
  }

  static bool _isSlotFree(List<structs.Session> sessions, String startTime, String endTime) {
    final startMinutes = TimeUtils.timeToMinutes(startTime);
    final endMinutes = TimeUtils.timeToMinutes(endTime);
    
    for (var session in sessions) {
      final sessionStart = TimeUtils.timeToMinutes(session.startTime);
      final sessionEnd = TimeUtils.timeToMinutes(session.endTime);
      
      // Check if there's any overlap
      if (startMinutes < sessionEnd && sessionStart < endMinutes) {
        return false;
      }
    }
    
    return true;
  }

  static String _getDayOfWeek(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Monday';
      case DateTime.tuesday:
        return 'Tuesday';
      case DateTime.wednesday:
        return 'Wednesday';
      case DateTime.thursday:
        return 'Thursday';
      case DateTime.friday:
        return 'Friday';
      case DateTime.saturday:
        return 'Saturday';
      case DateTime.sunday:
        return 'Sunday';
      default:
        return 'Monday';
    }
  }

  static void _showSuccessDialog(BuildContext context, Map<String, dynamic> result) {
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 12),
            Text('Success!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Successfully planned ${result['sessions_created']} sessions',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Total hours scheduled: ${result['hours_scheduled'].toStringAsFixed(1)} hours',
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  static void _showErrorDialog(BuildContext context, Map<String, dynamic> result) {
    final theme = Theme.of(context);
    
    String message = result['error'] ?? 'Unknown error';
    if (result.containsKey('available_hours')) {
      message += '\n\nAvailable hours: ${result['available_hours'].toStringAsFixed(1)}';
      message += '\nRequested hours: ${result['requested_hours'].toStringAsFixed(1)}';
    }
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: theme.colorScheme.error),
            SizedBox(width: 12),
            Text('Planning Failed'),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}
