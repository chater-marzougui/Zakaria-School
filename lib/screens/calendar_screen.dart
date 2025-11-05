import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../l10n/app_localizations.dart';
import '../models/structs.dart' as structs;
import 'calendar/calendar_header.dart';
import 'calendar/calendar_legend.dart';
import 'calendar/calendar_grid.dart';
import 'calendar/day_details_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedWeekStart = DateTime.now();
  double _zoomLevel = 1.0;

  @override
  void initState() {
    super.initState();
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

  void _goToToday() {
    setState(() {
      _selectedWeekStart = _getStartOfWeek(DateTime.now());
    });
  }

  void _updateZoom(double delta) {
    setState(() {
      _zoomLevel = (_zoomLevel + delta).clamp(0.5, 2.0);
    });
  }

  void _navigateToDayDetails(DateTime date, List<structs.Session> sessions) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DayDetailsScreen(
          date: date,
          sessions: sessions,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final weekEnd = _selectedWeekStart.add(const Duration(days: 6));

    return Scaffold(
      appBar: AppBar(
        title: Text(t.calendar),
        actions: [
          IconButton(
            icon: const Icon(Icons.zoom_in),
            onPressed: () => _updateZoom(0.1),
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out),
            onPressed: () => _updateZoom(-0.1),
          ),
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: _goToToday,
          ),
        ],
      ),
      body: Column(
        children: [
          CalendarHeader(
            weekStart: _selectedWeekStart,
            weekEnd: weekEnd,
            onNavigateWeek: _navigateWeek,
          ),
          const CalendarLegend(),
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

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('candidates').snapshots(),
                  builder: (context, candidatesSnapshot) {
                    if (!candidatesSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final candidatesMap = <String, structs.Candidate>{};
                    for (var doc in candidatesSnapshot.data!.docs) {
                      final candidate = structs.Candidate.fromFirestore(doc);
                      candidatesMap[candidate.id] = candidate;
                    }

                    return CalendarGrid(
                      weekStart: _selectedWeekStart,
                      sessions: sessions,
                      candidatesMap: candidatesMap,
                      zoomLevel: _zoomLevel,
                      onDayTap: _navigateToDayDetails,
                    );
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
}