import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';
import '../models/structs.dart' as structs;
import '../services/db_service.dart';

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
    _tabController = TabController(length: 4, vsync: this);
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
          _buildInfoTab(),
          _buildAvailabilityTab(),
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
            icon: Icons.credit_card,
            title: t.cin,
            value: widget.candidate.cin.isEmpty ? '-' : widget.candidate.cin,
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

  Widget _buildAvailabilityTab() {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;
    
    final daysOfWeek = [
      {'key': 'monday', 'label': t.monday},
      {'key': 'tuesday', 'label': t.tuesday},
      {'key': 'wednesday', 'label': t.wednesday},
      {'key': 'thursday', 'label': t.thursday},
      {'key': 'friday', 'label': t.friday},
      {'key': 'saturday', 'label': t.saturday},
      {'key': 'sunday', 'label': t.sunday},
    ];

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('candidates')
          .doc(widget.candidate.id)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final candidate = structs.Candidate.fromFirestore(snapshot.data!);
        final availability = candidate.availability;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.weeklyAvailability,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                t.availabilitySchedule,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withAlpha(180),
                ),
              ),
              const SizedBox(height: 24),
              ...daysOfWeek.map((day) {
                final dayKey = day['key'] as String;
                final dayLabel = day['label'] as String;
                final daySlots = availability[dayKey] ?? [];

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              dayLabel,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle),
                              color: theme.colorScheme.primary,
                              onPressed: () => _addTimeSlot(context, dayKey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (daySlots.isEmpty)
                          Text(
                            t.noAvailabilitySet,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.textTheme.bodySmall?.color?.withAlpha(150),
                            ),
                          )
                        else
                          ...daySlots.map((slot) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primaryContainer.withAlpha(100),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.access_time,
                                          size: 16,
                                          color: theme.colorScheme.primary,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${slot.startTime} - ${slot.endTime}',
                                          style: theme.textTheme.bodyMedium,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  color: theme.colorScheme.error,
                                  onPressed: () => _deleteTimeSlot(context, dayKey, slot),
                                ),
                              ],
                            ),
                          )),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
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
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return t.pleaseEnterLabel.replaceAll('{label}', t.phoneNumber);
                      }
                      // Basic phone validation (at least 8 digits)
                      if (value.replaceAll(RegExp(r'\D'), '').length < 8) {
                        return t.phoneNumberInvalid;
                      }
                      return null;
                    },
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
                      hintText: '12345678',
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 8,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        if (value.length != 8 || !RegExp(r'^\d+$').hasMatch(value)) {
                          return t.cinInvalid;
                        }
                      }
                      return null;
                    },
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
                    value: selectedStatus,
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

    // Clean up controllers
    nameController.dispose();
    phoneController.dispose();
    cinController.dispose();
    instructorController.dispose();
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

  void _addTimeSlot(BuildContext context, String dayKey) async {
    final t = AppLocalizations.of(context)!;
    TimeOfDay? startTime;
    TimeOfDay? endTime;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(t.addAvailability),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.access_time),
                title: Text(t.from),
                subtitle: Text(
                  startTime != null
                      ? '${startTime!.hour.toString().padLeft(2, '0')}:${startTime!.minute.toString().padLeft(2, '0')}'
                      : t.selectDate,
                ),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (time != null) {
                    setState(() => startTime = time);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.access_time),
                title: Text(t.to),
                subtitle: Text(
                  endTime != null
                      ? '${endTime!.hour.toString().padLeft(2, '0')}:${endTime!.minute.toString().padLeft(2, '0')}'
                      : t.selectDate,
                ),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (time != null) {
                    setState(() => endTime = time);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t.cancel),
            ),
            ElevatedButton(
              onPressed: startTime != null && endTime != null
                  ? () async {
                      final startTimeStr =
                          '${startTime!.hour.toString().padLeft(2, '0')}:${startTime!.minute.toString().padLeft(2, '0')}';
                      final endTimeStr =
                          '${endTime!.hour.toString().padLeft(2, '0')}:${endTime!.minute.toString().padLeft(2, '0')}';

                      // Get current availability
                      final doc = await FirebaseFirestore.instance
                          .collection('candidates')
                          .doc(widget.candidate.id)
                          .get();
                      
                      final candidate = structs.Candidate.fromFirestore(doc);
                      final currentAvailability = Map<String, List<structs.TimeSlot>>.from(candidate.availability);
                      
                      // Add new time slot
                      if (!currentAvailability.containsKey(dayKey)) {
                        currentAvailability[dayKey] = [];
                      }
                      currentAvailability[dayKey]!.add(
                        structs.TimeSlot(
                          startTime: startTimeStr,
                          endTime: endTimeStr,
                        ),
                      );

                      // Convert to Map for Firestore
                      Map<String, dynamic> availabilityMap = {};
                      currentAvailability.forEach((day, slots) {
                        availabilityMap[day] = slots.map((slot) => slot.toMap()).toList();
                      });

                      // Update Firestore
                      await FirebaseFirestore.instance
                          .collection('candidates')
                          .doc(widget.candidate.id)
                          .update({'availability': availabilityMap});

                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    }
                  : null,
              child: Text(t.save),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteTimeSlot(BuildContext context, String dayKey, structs.TimeSlot slot) async {
    final t = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.deleteTimeSlot),
        content: Text('${t.deleteTimeSlot}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(t.confirmDelete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Get current availability
      final doc = await FirebaseFirestore.instance
          .collection('candidates')
          .doc(widget.candidate.id)
          .get();
      
      final candidate = structs.Candidate.fromFirestore(doc);
      final currentAvailability = Map<String, List<structs.TimeSlot>>.from(candidate.availability);
      
      // Remove the time slot
      if (currentAvailability.containsKey(dayKey)) {
        currentAvailability[dayKey]!.removeWhere(
          (s) => s.startTime == slot.startTime && s.endTime == slot.endTime,
        );
        
        // Remove day if no slots left
        if (currentAvailability[dayKey]!.isEmpty) {
          currentAvailability.remove(dayKey);
        }
      }

      // Convert to Map for Firestore
      Map<String, dynamic> availabilityMap = {};
      currentAvailability.forEach((day, slots) {
        availabilityMap[day] = slots.map((slot) => slot.toMap()).toList();
      });

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('candidates')
          .doc(widget.candidate.id)
          .update({'availability': availabilityMap});
    }
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
