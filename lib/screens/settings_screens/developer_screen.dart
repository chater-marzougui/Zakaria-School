import 'package:flutter/material.dart';
import '../../services/db_service.dart';
import '../../helpers/seed_db.dart';

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
        _showError('Failed to load statistics: $e');
      }
    }
  }

  Future<void> _deleteAllData() async {
    final confirmed = await _showConfirmDialog(
      'Delete All Data',
      'Are you sure you want to delete ALL candidates and sessions? This action cannot be undone!',
      isDangerous: true,
    );

    if (!confirmed) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await DatabaseService.deleteAllCandidates();
      
      if (mounted) {
        _showSuccess('All candidates and sessions deleted successfully');
        await _loadStats();
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to delete data: $e');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _generateFakeData() async {
    final confirmed = await _showConfirmDialog(
      'Generate Test Data',
      'This will create fake candidates and sessions for testing. Continue?',
    );

    if (!confirmed) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await TestDataGenerator.ensureTestData();
      
      if (mounted) {
        _showSuccess('Test data generated successfully');
        await _loadStats();
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to generate test data: $e');
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
        _showSuccess('Created $candidateCount candidates and $sessionCount sessions');
        await _loadStats();
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to generate custom data: $e');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<bool> _showConfirmDialog(String title, String message, {bool isDangerous = false}) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: isDangerous ? Colors.red : null,
            ),
            child: Text(isDangerous ? 'Delete' : 'Confirm'),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('🛠️ Developer Tools'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadStats,
            tooltip: 'Refresh Statistics',
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
                              '⚠️ Warning: These tools are for testing only. Use with caution!',
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
                    '📊 Database Statistics',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  if (_stats != null) ...[
                    _StatCard(
                      title: 'Candidates',
                      stats: {
                        'Total': _stats!['totalCandidates'],
                        'Active': _stats!['activeCandidates'],
                        'Graduated': _stats!['graduatedCandidates'],
                        'Inactive': _stats!['inactiveCandidates'],
                      },
                      icon: Icons.people,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 12),
                    _StatCard(
                      title: 'Sessions',
                      stats: {
                        'Total': _stats!['totalSessions'],
                        'Scheduled': _stats!['scheduledSessions'],
                        'Done': _stats!['doneSessions'],
                        'Missed': _stats!['missedSessions'],
                        'Rescheduled': _stats!['rescheduledSessions'],
                      },
                      icon: Icons.event,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 12),
                    _StatCard(
                      title: 'Payments',
                      stats: {
                        'Paid': _stats!['paidSessions'],
                        'Unpaid': _stats!['unpaidSessions'],
                      },
                      icon: Icons.payment,
                      color: Colors.purple,
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Actions Section
                  Text(
                    '⚡ Quick Actions',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Generate Test Data Button
                  _ActionButton(
                    icon: Icons.data_usage,
                    label: 'Generate Test Data',
                    description: 'Create 21 candidates and 180 sessions',
                    color: Colors.blue,
                    onPressed: _generateFakeData,
                  ),

                  const SizedBox(height: 12),

                  // Custom Data Button
                  _ActionButton(
                    icon: Icons.tune,
                    label: 'Custom Test Data',
                    description: 'Specify number of candidates and sessions',
                    color: Colors.teal,
                    onPressed: _addCustomFakeData,
                  ),

                  const SizedBox(height: 12),

                  // Delete All Button
                  _ActionButton(
                    icon: Icons.delete_forever,
                    label: 'Delete All Data',
                    description: 'Remove all candidates and sessions',
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
                                'Information',
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
    return AlertDialog(
      title: const Text('Custom Test Data'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _candidatesController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Number of Candidates',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _sessionsController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Number of Sessions',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final candidates = int.tryParse(_candidatesController.text) ?? 0;
            final sessions = int.tryParse(_sessionsController.text) ?? 0;
            
            // Validate reasonable limits
            if (candidates > maxCandidates) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Maximum $maxCandidates candidates allowed'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
            
            if (sessions > maxSessions) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Maximum $maxSessions sessions allowed'),
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
          child: const Text('Generate'),
        ),
      ],
    );
  }
}
