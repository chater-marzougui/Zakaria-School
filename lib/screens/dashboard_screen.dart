import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../l10n/app_localizations.dart';
import '../models/structs.dart' as structs;
import '../helpers/image_generator.dart';
import '../widgets/widgets.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isGenerating = false;

  Future<void> _showInstructorSelectionDialog() async {
    final t = AppLocalizations.of(context)!;

    // Fetch all users (instructors)
    final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
    final users = usersSnapshot.docs
        .map((doc) => structs.User.fromFirestore(doc))
        .toList();

    if (!mounted) return;

    if (users.isEmpty) {
      showCustomSnackBar(
        context,
        'No users found',
        type: SnackBarType.error,
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Select Instructor'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(user.displayName[0].toUpperCase()),
                ),
                title: Text(user.displayName),
                subtitle: Text(user.phoneNumber),
                onTap: () {
                  Navigator.pop(dialogContext);
                  _handleSendScheduleToInstructor(user);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(t.cancel),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSendScheduleToInstructor(structs.User instructor) async {
    setState(() {
      _isGenerating = true;
    });

    try {
      // Fetch all sessions for this instructor
      final sessionsSnapshot = await FirebaseFirestore.instance
          .collection('sessions')
          .where('instructor_id', isEqualTo: instructor.uid)
          .orderBy('date')
          .get();

      final sessions = sessionsSnapshot.docs
          .map((doc) => structs.Session.fromFirestore(doc))
          .toList();

      if (sessions.isEmpty) {
        if (mounted) {
          showCustomSnackBar(
            context,
            'No sessions found for this instructor',
            type: SnackBarType.error,
          );
        }
        return;
      }

      if (!mounted) return;

      await InstructorScheduleImageGenerator.generateAndShare(
        context: context,
        instructor: instructor,
        sessions: sessions,
      );
    } catch (e) {
      if (mounted) {
        debugPrint('Error generating/sharing instructor schedule: $e');
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
                const SizedBox(height: 16),

                // Send Schedule to Instructor Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isGenerating
                        ? null
                        : _showInstructorSelectionDialog,
                    icon: _isGenerating
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : const Icon(Icons.send),
                    label: const Text(
                      'Send Schedule to Instructor',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
