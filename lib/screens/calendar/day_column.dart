import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/structs.dart' as structs;
import '../../helpers/time_utils.dart';
import 'session_block.dart';
import 'session_overlap_calculator.dart';

class DayColumn extends StatelessWidget {
  final DateTime date;
  final List<structs.Session> sessions;
  final Map<String, structs.Candidate> candidatesMap;
  final double hourHeight;
  final List<int> hours;
  final VoidCallback onTap;

  const DayColumn({
    super.key,
    required this.date,
    required this.sessions,
    required this.candidatesMap,
    required this.hourHeight,
    required this.hours,
    required this.onTap,
  });

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isToday = _isSameDay(date, DateTime.now());
    
    // Calculate overlapping sessions
    final overlaps = SessionOverlapCalculator.calculateOverlaps(sessions);
    
    // Total height for the day (13 hours * hourHeight)
    final totalHeight = hours.length * hourHeight;
    
    // Base position is 8:00 AM (480 minutes from midnight)
    const baseMinutes = 8 * 60;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          color: isToday 
              ? theme.colorScheme.primary.withAlpha(12)
              : null,
          border: Border(
            right: BorderSide(color: theme.dividerColor),
          ),
        ),
        child: Column(
          children: [
            // Day header
            Container(
              height: 60,
              decoration: BoxDecoration(
                color: isToday 
                    ? theme.colorScheme.primary.withAlpha(24)
                    : null,
                border: Border(
                  bottom: BorderSide(color: theme.dividerColor),
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
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isToday ? theme.colorScheme.primary : null,
                    ),
                  ),
                ],
              ),
            ),
            
            // Day grid with sessions
            SizedBox(
              height: totalHeight,
              child: Stack(
                children: [
                  // Hour dividers
                  ...hours.asMap().entries.map((entry) {
                    final index = entry.key;
                    return Positioned(
                      top: index * hourHeight,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: hourHeight,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: theme.dividerColor.withAlpha(72),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  
                  // Sessions
                  ...sessions.asMap().entries.map((entry) {
                    final index = entry.key;
                    final session = entry.value;
                    final overlap = overlaps[index];
                    
                    final startMinutes = TimeUtils.timeToMinutes(session.startTime);
                    final endMinutes = TimeUtils.timeToMinutes(session.endTime);
                    final duration = endMinutes - startMinutes;
                    
                    // Calculate position relative to 8:00 AM
                    final topPosition = ((startMinutes - baseMinutes) / 60) * hourHeight;
                    final height = (duration / 60) * hourHeight;
                    
                    // Calculate width and left offset for overlaps
                    final columnWidth = 150.0 / overlap.totalColumns;
                    final leftOffset = overlap.columnIndex * columnWidth;
                    
                    return Positioned(
                      top: topPosition.clamp(0.0, totalHeight),
                      left: leftOffset,
                      child: SessionBlock(
                        session: session,
                        candidate: candidatesMap[session.candidateId],
                        width: columnWidth - 2, // Small gap between overlapping sessions
                        height: height.clamp(20.0, totalHeight),
                      ),
                    );
                  }),
                  
                  // Show count badge if more than 4 sessions
                  if (sessions.length > 4)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: GestureDetector(
                        onTap: onTap,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(48),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Text(
                            '${sessions.length}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}