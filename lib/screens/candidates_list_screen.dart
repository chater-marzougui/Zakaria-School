import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../l10n/app_localizations.dart';
import '../models/structs.dart' as structs;
import '../services/db_service.dart';
import '../helpers/validators.dart';
import 'candidate_detail_screen.dart';

class CandidatesListScreen extends StatefulWidget {
  const CandidatesListScreen({super.key});

  @override
  State<CandidatesListScreen> createState() => _CandidatesListScreenState();
}

class _CandidatesListScreenState extends State<CandidatesListScreen> {
  String _searchQuery = '';
  String _statusFilter = 'all';
  String _sortBy = 'name'; // name, startDate, progress, remainingHours
  bool _sortAscending = true;

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

          // Filter and Sort Controls
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Status Filter
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _statusFilter,
                    decoration: InputDecoration(
                      labelText: t.filterByStatus,
                      prefixIcon: const Icon(Icons.filter_list),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    items: [
                      DropdownMenuItem(value: 'all', child: Text(t.allStatuses, overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'active', child: Text(t.active, overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'inactive', child: Text(t.inactive, overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'graduated', child: Text(t.graduated, overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _statusFilter = value;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // Sort By
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _sortBy,
                    decoration: InputDecoration(
                      labelText: t.sortBy,
                      prefixIcon: const Icon(Icons.sort),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      DropdownMenuItem(value: 'name', child: Text(t.sortByName)),
                      DropdownMenuItem(value: 'startDate', child: Text(t.sortByStartDate)),
                      DropdownMenuItem(value: 'progress', child: Text(t.sortByProgress)),
                      DropdownMenuItem(value: 'remainingHours', child: Text(t.sortByRemainingHours)),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _sortBy = value;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // Sort Order Toggle
                IconButton(
                  icon: Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward),
                  tooltip: _sortAscending ? t.ascending : t.descending,
                  onPressed: () {
                    setState(() {
                      _sortAscending = !_sortAscending;
                    });
                  },
                ),
              ],
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
                  return Center(child: Text(t.error(snapshot.error.toString())));
                }

                final allCandidates = snapshot.data?.docs
                    .map((doc) => structs.Candidate.fromFirestore(doc))
                    .toList() ?? [];

                final candidates = allCandidates
                    .where((c) {
                      // Apply search filter
                      if (_searchQuery.isNotEmpty) {
                        bool matchesSearch = c.name.toLowerCase().contains(_searchQuery) ||
                            c.phone.contains(_searchQuery) ||
                            c.cin.toLowerCase().contains(_searchQuery);
                        if (!matchesSearch) return false;
                      }
                      
                      // Apply status filter
                      if (_statusFilter != 'all' && c.status != _statusFilter) {
                        return false;
                      }
                      
                      return true;
                    })
                    .toList();

                // Apply sorting
                candidates.sort((a, b) {
                  int comparison;
                  switch (_sortBy) {
                    case 'name':
                      comparison = a.name.compareTo(b.name);
                      break;
                    case 'startDate':
                      comparison = a.startDate.compareTo(b.startDate);
                      break;
                    case 'progress':
                      comparison = a.progressPercentage.compareTo(b.progressPercentage);
                      break;
                    case 'remainingHours':
                      comparison = a.remainingHours.compareTo(b.remainingHours);
                      break;
                    default:
                      comparison = 0;
                  }
                  return _sortAscending ? comparison : -comparison;
                });

                return Column(
                  children: [
                    // Results count
                    if (allCandidates.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, size: 16, color: theme.textTheme.bodySmall?.color),
                            const SizedBox(width: 8),
                            Text(
                              t.showingResults(candidates.length, allCandidates.length),
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    
                    // Candidates list or empty state
                    Expanded(
                      child: candidates.isEmpty
                          ? Center(
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
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: candidates.length,
                              itemBuilder: (context, index) {
                                return _CandidateCard(candidate: candidates[index]);
                              },
                            ),
                    ),
                  ],
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
    final theme = Theme.of(context);
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final cinController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.addCandidate),
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
                    labelText: t.candidateCin,
                    prefixIcon: const Icon(Icons.credit_card),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    hintText: '${t.cinExample} (${t.optional})',
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 8,
                  validator: (value) => Validators.validateCIN(
                    value,
                    errorMessage: t.cinInvalid,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  final candidate = structs.Candidate(
                    id: '',
                    name: nameController.text.trim(),
                    phone: phoneController.text.trim(),
                    cin: cinController.text.trim(),
                    startDate: DateTime.now(),
                  );

                  await DatabaseService.createCandidate(candidate);

                  if (!context.mounted) return;
                  Navigator.pop(context);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(t.candidateCreatedSuccessfully),
                      backgroundColor: theme.colorScheme.primary,
                    ),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${t.failedToCreateCandidate}: $e'),
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
