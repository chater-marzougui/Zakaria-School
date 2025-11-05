import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';
import '../../models/structs.dart' as structs;

class SessionDetailsDialog extends StatelessWidget {
  final structs.Session session;
  final structs.Candidate? candidate;

  const SessionDetailsDialog({
    super.key,
    required this.session,
    required this.candidate,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(t.sessionDetails),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (candidate != null) ...[
              _DetailRow(
                label: t.candidate,
                value: candidate!.name,
                theme: theme,
              ),
              const SizedBox(height: 8),
            ],
            _DetailRow(
              label: t.date,
              value: DateFormat('dd/MM/yyyy').format(session.date),
              theme: theme,
            ),
            _DetailRow(
              label: t.time,
              value: '${session.startTime} - ${session.endTime}',
              theme: theme,
            ),
            _DetailRow(
              label: t.duration,
              value: '${session.durationInHours.toStringAsFixed(2)} hours',
              theme: theme,
            ),
            _DetailRow(
              label: t.status,
              value: session.status,
              theme: theme,
            ),
            _DetailRow(
              label: t.paymentStatus,
              value: session.paymentStatus,
              theme: theme,
            ),
            if (session.note.isNotEmpty) ...[
              const SizedBox(height: 8),
              _DetailRow(
                label: t.notes,
                value: session.note,
                theme: theme,
              ),
            ],
          ],
        ),
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
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}