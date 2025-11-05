import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../models/structs.dart' as structs;

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
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final sessions = snapshot.data?.docs
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

                return _buildCalendarGrid(sessions);
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

  Widget _buildCalendarGrid(List<structs.Session> sessions) {
    final theme = Theme.of(context);
    
    // Generate time slots (8 AM to 8 PM)
    final timeSlots = List.generate(13, (index) => index + 8);
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columnSpacing: 8,
          horizontalMargin: 8,
          headingRowHeight: 50,
          dataRowMinHeight: 60,
          dataRowMaxHeight: 65,
          columns: [
            DataColumn(
              label: SizedBox(
                width: 60,
                child: Text(
                  'Time',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            ...List.generate(7, (index) {
              final date = _selectedWeekStart.add(Duration(days: index));
              return DataColumn(
                label: SizedBox(
                  width: 100,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('EEE').format(date),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        DateFormat('dd').format(date),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
          rows: timeSlots.map((hour) {
            return DataRow(
              cells: [
                DataCell(
                  Text(
                    '${hour.toString().padLeft(2, '0')}:00',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                ...List.generate(7, (dayIndex) {
                  final date = _selectedWeekStart.add(Duration(days: dayIndex));
                  final sessionsAtTime = sessions.where((s) {
                    final startHour = int.parse(s.startTime.split(':')[0]);
                    return s.date.year == date.year &&
                        s.date.month == date.month &&
                        s.date.day == date.day &&
                        startHour == hour;
                  }).toList();

                  if (sessionsAtTime.isEmpty) {
                    return const DataCell(SizedBox(width: 100, height: 60));
                  }

                  return DataCell(
                    GestureDetector(
                      onTap: () {
                        _showSessionDetails(context, sessionsAtTime.first);
                      },
                      child: Container(
                        width: 100,
                        height: 55,
                        decoration: BoxDecoration(
                          color: _getStatusColor(sessionsAtTime.first.status),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('candidates')
                              .doc(sessionsAtTime.first.candidateId)
                              .get(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData && snapshot.data!.exists) {
                              final candidate = structs.Candidate.fromFirestore(snapshot.data!);
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    candidate.name,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${sessionsAtTime.first.startTime}-${sessionsAtTime.first.endTime}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              );
                            }
                            return const SizedBox();
                          },
                        ),
                      ),
                    ),
                  );
                }),
              ],
            );
          }).toList(),
        ),
      ),
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
