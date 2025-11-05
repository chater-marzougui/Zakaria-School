import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';
import '../models/structs.dart' as structs;

class CandidateDetailScreen extends StatefulWidget {
  final structs.Candidate candidate;

  const CandidateDetailScreen({super.key, required this.candidate});

  @override
  State<CandidateDetailScreen> createState() => _CandidateDetailScreenState();
}

class _CandidateDetailScreenState extends State<CandidateDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _notesController.text = widget.candidate.notes;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.candidate.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone),
            onPressed: () => _makeCall(widget.candidate.phone),
          ),
          IconButton(
            icon: const Icon(Icons.message),
            onPressed: () => _sendSMS(widget.candidate.phone),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'whatsapp') {
                _sendWhatsApp(widget.candidate.phone);
              } else if (value == 'edit') {
                _showEditDialog();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'whatsapp',
                child: Row(
                  children: [
                    const Icon(Icons.chat),
                    const SizedBox(width: 8),
                    Text(t.sendWhatsApp),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    const Icon(Icons.edit),
                    const SizedBox(width: 8),
                    Text(t.editInfo),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: t.info),
            Tab(text: t.schedule),
            Tab(text: t.payments),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInfoTab(),
          _buildScheduleTab(),
          _buildPaymentsTab(),
        ],
      ),
    );
  }

  Widget _buildInfoTab() {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoCard(
            icon: Icons.person,
            title: t.candidateName,
            value: widget.candidate.name,
          ),
          _InfoCard(
            icon: Icons.phone,
            title: t.candidatePhone,
            value: widget.candidate.phone,
          ),
          _InfoCard(
            icon: Icons.calendar_today,
            title: t.startDate,
            value: DateFormat('dd/MM/yyyy').format(widget.candidate.startDate),
          ),
          _InfoCard(
            icon: Icons.school,
            title: t.theoryPassed,
            value: widget.candidate.theoryPassed ? t.yes : t.no,
          ),
          _InfoCard(
            icon: Icons.access_time,
            title: t.totalPaidHours,
            value: '${widget.candidate.totalPaidHours.toStringAsFixed(1)} ${t.hours}',
          ),
          _InfoCard(
            icon: Icons.done,
            title: t.totalTakenHours,
            value: '${widget.candidate.totalTakenHours.toStringAsFixed(1)} ${t.hours}',
          ),
          _InfoCard(
            icon: Icons.hourglass_empty,
            title: t.remainingHours,
            value: '${widget.candidate.remainingHours.toStringAsFixed(1)} ${t.hours}',
          ),
          _InfoCard(
            icon: Icons.account_balance_wallet,
            title: t.balance,
            value: '${widget.candidate.balance.toStringAsFixed(2)} TND',
          ),
          _InfoCard(
            icon: Icons.person_outline,
            title: t.assignedInstructor,
            value: widget.candidate.assignedInstructor.isEmpty
                ? '-'
                : widget.candidate.assignedInstructor,
          ),
          _InfoCard(
            icon: Icons.info_outline,
            title: t.status,
            value: widget.candidate.status,
          ),
          const SizedBox(height: 24),
          Text(
            t.notes,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: t.notes,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) {
              _updateNotes(value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleTab() {
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
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final sessions = snapshot.data?.docs
            .map((doc) => structs.Session.fromFirestore(doc))
            .toList() ?? [];

        if (sessions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.event_busy,
                  size: 64,
                  color: theme.textTheme.bodyMedium?.color?.withAlpha(100),
                ),
                const SizedBox(height: 16),
                Text(
                  t.noSessionsYet,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withAlpha(150),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sessions.length,
          itemBuilder: (context, index) {
            final session = sessions[index];
            return _SessionItem(session: session);
          },
        );
      },
    );
  }

  Widget _buildPaymentsTab() {
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
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final sessions = snapshot.data?.docs
            .map((doc) => structs.Session.fromFirestore(doc))
            .toList() ?? [];

        final paidSessions = sessions.where((s) => s.paymentStatus == 'paid').toList();
        final unpaidSessions = sessions.where((s) => s.paymentStatus == 'unpaid').toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Payment Summary
              Card(
                color: theme.colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(t.paid, style: theme.textTheme.titleMedium),
                          Text(
                            '${paidSessions.length} ${t.sessions}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(t.unpaid, style: theme.textTheme.titleMedium),
                          Text(
                            '${unpaidSessions.length} ${t.sessions}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Sessions List
              if (sessions.isEmpty)
                Center(child: Text(t.noSessionsYet))
              else
                ...sessions.map((session) => _PaymentItem(session: session)),
            ],
          ),
        );
      },
    );
  }

  void _updateNotes(String notes) {
    FirebaseFirestore.instance
        .collection('candidates')
        .doc(widget.candidate.id)
        .update({'notes': notes});
  }

  void _makeCall(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _sendSMS(String phone) async {
    final uri = Uri(scheme: 'sms', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _sendWhatsApp(String phone) async {
    final uri = Uri.parse('https://wa.me/$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showEditDialog() {
    // TODO: Implement edit dialog
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(
          title,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.textTheme.bodySmall?.color?.withAlpha(180),
          ),
        ),
        subtitle: Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _SessionItem extends StatelessWidget {
  final structs.Session session;

  const _SessionItem({required this.session});

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
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: statusColor.withAlpha(50),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.event, color: statusColor),
        ),
        title: Text(
          DateFormat('EEEE, dd MMMM yyyy').format(session.date),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
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
      ),
    );
  }
}

class _PaymentItem extends StatelessWidget {
  final structs.Session session;

  const _PaymentItem({required this.session});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          session.paymentStatus == 'paid' ? Icons.check_circle : Icons.pending,
          color: session.paymentStatus == 'paid'
              ? Colors.green
              : theme.colorScheme.error,
          size: 32,
        ),
        title: Text(
          DateFormat('dd/MM/yyyy').format(session.date),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '${session.durationInHours.toStringAsFixed(1)} ${t.hours} • ${session.paymentStatus}',
        ),
        trailing: session.paymentStatus == 'unpaid'
            ? ElevatedButton(
                onPressed: () {
                  FirebaseFirestore.instance
                      .collection('sessions')
                      .doc(session.id)
                      .update({'payment_status': 'paid'});
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: Text(t.markPayment),
              )
            : null,
      ),
    );
  }
}
