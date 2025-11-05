import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/structs.dart' as structs;
import '../l10n/app_localizations.dart';

class SessionTile extends StatelessWidget {
  final structs.Session session;
  final VoidCallback? onTap;

  const SessionTile({
    super.key,
    required this.session,
    this.onTap,
  });

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

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'done':
        return Icons.check_circle;
      case 'missed':
        return Icons.cancel;
      case 'rescheduled':
        return Icons.schedule;
      default:
        return Icons.event;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;
    final statusColor = _getStatusColor(session.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Status Indicator
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(50),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getStatusIcon(session.status),
                  color: statusColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),

              // Session Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Candidate Name
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('candidates')
                          .doc(session.candidateId)
                          .get(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data!.exists) {
                          final candidate = structs.Candidate.fromFirestore(snapshot.data!);
                          return Text(
                            candidate.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }
                        return Text(
                          t.candidate,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                    
                    // Date and Time
                    Text(
                      DateFormat('EEEE, dd MMMM yyyy').format(session.date),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withAlpha(180),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${session.startTime} - ${session.endTime} (${session.durationInHours.toStringAsFixed(1)}h)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    
                    // Status and Payment
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withAlpha(50),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            session.status,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          session.paymentStatus == 'paid'
                              ? Icons.check_circle
                              : Icons.pending,
                          size: 16,
                          color: session.paymentStatus == 'paid'
                              ? Colors.green
                              : theme.colorScheme.error,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          session.paymentStatus,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: session.paymentStatus == 'paid'
                                ? Colors.green
                                : theme.colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow Icon
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
