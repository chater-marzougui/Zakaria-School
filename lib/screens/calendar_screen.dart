import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../models/structs.dart' as structs;
import '../helpers/time_utils.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedWeekStart = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Set to start of week (Monday)
    _selectedWeekStart = _getStartOfWeek(DateTime.now());
  }

  DateTime _getStartOfWeek(DateTime date) {
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }

  void _navigateWeek(int weeks) {
    setState(() {
      _selectedWeekStart = _selectedWeekStart.add(Duration(days: 7 * weeks));
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;

    final weekEnd = _selectedWeekStart.add(const Duration(days: 6));

    return Scaffold(
      appBar: AppBar(
        title: Text(t.calendar),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              setState(() {
                _selectedWeekStart = _getStartOfWeek(DateTime.now());
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Week Navigation
          Container(
            padding: const EdgeInsets.all(16),
            color: theme.colorScheme.primaryContainer.withAlpha(50),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _navigateWeek(-1),
                ),
                Text(
                  '${DateFormat('dd MMM').format(_selectedWeekStart)} - ${DateFormat('dd MMM yyyy').format(weekEnd)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _navigateWeek(1),
                ),
              ],
            ),
          ),

          // Legend
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _LegendItem(color: Colors.green, label: t.scheduled),
                _LegendItem(color: Colors.blue, label: t.done),
                _LegendItem(color: Colors.orange, label: t.rescheduled),
                _LegendItem(color: Colors.red, label: t.missed),
              ],
            ),
          ),

          // Calendar Grid
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('sessions')
                  .where('date',
                      isGreaterThanOrEqualTo: Timestamp.fromDate(_selectedWeekStart))
                  .where('date',
                      isLessThan: Timestamp.fromDate(weekEnd.add(const Duration(days: 1))))
                  .snapshots(),
              builder: (context, sessionsSnapshot) {
                if (sessionsSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (sessionsSnapshot.hasError) {
                  return Center(child: Text('Error: ${sessionsSnapshot.error}'));
                }

                final sessions = sessionsSnapshot.data?.docs
                    .map((doc) => structs.Session.fromFirestore(doc))
                    .toList() ?? [];

                if (sessions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: 64,
                          color: theme.textTheme.bodyMedium?.color?.withAlpha(100),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          t.noSessionsThisWeek,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.textTheme.bodyMedium?.color?.withAlpha(150),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Fetch all candidates to avoid N+1 query issue
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('candidates').snapshots(),
                  builder: (context, candidatesSnapshot) {
                    if (!candidatesSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    // Create a map for quick lookups
                    final candidatesMap = <String, structs.Candidate>{};
                    for (var doc in candidatesSnapshot.data!.docs) {
                      final candidate = structs.Candidate.fromFirestore(doc);
                      candidatesMap[candidate.id] = candidate;
                    }

                    return _buildImprovedCalendarGrid(sessions, candidatesMap);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/add-session');
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildImprovedCalendarGrid(List<structs.Session> sessions, Map<String, structs.Candidate> candidatesMap) {
    final theme = Theme.of(context);
    
    // Generate time slots with 15-minute intervals (8:00 AM to 8:00 PM)
    final List<int> timeSlots = [];
    for (int hour = 8; hour <= 20; hour++) {
      for (int minute = 0; minute < 60; minute += 15) {
        timeSlots.add(hour * 60 + minute); // Store as minutes since midnight
      }
    }
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                // Time column header
                SizedBox(
                  width: 70,
                  height: 50,
                  child: Center(
                    child: Text(
                      'Time',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // Day headers
                ...List.generate(7, (index) {
                  final date = _selectedWeekStart.add(Duration(days: index));
                  final isToday = _isSameDay(date, DateTime.now());
                  return Container(
                    width: 150,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isToday 
                          ? theme.colorScheme.primary.withAlpha(30)
                          : null,
                      border: Border.all(
                        color: theme.dividerColor,
                        width: 0.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('EEE').format(date),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isToday ? theme.colorScheme.primary : null,
                          ),
                        ),
                        Text(
                          DateFormat('dd').format(date),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isToday ? theme.colorScheme.primary : null,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
            // Time rows
            ...timeSlots.map((timeInMinutes) {
              final hour = timeInMinutes ~/ 60;
              final minute = timeInMinutes % 60;
              final timeString = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
              
              return Row(
                children: [
                  // Time label
                  Container(
                    width: 70,
                    height: 40,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: theme.dividerColor,
                        width: 0.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        timeString,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: minute == 0 ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                  // Day cells
                  ...List.generate(7, (dayIndex) {
                    final date = _selectedWeekStart.add(Duration(days: dayIndex));
                    final isToday = _isSameDay(date, DateTime.now());
                    
                    // Find all sessions that occupy this time slot
                    final sessionsAtTime = _getSessionsAtTimeSlot(
                      sessions,
                      date,
                      timeInMinutes,
                    );
                    
                    return Container(
                      width: 150,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isToday 
                            ? theme.colorScheme.primary.withAlpha(10)
                            : null,
                        border: Border.all(
                          color: theme.dividerColor,
                          width: 0.5,
                        ),
                      ),
                      child: sessionsAtTime.isEmpty
                          ? null
                          : _buildSessionCells(sessionsAtTime, timeInMinutes, candidatesMap),
                    );
                  }),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  List<structs.Session> _getSessionsAtTimeSlot(
    List<structs.Session> allSessions,
    DateTime date,
    int timeInMinutes,
  ) {
    return allSessions.where((session) {
      if (!_isSameDay(session.date, date)) return false;
      
      final sessionStart = TimeUtils.timeToMinutes(session.startTime);
      final sessionEnd = TimeUtils.timeToMinutes(session.endTime);
      
      // Check if this time slot falls within the session
      return timeInMinutes >= sessionStart && timeInMinutes < sessionEnd;
    }).toList();
  }

  Widget _buildSessionCells(List<structs.Session> sessions, int timeInMinutes, Map<String, structs.Candidate> candidatesMap) {
    if (sessions.isEmpty) return const SizedBox();
    
    // If multiple sessions overlap, show them side by side
    if (sessions.length == 1) {
      return _buildSessionCell(sessions[0], timeInMinutes, candidatesMap, isFirst: true, width: 150);
    } else {
      // Multiple sessions - show side by side
      final cellWidth = 150.0 / sessions.length;
      return Row(
        children: sessions.map((session) {
          final isFirst = sessions.indexOf(session) == 0;
          return _buildSessionCell(session, timeInMinutes, candidatesMap, isFirst: isFirst, width: cellWidth);
        }).toList(),
      );
    }
  }

  Widget _buildSessionCell(structs.Session session, int timeInMinutes, Map<String, structs.Candidate> candidatesMap, {required bool isFirst, required double width}) {
    final theme = Theme.of(context);
    final sessionStart = TimeUtils.timeToMinutes(session.startTime);
    
    // Only show content on the first time slot of the session
    final showContent = timeInMinutes == sessionStart;
    
    return GestureDetector(
      onTap: () => _showSessionDetails(context, session),
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: _getStatusColor(session.status),
          border: Border(
            left: BorderSide(
              color: Colors.white,
              width: isFirst ? 0 : 1,
            ),
          ),
        ),
        padding: const EdgeInsets.all(2),
        child: showContent
            ? _buildSessionContent(session, candidatesMap)
            : null,
      ),
    );
  }

  Widget? _buildSessionContent(structs.Session session, Map<String, structs.Candidate> candidatesMap) {
    final theme = Theme.of(context);
    final candidate = candidatesMap[session.candidateId];
    
    if (candidate == null) return null;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          candidate.name,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 9,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          '${session.startTime}-${session.endTime}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.white,
            fontSize: 8,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'done':
        return Colors.blue;
      case 'missed':
        return Colors.red;
      case 'rescheduled':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  void _showSessionDetails(BuildContext context, structs.Session session) {
    final t = AppLocalizations.of(context)!;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.sessionDetails),
        content: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('candidates')
              .doc(session.candidateId)
              .get(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const CircularProgressIndicator();
            }
            
            final candidate = structs.Candidate.fromFirestore(snapshot.data!);
            
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${t.candidate}: ${candidate.name}'),
                const SizedBox(height: 8),
                Text('${t.date}: ${DateFormat('dd/MM/yyyy').format(session.date)}'),
                Text('${t.time}: ${session.startTime} - ${session.endTime}'),
                Text('${t.duration}: ${session.durationInHours.toStringAsFixed(2)} hours'),
                Text('${t.status}: ${session.status}'),
                Text('${t.paymentStatus}: ${session.paymentStatus}'),
                if (session.note.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('${t.notes}: ${session.note}'),
                ],
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t.close),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(
                context,
                '/add-session',
                arguments: session,
              );
            },
            child: Text(t.edit),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}
