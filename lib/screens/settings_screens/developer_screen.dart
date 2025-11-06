import 'package:flutter/material.dart';
import '../../services/db_service.dart';
import '../../helpers/seed_db.dart';
import '../../l10n/app_localizations.dart';

/// Developer Screen for testing database operations
/// Allows developers to:
/// - View database statistics
/// - Delete all candidates and sessions
/// - Generate fake test data
class DeveloperScreen extends StatefulWidget {
  const DeveloperScreen({super.key});

  @override
  State<DeveloperScreen> createState() => _DeveloperScreenState();
}

class _DeveloperScreenState extends State<DeveloperScreen> {
  
  Map<String, dynamic>? _stats;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final stats = await DatabaseService.getStatistics();
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        final t = AppLocalizations.of(context)!;
        _showError(t.failedToLoadStatistics(e.toString()));
      }
    }
  }

  Future<void> _deleteAllData() async {
    final t = AppLocalizations.of(context)!;
    final confirmed = await _showConfirmDialog(
      t.deleteAllData,
      t.deleteAllDataConfirmation,
      isDangerous: true,
    );

    if (!confirmed) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await DatabaseService.deleteAllCandidates();
      
      if (mounted) {
        _showSuccess(t.allDataDeletedSuccessfully);
        await _loadStats();
      }
    } catch (e) {
      if (mounted) {
        _showError(t.failedToDeleteData(e.toString()));
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _generateFakeData() async {
    final t = AppLocalizations.of(context)!;
    final confirmed = await _showConfirmDialog(
      t.generateTestData,
      t.generateTestDataConfirmation,
    );

    if (!confirmed) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await TestDataGenerator.ensureTestData();
      
      if (mounted) {
        _showSuccess(t.testDataGeneratedSuccessfully);
        await _loadStats();
      }
    } catch (e) {
      if (mounted) {
        _showError(t.failedToGenerateTestData(e.toString()));
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addCustomFakeData() async {
    final result = await showDialog<Map<String, int>>(
      context: context,
      builder: (context) => _CustomDataDialog(),
    );

    if (result == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final candidateCount = result['candidates'] ?? 0;
      final sessionCount = result['sessions'] ?? 0;

      if (candidateCount > 0) {
        final candidateIds = await TestDataGenerator.createCandidates(candidateCount);
        if (sessionCount > 0) {
          await TestDataGenerator.createSessions(sessionCount, candidateIds);
        }
      }
      
      if (mounted) {
        final t = AppLocalizations.of(context)!;
        _showSuccess(t.createdCandidatesAndSessions(candidateCount, sessionCount));
        await _loadStats();
      }
    } catch (e) {
      if (mounted) {
        final t = AppLocalizations.of(context)!;
        _showError(t.failedToGenerateCustomData(e.toString()));
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<bool> _showConfirmDialog(String title, String message, {bool isDangerous = false}) async {
    final t = AppLocalizations.of(context)!;
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: isDangerous ? Colors.red : null,
            ),
            child: Text(isDangerous ? t.delete : t.confirm),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.developerTools),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadStats,
            tooltip: t.refreshStatistics,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Warning Banner
                  Card(
                    color: Colors.orange.withAlpha(50),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange[700]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              t.developerToolsWarning,
                              style: TextStyle(
                                color: Colors.orange[900],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Statistics Section
                  Text(
                    t.databaseStatistics,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  if (_stats != null) ...[
                    _StatCard(
                      title: t.candidates,
                      stats: {
                        t.total: _stats!['totalCandidates'],
                        t.active: _stats!['activeCandidates'],
                        t.graduated: _stats!['graduatedCandidates'],
                        t.inactive: _stats!['inactiveCandidates'],
                      },
                      icon: Icons.people,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 12),
                    _StatCard(
                      title: t.sessions,
                      stats: {
                        t.total: _stats!['totalSessions'],
                        t.scheduled: _stats!['scheduledSessions'],
                        t.done: _stats!['doneSessions'],
                        t.missed: _stats!['missedSessions'],
                        t.rescheduled: _stats!['rescheduledSessions'],
                      },
                      icon: Icons.event,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 12),
                    _StatCard(
                      title: t.payments,
                      stats: {
                        t.paid: _stats!['paidSessions'],
                        t.unpaid: _stats!['unpaidSessions'],
                      },
                      icon: Icons.payment,
                      color: Colors.purple,
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Actions Section
                  Text(
                    t.quickActions,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Generate Test Data Button
                  _ActionButton(
                    icon: Icons.data_usage,
                    label: t.generateTestData,
                    description: t.createTestDataDescription,
                    color: Colors.blue,
                    onPressed: _generateFakeData,
                  ),

                  const SizedBox(height: 12),

                  // Custom Data Button
                  _ActionButton(
                    icon: Icons.tune,
                    label: t.customTestData,
                    description: t.specifyNumberOfCandidatesAndSessions,
                    color: Colors.teal,
                    onPressed: _addCustomFakeData,
                  ),

                  const SizedBox(height: 12),

                  // Delete All Button
                  _ActionButton(
                    icon: Icons.delete_forever,
                    label: t.deleteAllData,
                    description: t.removeAllCandidatesAndSessions,
                    color: Colors.red,
                    onPressed: _deleteAllData,
                    isDangerous: true,
                  ),

                  const SizedBox(height: 32),

                  // Info Section
                  Card(
                    color: theme.colorScheme.primaryContainer.withAlpha(50),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: theme.colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                t.information,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '• Test data includes realistic names, phone numbers, and session times\n'
                            '• Sessions are distributed across past, present, and future dates\n'
                            '• Candidates have varying progress levels and statuses\n'
                            '• User data is not affected by these operations',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final Map<String, dynamic> stats;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.stats,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...stats.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key,
                      style: theme.textTheme.bodyLarge,
                    ),
                    Text(
                      '${entry.value}',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final VoidCallback onPressed;
  final bool isDangerous;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.onPressed,
    this.isDangerous = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withAlpha(50),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDangerous ? Colors.red : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withAlpha(150),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.textTheme.bodyMedium?.color?.withAlpha(100),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomDataDialog extends StatefulWidget {
  @override
  State<_CustomDataDialog> createState() => _CustomDataDialogState();
}

class _CustomDataDialogState extends State<_CustomDataDialog> {
  final _candidatesController = TextEditingController(text: '10');
  final _sessionsController = TextEditingController(text: '50');
  // Maximum limits for data generation
  static const int maxCandidates = 1000;
  static const int maxSessions = 5000;

  @override
  void dispose() {
    _candidatesController.dispose();
    _sessionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(t.customTestData),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _candidatesController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: t.numberOfCandidates,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _sessionsController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: t.numberOfSessions,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(t.cancel),
        ),
        TextButton(
          onPressed: () {
            final candidates = int.tryParse(_candidatesController.text) ?? 0;
            final sessions = int.tryParse(_sessionsController.text) ?? 0;
            
            // Validate reasonable limits
            if (candidates > maxCandidates) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(t.maximumCandidatesAllowed(maxCandidates)),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
            
            if (sessions > maxSessions) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(t.maximumSessionsAllowed(maxSessions)),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
            
            if (candidates > 0 || sessions > 0) {
              Navigator.pop(context, {
                'candidates': candidates,
                'sessions': sessions,
              });
            }
          },
          child: Text(t.generate),
        ),
      ],
    );
  }
}
