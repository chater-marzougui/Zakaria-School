import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

/// Header widget with title and save button
class AvailabilityHeader extends StatelessWidget {
  final bool hasChanges;
  final VoidCallback onSave;

  const AvailabilityHeader({
    super.key,
    required this.hasChanges,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Center(
              child: Text(
                t.weeklyAvailability,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          if (hasChanges)
            ElevatedButton.icon(
              onPressed: onSave,
              icon: const Icon(Icons.save),
              label: Text(t.save),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
            ),
        ],
      ),
    );
  }
}

/// Instructions widget
class AvailabilityInstructions extends StatelessWidget {
  const AvailabilityInstructions({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(12),
      color: theme.colorScheme.primaryContainer.withAlpha(100),
      child: Row(
        children: [
          Icon(Icons.info_outline,
              size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              t.availabilityInstructions,
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
