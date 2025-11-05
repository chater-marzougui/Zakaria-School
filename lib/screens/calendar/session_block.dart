import 'package:flutter/material.dart';
import '../../models/structs.dart' as structs;
import 'session_details_dialog.dart';

class SessionBlock extends StatelessWidget {
  final structs.Session session;
  final structs.Candidate? candidate;
  final double width;
  final double height;

  const SessionBlock({
    super.key,
    required this.session,
    required this.candidate,
    required this.width,
    required this.height,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(session.status);

    return GestureDetector(
      onTap: () => _showSessionDetails(context),
      child: Container(
        width: width,
        height: height,
        margin: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
        decoration: BoxDecoration(
          color: statusColor.withAlpha(220),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: statusColor.withAlpha(72),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(24),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        padding: const EdgeInsets.all(4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (candidate != null)
              Text(
                candidate!.name,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 2),
            Text(
              '${session.startTime} - ${session.endTime}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white.withAlpha(220),
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSessionDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => SessionDetailsDialog(
        session: session,
        candidate: candidate,
      ),
    );
  }
}