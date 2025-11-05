import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../l10n/app_localizations.dart';
import '../models/structs.dart' as structs;
import 'candidate_detail_screen.dart';

class CandidatesListScreen extends StatefulWidget {
  const CandidatesListScreen({super.key});

  @override
  State<CandidatesListScreen> createState() => _CandidatesListScreenState();
}

class _CandidatesListScreenState extends State<CandidatesListScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.candidates),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              style: theme.textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: t.searchCandidates,
                hintStyle: TextStyle(
                  color: theme.textTheme.bodyLarge?.color?.withAlpha(128),
                ),
                prefixIcon: Icon(Icons.search, color: theme.colorScheme.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary.withAlpha(75),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary.withAlpha(75),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: theme.colorScheme.surface,
              ),
            ),
          ),

          // Candidates List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('candidates')
                  .orderBy('name')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final candidates = snapshot.data?.docs
                    .map((doc) => structs.Candidate.fromFirestore(doc))
                    .where((c) {
                      if (_searchQuery.isEmpty) return true;
                      return c.name.toLowerCase().contains(_searchQuery) ||
                          c.phone.contains(_searchQuery) ||
                          c.cin.toLowerCase().contains(_searchQuery);
                    })
                    .toList() ?? [];

                if (candidates.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_add_outlined,
                          size: 64,
                          color: theme.textTheme.bodyMedium?.color?.withAlpha(100),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          t.noCandidatesYet,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.textTheme.bodyMedium?.color?.withAlpha(150),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: candidates.length,
                  itemBuilder: (context, index) {
                    return _CandidateCard(candidate: candidates[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showAddCandidateDialog(context);
        },
        icon: const Icon(Icons.add),
        label: Text(t.addCandidate),
      ),
    );
  }

  void _showAddCandidateDialog(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final cinController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.addCandidate),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: t.candidateName,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: t.candidatePhone,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: cinController,
                decoration: InputDecoration(
                  labelText: t.candidateCin,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty || phoneController.text.isEmpty) {
                return;
              }

              final candidate = structs.Candidate(
                id: '',
                name: nameController.text,
                phone: phoneController.text,
                cin: cinController.text,
                startDate: DateTime.now(),
              );

              await FirebaseFirestore.instance
                  .collection('candidates')
                  .add(candidate.toFirestore());

              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: Text(t.save),
          ),
        ],
      ),
    );
  }
}

class _CandidateCard extends StatelessWidget {
  final structs.Candidate candidate;

  const _CandidateCard({required this.candidate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary,
          child: Text(
            candidate.name.isNotEmpty ? candidate.name[0].toUpperCase() : '?',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          candidate.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            // Progress bar
            LinearProgressIndicator(
              value: candidate.progressPercentage / 100,
              backgroundColor: theme.colorScheme.surface,
              valueColor: AlwaysStoppedAnimation<Color>(
                candidate.progressPercentage >= 100
                    ? Colors.green
                    : theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${candidate.progressPercentage.toStringAsFixed(0)}% • ${candidate.remainingHours.toStringAsFixed(1)}h ${t.remainingHours}',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            // Next session
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('sessions')
                  .where('candidate_id', isEqualTo: candidate.id)
                  .where('status', isEqualTo: 'scheduled')
                  .orderBy('date')
                  .limit(1)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  final session = structs.Session.fromFirestore(snapshot.data!.docs.first);
                  return Text(
                    '${t.nextSession}: ${session.date.day}/${session.date.month} ${session.startTime}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  );
                }
                return Text(
                  t.noSessionsYet,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withAlpha(150),
                  ),
                );
              },
            ),
          ],
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: theme.colorScheme.primary,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CandidateDetailScreen(candidate: candidate),
            ),
          );
        },
      ),
    );
  }
}
