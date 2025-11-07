import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';
import '../models/structs.dart' as structs;
import '../services/db_service.dart';
import '../helpers/validators.dart';
import '../widgets/widgets.dart';
import 'candidate_details/availability_tab.dart';
import 'candidate_details/info_tab.dart';
import 'candidate_details/planning_tab.dart';

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
    _tabController = TabController(length: 3, vsync: this);
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
            key: const Key('callCandidateButton'),
            icon: const Icon(Icons.phone),
            onPressed: () => _makeCall(widget.candidate.phone),
          ),
          IconButton(
            key: const Key('smsCandidateButton'),
            icon: const Icon(Icons.message),
            onPressed: () => _sendSMS(widget.candidate.phone),
          ),
          PopupMenuButton<String>(
            key: const Key('candidateOptionsMenuButton'),
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
          unselectedLabelColor: Colors.white70,
          labelColor: theme.colorScheme.secondary,
          indicatorColor: theme.colorScheme.secondary,
          tabs: [
            Tab(text: t.info),
            Tab(text: t.availability),
            Tab(text: t.schedule)
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          CandidateInfoTab(candidate: widget.candidate),
          AvailabilityCalendarTab(candidate: widget.candidate),
          PlanningTab(candidate: widget.candidate,),
        ],
      ),
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
    final phoneClean = phone.trim().split(' ').join('');
    if (phoneClean.isEmpty) return;
    if (!phoneClean.startsWith('+')) {
      // Assuming default country code +1 if not provided
      phone = '+216$phoneClean';
    } else {
      phone = phoneClean;
    }
    final uri = Uri.parse('https://wa.me/$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showEditDialog() async {
    final t = AppLocalizations.of(context)!;
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
                    key: const Key('statusDropdown'),
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
              key: const Key('cancelEditCandidateButton'),
              onPressed: () => Navigator.of(context).pop(),
              child: Text(t.cancel),
            ),
            ElevatedButton(
              key: const Key('saveCandidateButton'),
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
                    showCustomSnackBar(
                      context,
                      t.candidateUpdatedSuccessfully,
                      type: SnackBarType.success,
                    );
                  } catch (e) {
                    if (!mounted) return;
                    showCustomSnackBar(
                      context,
                      '${t.failedToUpdateCandidate}: $e',
                      type: SnackBarType.error,
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
            key: const Key('cancelDeleteCandidateButton'),
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(t.cancel),
          ),
          ElevatedButton(
            key: const Key('confirmDeleteCandidateButton'),
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
        
        showCustomSnackBar(
          context,
          t.candidateDeletedSuccessfully,
          type: SnackBarType.success,
        );
      } catch (e) {
        if (!mounted) return;
        showCustomSnackBar(
          context,
          '${t.failedToDeleteCandidate}: $e',
          type: SnackBarType.error,
        );
      }
    }
  }
}