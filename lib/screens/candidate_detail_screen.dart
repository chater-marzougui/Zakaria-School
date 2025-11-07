import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';
import '../models/structs.dart' as structs;
import '../services/db_service.dart';
import '../widgets/widgets.dart';
import 'candidate_details/availability_tab.dart';
import '../dialogs/edit_candidate_dialog.dart';
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

  void _showEditDialog() async {
    final t = AppLocalizations.of(context)!;

    // Use a separate context for the dialog to avoid disposal issues
    final dialogContext = context;

    await showDialog(
      context: dialogContext,
      barrierDismissible: false, // Prevent accidental dismissal during state updates
      builder: (context) => EditCandidateDialog(
        candidate: widget.candidate,
        onSave: (updatedData) async {
          try {
            await DatabaseService.updateCandidate(
              widget.candidate.id,
              updatedData,
            );

            if (!dialogContext.mounted) return;
            showCustomSnackBar(
              dialogContext,
              t.candidateUpdatedSuccessfully,
              type: SnackBarType.success,
            );
          } catch (e) {
            if (!dialogContext.mounted) return;
            showCustomSnackBar(
              dialogContext,
              '${t.failedToUpdateCandidate}: $e',
              type: SnackBarType.error,
            );
          }
        },
      ),
    );
  }

}