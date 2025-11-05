import 'package:flutter/material.dart';
import '../../models/structs.dart' as structs;
import 'day_column.dart';

class CalendarGrid extends StatelessWidget {
  final DateTime weekStart;
  final List<structs.Session> sessions;
  final Map<String, structs.Candidate> candidatesMap;
  final double zoomLevel;
  final Function(DateTime, List<structs.Session>) onDayTap;

  const CalendarGrid({
    super.key,
    required this.weekStart,
    required this.sessions,
    required this.candidatesMap,
    required this.zoomLevel,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Base hour height scaled by zoom
    final hourHeight = 60.0 * zoomLevel;
    
    // Generate hours from 8 AM to 8 PM
    final hours = List.generate(13, (index) => 8 + index);
    
    // Group sessions by day
    final sessionsByDay = <DateTime, List<structs.Session>>{};
    for (var session in sessions) {
      final dayKey = DateTime(session.date.year, session.date.month, session.date.day);
      sessionsByDay.putIfAbsent(dayKey, () => []).add(session);
    }

    return InteractiveViewer(
      constrained: false,
      boundaryMargin: const EdgeInsets.all(80),
      minScale: 0.5,
      maxScale: 3.0,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time column
          _buildTimeColumn(hours, hourHeight, theme),
          
          // Day columns
          ...List.generate(7, (dayIndex) {
            final date = weekStart.add(Duration(days: dayIndex));
            final dayKey = DateTime(date.year, date.month, date.day);
            final daySessions = sessionsByDay[dayKey] ?? [];
            
            return DayColumn(
              date: date,
              sessions: daySessions,
              candidatesMap: candidatesMap,
              hourHeight: hourHeight,
              hours: hours,
              onTap: () => onDayTap(date, daySessions),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTimeColumn(List<int> hours, double hourHeight, ThemeData theme) {
    return Container(
      width: 70,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          right: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            height: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: theme.dividerColor),
              ),
            ),
            child: Text(
              'Time',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // Hour labels
          ...hours.map((hour) {
            return Container(
              height: hourHeight,
              alignment: Alignment.topCenter,
              padding: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: theme.dividerColor.withAlpha(72),
                  ),
                ),
              ),
              child: Text(
                '${hour.toString().padLeft(2, '0')}:00',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}