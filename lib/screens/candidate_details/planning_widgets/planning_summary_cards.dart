import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

class PlanningSummaryCards extends StatelessWidget {
  final int paidSessionsCount;
  final double totalPaidHours;
  final int unpaidSessionsCount;
  final double totalUnpaidHours;
  final int totalSessionsCount;
  final double totalHours;

  const PlanningSummaryCards({
    super.key,
    required this.paidSessionsCount,
    required this.totalPaidHours,
    required this.unpaidSessionsCount,
    required this.totalUnpaidHours,
    required this.totalSessionsCount,
    required this.totalHours,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          SummaryCard(
            title: t.paid,
            sessionsCount: paidSessionsCount,
            hours: totalPaidHours,
            color: Colors.green,
            icon: Icons.check_circle,
            theme: theme,
            t: t,
          ),
          const SizedBox(width: 12),
          SummaryCard(
            title: t.unpaid,
            sessionsCount: unpaidSessionsCount,
            hours: totalUnpaidHours,
            color: theme.colorScheme.error,
            icon: Icons.pending,
            theme: theme,
            t: t,
          ),
          const SizedBox(width: 12),
          SummaryCard(
            title: t.total,
            sessionsCount: totalSessionsCount,
            hours: totalHours,
            color: theme.colorScheme.primary,
            icon: Icons.receipt_long,
            theme: theme,
            t: t,
          ),
        ],
      ),
    );
  }
}

class SummaryCard extends StatelessWidget {
  final String title;
  final int sessionsCount;
  final double hours;
  final Color color;
  final IconData icon;
  final ThemeData theme;
  final AppLocalizations t;

  const SummaryCard({
    super.key,
    required this.title,
    required this.sessionsCount,
    required this.hours,
    required this.color,
    required this.icon,
    required this.theme,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(75), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '$sessionsCount ${t.sessions}',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            '${hours.toStringAsFixed(1)} ${t.hours}',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
