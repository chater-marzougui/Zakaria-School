import 'package:ecole_zakaria/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../helpers/image_generator.dart';
import '../../l10n/app_localizations.dart';
import '../../models/structs.dart' as structs;
import 'planning_widgets/planning_summary_cards.dart';
import 'planning_widgets/planning_session_item.dart';
import 'planning_widgets/auto_session_planner.dart';

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

  /// Fetch the latest candidate data from Firestore
  Future<structs.Candidate?> _getLatestCandidateData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('candidates')
          .doc(widget.candidate.id)
          .get();
      
      if (doc.exists) {
        return structs.Candidate.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

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
            PlanningSummaryCards(
              paidSessionsCount: paidSessions.length,
              totalPaidHours: totalPaidHours,
              unpaidSessionsCount: unpaidSessions.length,
              totalUnpaidHours: totalUnpaidHours,
              totalSessionsCount: allSessions.length,
              totalHours: totalPaidHours + totalUnpaidHours,
            ),

            // Auto Planning Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    // Fetch the latest candidate data before planning
                    final latestCandidate = await _getLatestCandidateData();
                    if (latestCandidate == null) {
                      if (mounted) {
                        showCustomSnackBar(
                          context,
                          'Failed to fetch latest candidate data',
                          type: SnackBarType.error,
                        );
                      }
                      return;
                    }
                    if (mounted) {
                      AutoSessionPlanner.showAutoPlanningDialog(context, latestCandidate);
                    }
                  },
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text(
                    'Auto Session Planning',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
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
                  return PlanningSessionItem(session: allSessions[index]);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
