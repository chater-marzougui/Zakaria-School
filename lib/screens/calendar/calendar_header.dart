import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CalendarHeader extends StatelessWidget {
  final DateTime weekStart;
  final DateTime weekEnd;
  final Function(int) onNavigateWeek;

  const CalendarHeader({
    super.key,
    required this.weekStart,
    required this.weekEnd,
    required this.onNavigateWeek,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      color: theme.colorScheme.primary.withAlpha(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => onNavigateWeek(-1),
          ),
          Text(
            '${DateFormat('dd MMM').format(weekStart)} - ${DateFormat('dd MMM yyyy').format(weekEnd)}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => onNavigateWeek(1),
          ),
        ],
      ),
    );
  }
}