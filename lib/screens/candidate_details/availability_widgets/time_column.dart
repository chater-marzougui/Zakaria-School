import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

/// Time column widget showing hour labels
class TimeColumn extends StatelessWidget {
  final List<int> hours;
  final double hourHeight;
  final double quarterHeight;

  const TimeColumn({
    super.key,
    required this.hours,
    required this.hourHeight,
    required this.quarterHeight,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;

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
            height: 80,
            alignment: Alignment.bottomCenter,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: theme.dividerColor),
              ),
            ),
            child: Text(
              t.time,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Hour labels
          ...hours.map((hour) {
            return Container(
              height: hourHeight,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: theme.dividerColor.withAlpha(72),
                  ),
                ),
              ),
              child: Container(
                height: hourHeight - 2,
                alignment: Alignment.topCenter,
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${hour.toString().padLeft(2, '0')}:00',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
