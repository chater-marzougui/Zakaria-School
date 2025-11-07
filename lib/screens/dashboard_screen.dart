import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../l10n/app_localizations.dart';
import '../models/structs.dart' as structs;

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.dashboard),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('sessions')
            .orderBy('date')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text(t.error(snapshot.error.toString())));
          }

          final sessions = snapshot.data?.docs
              .map((doc) => structs.Session.fromFirestore(doc))
              .toList() ?? [];

          // Filter today's sessions
          final today = DateTime.now();
          final todaySessions = sessions.where((s) {
            return s.date.year == today.year &&
                s.date.month == today.month &&
                s.date.day == today.day &&
                (s.status == 'scheduled' || s.status == 'done');
          }).toList();

          // Get upcoming 5 sessions
          final upcomingSessions = sessions.where((s) {
            return s.date.isAfter(today) || 
                (s.date.year == today.year &&
                 s.date.month == today.month &&
                 s.date.day == today.day);
          }).take(5).toList();

          // Calculate unpaid summary
          final unpaidTotal = sessions
              .where((s) => s.paymentStatus == 'unpaid')
              .fold<double>(0, (sumT, s) => sumT + s.durationInHours);

          return RefreshIndicator(
            onRefresh: () async {
              // Refresh is handled by StreamBuilder
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Summary Cards
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        title: t.todaySessions,
                        value: todaySessions.length.toString(),
                        icon: Icons.today,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryCard(
                        title: t.unpaidSummary,
                        value: '${unpaidTotal.toStringAsFixed(1)}h',
                        icon: Icons.payment,
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Today's Sessions
                Text(
                  t.todaySessions,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                if (todaySessions.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          t.noSessionsYet,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.textTheme.bodyMedium?.color?.withAlpha(150),
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  ...todaySessions.map((session) => _SessionCard(session: session)),

                const SizedBox(height: 24),

                // Upcoming Sessions
                Text(
                  t.upcomingSessions,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                if (upcomingSessions.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          t.noSessionsYet,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.textTheme.bodyMedium?.color?.withAlpha(150),
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  ...upcomingSessions.map((session) => _SessionCard(session: session)),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add-session-dashboard',
        onPressed: () {
          // Navigate to add session screen
          Navigator.pushNamed(context, '/add-session');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withAlpha(180),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final structs.Session session;

  const _SessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;

    Color statusColor;
    switch (session.status) {
      case 'done':
        statusColor = Colors.blue;
        break;
      case 'missed':
        statusColor = Colors.red;
        break;
      case 'rescheduled':
        statusColor = Colors.orange;
        break;
      default:
        statusColor = Colors.green;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 4,
          height: double.infinity,
          decoration: BoxDecoration(
            color: statusColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        title: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('candidates')
              .doc(session.candidateId)
              .get(),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data!.exists) {
              final candidate = structs.Candidate.fromFirestore(snapshot.data!);
              return Text(candidate.name);
            }
            return Text(t.candidate);
          },
        ),
        subtitle: Text(
          '${session.startTime} - ${session.endTime} • ${session.status}',
        ),
        trailing: Icon(
          session.paymentStatus == 'paid' ? Icons.check_circle : Icons.pending,
          color: session.paymentStatus == 'paid'
              ? Colors.green
              : theme.colorScheme.error,
        ),
        onTap: () {
          // Navigate to session details
        },
      ),
    );
  }
}
