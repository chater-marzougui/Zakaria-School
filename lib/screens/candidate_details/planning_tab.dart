import 'package:ecole_zakaria/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../helpers/image_generator.dart';
import '../../l10n/app_localizations.dart';
import '../../models/structs.dart' as structs;

class PlanningTab extends StatefulWidget {
  final structs.Candidate candidate;

  const PlanningTab({
    super.key,
    required this.candidate,
  });

  @override
  State<PlanningTab> createState() => _PlanningTabState();
}

class _PlanningTabState extends State<PlanningTab> {
  bool _isGenerating = false;

  Future<void> _handleSharePlanning(List<structs.Session> sessions) async {
    if (sessions.isEmpty) {
      showCustomSnackBar(
        context,
        'No sessions to share',
        type: SnackBarType.error,
      );
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      await PlanningImageGenerator.generateAndShare(
        context: context,
        candidate: widget.candidate,
        sessions: sessions,
      );
    } catch (e) {
      if (mounted) {
        print('Error generating/sharing planning image: $e');
        showCustomSnackBar(
          context,
          'Error: $e',
          type: SnackBarType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sessions')
          .where('candidate_id', isEqualTo: widget.candidate.id)
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text(t.error(snapshot.error.toString())));
        }

        final allSessions = snapshot.data?.docs
            .map((doc) => structs.Session.fromFirestore(doc))
            .toList() ??
            [];

        final paidSessions =
        allSessions.where((s) => s.paymentStatus == 'paid').toList();
        final unpaidSessions =
        allSessions.where((s) => s.paymentStatus == 'unpaid').toList();

        // Calculate totals
        final totalPaidHours = paidSessions.fold<double>(
            0, (sumT, s) => sumT + s.durationInHours);
        final totalUnpaidHours = unpaidSessions.fold<double>(
            0, (sumT, s) => sumT + s.durationInHours);

        return Column(
          children: [
            // Payment Summary Cards
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _SummaryCard(
                    title: t.paid,
                    sessionsCount: paidSessions.length,
                    hours: totalPaidHours,
                    color: Colors.green,
                    icon: Icons.check_circle,
                    theme: theme,
                    t: t,
                  ),
                  const SizedBox(width: 12),
                  _SummaryCard(
                    title: t.unpaid,
                    sessionsCount: unpaidSessions.length,
                    hours: totalUnpaidHours,
                    color: theme.colorScheme.error,
                    icon: Icons.pending,
                    theme: theme,
                    t: t,
                  ),
                  const SizedBox(width: 12),
                  _SummaryCard(
                    title: t.total,
                    sessionsCount: allSessions.length,
                    hours: totalPaidHours + totalUnpaidHours,
                    color: theme.colorScheme.primary,
                    icon: Icons.receipt_long,
                    theme: theme,
                    t: t,
                  ),
                ],
              ),
            ),

            // Share Planning Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isGenerating
                      ? null
                      : () => _handleSharePlanning(allSessions),
                  icon: _isGenerating
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : const Icon(Icons.share),
                  label: Text(
                    _isGenerating ? 'Generating...' : 'Share Planning',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366), // WhatsApp green
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Sessions List
            Expanded(
              child: allSessions.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_outlined,
                      size: 64,
                      color: theme.textTheme.bodyMedium?.color
                          ?.withAlpha(100),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      t.noSessionsYet,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.textTheme.bodyMedium?.color
                            ?.withAlpha(150),
                      ),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: allSessions.length,
                itemBuilder: (context, index) {
                  return _PaymentItem(session: allSessions[index]);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final int sessionsCount;
  final double hours;
  final Color color;
  final IconData icon;
  final ThemeData theme;
  final AppLocalizations t;

  const _SummaryCard({
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

class _PaymentItem extends StatelessWidget {
  final structs.Session session;

  const _PaymentItem({required this.session});

  void _showPaymentConfirmationDialog(BuildContext context, bool markAsPaid) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              markAsPaid ? Icons.check_circle : Icons.cancel,
              color: markAsPaid ? Colors.green : theme.colorScheme.error,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                markAsPaid ? t.markAsPaid : t.markAsUnpaid,
                style: theme.textTheme.titleLarge,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.confirmPaymentStatusChange),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('dd/MM/yyyy').format(session.date),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        '${session.durationInHours.toStringAsFixed(1)} ${t.hours}',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('sessions')
                    .doc(session.id)
                    .update({
                  'payment_status': markAsPaid ? 'paid' : 'unpaid'
                });

                if (!context.mounted) return;
                Navigator.pop(context);

                showCustomSnackBar(
                  context,
                  markAsPaid
                      ? t.paymentMarkedAsPaid
                      : t.paymentMarkedAsUnpaid,
                  type: SnackBarType.success,
                );
              } catch (e) {
                if (!context.mounted) return;
                showCustomSnackBar(
                  context,
                  '${t.error}: $e',
                  type: SnackBarType.error,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
              markAsPaid ? Colors.green : theme.colorScheme.error,
              foregroundColor: Colors.white,
            ),
            child: Text(t.confirm),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.delete_outline,
              color: theme.colorScheme.error,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                t.deleteSession,
                style: theme.textTheme.titleLarge,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.deleteSessionMessage),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('dd/MM/yyyy').format(session.date),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        '${session.startTime} - ${session.endTime}',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('sessions')
                    .doc(session.id)
                    .delete();

                if (!context.mounted) return;
                Navigator.pop(context);

                showCustomSnackBar(
                  context,
                  t.deleteSession,
                  type: SnackBarType.success,
                );
              } catch (e) {
                if (!context.mounted) return;
                showCustomSnackBar(
                  context,
                  '${t.error}: $e',
                  type: SnackBarType.error,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: Colors.white,
            ),
            child: Text(t.delete),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;
    final isPaid = session.paymentStatus == 'paid';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () {
          _showPaymentConfirmationDialog(context, !isPaid);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Status Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isPaid ? Colors.green : theme.colorScheme.error)
                      .withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPaid ? Icons.check_circle : Icons.pending,
                  color: isPaid ? Colors.green : theme.colorScheme.error,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),

              // Session Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE, dd MMMM yyyy').format(session.date),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.access_time,
                            size: 14,
                            color: theme.textTheme.bodySmall?.color),
                        const SizedBox(width: 4),
                        Text(
                          '${session.startTime} - ${session.endTime}',
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '• ${session.durationInHours.toStringAsFixed(1)} ${t.hours}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Action Button
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: (isPaid ? Colors.green : theme.colorScheme.error)
                          .withAlpha(25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isPaid ? t.paid : t.unpaid,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: isPaid ? Colors.green : theme.colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      _showDeleteConfirmationDialog(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error.withAlpha(25),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}