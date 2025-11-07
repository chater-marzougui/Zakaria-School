import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';
import '../models/structs.dart' as structs;
import '../services/db_service.dart';
import '../helpers/validators.dart';
import 'candidate_details/availability_tab.dart';
import 'candidate_details/info_tab.dart';

class CandidateDetailScreen extends StatefulWidget {
  final structs.Candidate candidate;

  const CandidateDetailScreen({super.key, required this.candidate});

  @override
  State<CandidateDetailScreen> createState() => _CandidateDetailScreenState();
}

class _CandidateDetailScreenState extends State<CandidateDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

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
              } else if (value == 'delete') {
                _showDeleteConfirmation();
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
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: theme.colorScheme.error),
                    const SizedBox(width: 8),
                    Text(t.deleteCandidate, style: TextStyle(color: theme.colorScheme.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.secondary,
          indicatorColor: theme.colorScheme.secondary,
          tabs: [
            Tab(text: t.info),
            Tab(text: t.availability),
            Tab(text: t.schedule),
            Tab(text: t.payments),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          buildInfoTab(context, widget.candidate),
          AvailabilityCalendarTab(candidate: widget.candidate),
          _buildScheduleTab(),
          _buildPaymentsTab(),
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
          final t = AppLocalizations.of(context)!;
          return Center(child: Text(t.error(snapshot.error.toString())));
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
          final t = AppLocalizations.of(context)!;
          return Center(child: Text(t.error(snapshot.error.toString())));
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

  void _showEditDialog() async {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    
    // Controllers for the form
    final nameController = TextEditingController(text: widget.candidate.name);
    final phoneController = TextEditingController(text: widget.candidate.phone);
    final cinController = TextEditingController(text: widget.candidate.cin);
    final instructorController = TextEditingController(text: widget.candidate.assignedInstructor);
    
    bool theoryPassed = widget.candidate.theoryPassed;
    String selectedStatus = widget.candidate.status;
    
    final formKey = GlobalKey<FormState>();

    try {
      await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(t.editCandidate),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: t.candidateName,
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return t.nameRequired;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: phoneController,
                    decoration: InputDecoration(
                      labelText: t.candidatePhone,
                      prefixIcon: const Icon(Icons.phone),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) => Validators.validatePhone(
                      value,
                      errorMessage: value == null || value.trim().isEmpty
                          ? t.pleaseEnterLabel(t.phoneNumber)
                          : t.phoneNumberInvalid,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: cinController,
                    decoration: InputDecoration(
                      labelText: t.cin,
                      prefixIcon: const Icon(Icons.credit_card),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: t.cinExample,
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 8,
                    validator: (value) => Validators.validateCIN(
                      value,
                      errorMessage: t.cinInvalid,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: instructorController,
                    decoration: InputDecoration(
                      labelText: t.assignedInstructor,
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedStatus,
                    decoration: InputDecoration(
                      labelText: t.status,
                      prefixIcon: const Icon(Icons.info_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: [
                      DropdownMenuItem(value: 'active', child: Text(t.active)),
                      DropdownMenuItem(value: 'inactive', child: Text(t.inactive)),
                      DropdownMenuItem(value: 'graduated', child: Text(t.graduated)),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedStatus = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: Text(t.theoryPassed),
                    value: theoryPassed,
                    onChanged: (value) {
                      setState(() {
                        theoryPassed = value;
                      });
                    },
                    secondary: const Icon(Icons.school),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(t.cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  try {
                    // Update candidate in Firestore
                    await DatabaseService.updateCandidate(
                      widget.candidate.id,
                      {
                        'name': nameController.text.trim(),
                        'phone': phoneController.text.trim(),
                        'cin': cinController.text.trim(),
                        'assigned_instructor': instructorController.text.trim(),
                        'status': selectedStatus,
                        'theory_passed': theoryPassed,
                      },
                    );

                    if (!mounted) return;
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(t.candidateUpdatedSuccessfully),
                        backgroundColor: theme.colorScheme.primary,
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${t.failedToUpdateCandidate}: $e'),
                        backgroundColor: theme.colorScheme.error,
                      ),
                    );
                  }
                }
              },
              child: Text(t.save),
            ),
          ],
        ),
      ),
    );
    } finally {
      // Clean up controllers
      nameController.dispose();
      phoneController.dispose();
      cinController.dispose();
      instructorController.dispose();
    }
  }

  void _showDeleteConfirmation() async {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.deleteCandidate),
        content: Text(t.deleteCandidateMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(t.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: Colors.white,
            ),
            child: Text(t.deleteCandidate),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Delete candidate and all their sessions
        await DatabaseService.deleteCandidate(widget.candidate.id);

        if (!mounted) return;
        
        // Pop back to the previous screen (candidates list)
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.candidateDeletedSuccessfully),
            backgroundColor: theme.colorScheme.primary,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${t.failedToDeleteCandidate}: $e'),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    }
  }
}

class _SessionItem extends StatelessWidget {
  final structs.Session session;

  const _SessionItem({required this.session});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
