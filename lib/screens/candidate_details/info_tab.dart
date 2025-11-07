import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';
import '../../models/structs.dart' as structs;


class CandidateInfoTab extends StatefulWidget {
  final structs.Candidate candidate;

  const CandidateInfoTab({
    super.key,
    required this.candidate,
  });

  @override
  State<CandidateInfoTab> createState() => _CandidateInfoTabState();
}

class _CandidateInfoTabState extends State<CandidateInfoTab> {

  void updateNotes(String notes) {
    FirebaseFirestore.instance
        .collection('candidates')
        .doc(widget.candidate.id)
        .update({'notes': notes});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;
    final notesController = TextEditingController(text: widget.candidate.notes);


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
            value: '${widget.candidate.totalPaidHours.toStringAsFixed(1)} ${t
                .hours}',
          ),
          _InfoCard(
            icon: Icons.done,
            title: t.totalTakenHours,
            value: '${widget.candidate.totalTakenHours.toStringAsFixed(1)} ${t
                .hours}',
          ),
          _InfoCard(
            icon: Icons.hourglass_empty,
            title: t.remainingHours,
            value: '${widget.candidate.remainingHours.toStringAsFixed(1)} ${t
                .hours}',
          ),
          _InfoCard(
            icon: Icons.person_outline,
            title: t.assignedInstructor,
            value: widget.candidate.assignedInstructorId.isEmpty
                ? '-'
                : widget.candidate.assignedInstructorId,
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
            controller: notesController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: t.notes,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) {
              updateNotes(value);
            },
          ),
        ],
      ),
    );
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

