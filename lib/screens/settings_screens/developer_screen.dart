import 'package:flutter/material.dart';
import '../../services/db_service.dart';
import '../../services/user_service.dart';
import '../../helpers/seed_db.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/widgets.dart';
import '../../models/structs.dart' as structs;
import '../../controllers/user_controller.dart';

/// Developer Screen for testing database operations and user management
/// Allows developers to:
/// - View database statistics
/// - Delete all candidates and sessions
/// - Generate fake test data
/// - Manage users (instructors, secretaries)
/// 
/// IMPORTANT: This screen should only be accessible to users with role = 'developer'
class DeveloperScreen extends StatefulWidget {
  const DeveloperScreen({super.key});

  @override
  State<DeveloperScreen> createState() => _DeveloperScreenState();
}

class _DeveloperScreenState extends State<DeveloperScreen> with SingleTickerProviderStateMixin {
  
  Map<String, dynamic>? _stats;
  bool _isLoading = false;
  late TabController _tabController;
  List<structs.User> _users = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadStats();
    _loadUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final users = await UserService.getAllUsers();
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        final t = AppLocalizations.of(context)!;
        _showError(t.failedToLoadUsers(e.toString()));
      }
    }
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
    showCustomSnackBar(
      context,
      message,
      type: SnackBarType.success,
    );
  }

  void _showError(String message) {
    showCustomSnackBar(
      context,
      message,
      type: SnackBarType.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;

    // Verify user has developer role
    final currentUser = UserController().currentUser;
    if (currentUser?.role != 'developer') {
      return Scaffold(
        appBar: AppBar(
          title: Text(t.developerTools),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock,
                  size: 64,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  t.accessDenied,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  t.developerAccessOnly,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(t.developerTools),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : () {
              _loadStats();
              _loadUsers();
            },
            tooltip: t.refreshStatistics,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: t.databaseStatistics),
            Tab(text: t.userManagement),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDatabaseTab(),
          _buildUserManagementTab(),
        ],
      ),
    );
  }

  Widget _buildDatabaseTab() {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;

    return _isLoading
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
            );
  }

  Widget _buildUserManagementTab() {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;

    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Add User Button
                ElevatedButton.icon(
                  icon: const Icon(Icons.person_add),
                  label: Text(t.addUser),
                  onPressed: () => _showAddUserDialog(),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                ),

                const SizedBox(height: 24),

                // Users List
                if (_users.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        t.noUsers,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.textTheme.bodyMedium?.color?.withAlpha(128),
                        ),
                      ),
                    ),
                  )
                else
                  ..._users.map((user) => _UserCard(
                        user: user,
                        onEdit: () => _showEditUserDialog(user),
                        onDelete: () => _deleteUser(user),
                      )),
              ],
            ),
          );
  }

  Future<void> _showAddUserDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _UserDialog(),
    );

    if (result == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await UserService.createUser(
        email: result['email'],
        password: result['password'],
        firstName: result['firstName'],
        lastName: result['lastName'],
        phoneNumber: result['phoneNumber'],
        role: result['role'],
      );

      if (mounted) {
        final t = AppLocalizations.of(context)!;
        _showSuccess(t.userCreatedSuccessfully);
        await _loadUsers();
      }
    } catch (e) {
      if (mounted) {
        final t = AppLocalizations.of(context)!;
        _showError(t.failedToCreateUser(e.toString()));
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showEditUserDialog(structs.User user) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _UserDialog(user: user),
    );

    if (result == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await UserService.updateUser(user.uid, result);

      if (mounted) {
        final t = AppLocalizations.of(context)!;
        _showSuccess(t.userUpdatedSuccessfully);
        await _loadUsers();
      }
    } catch (e) {
      if (mounted) {
        final t = AppLocalizations.of(context)!;
        _showError(t.failedToUpdateUser(e.toString()));
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteUser(structs.User user) async {
    final t = AppLocalizations.of(context)!;
    final confirmed = await _showConfirmDialog(
      t.deleteUser,
      t.deleteUserConfirmation,
      isDangerous: true,
    );

    if (!confirmed) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await UserService.deleteUser(user.uid);

      if (mounted) {
        _showSuccess(t.userDeletedSuccessfully);
        await _loadUsers();
      }
    } catch (e) {
      if (mounted) {
        _showError(t.failedToDeleteUser(e.toString()));
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
              showCustomSnackBar(
                context,
                t.maximumCandidatesAllowed(maxCandidates),
                type: SnackBarType.error,
              );
              return;
            }
            
            if (sessions > maxSessions) {
              showCustomSnackBar(
                context,
                t.maximumSessionsAllowed(maxSessions),
                type: SnackBarType.error,
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

class _UserCard extends StatelessWidget {
  final structs.User user;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _UserCard({
    required this.user,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    Color roleColor;
    IconData roleIcon;

    switch (user.role) {
      case 'developer':
        roleColor = Colors.purple;
        roleIcon = Icons.code;
        break;
      case 'secretary':
        roleColor = Colors.orange;
        roleIcon = Icons.admin_panel_settings;
        break;
      default: // instructor
        roleColor = Colors.blue;
        roleIcon = Icons.school;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: roleColor.withAlpha(50),
          child: Icon(roleIcon, color: roleColor),
        ),
        title: Text(user.displayName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email),
            Text(user.phoneNumber),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: roleColor.withAlpha(50),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                user.role == 'instructor' ? t.instructor :
                user.role == 'secretary' ? t.secretary : t.developer,
                style: TextStyle(
                  color: roleColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: onEdit,
              tooltip: t.editUser,
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
              tooltip: t.deleteUser,
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}

class _UserDialog extends StatefulWidget {
  final structs.User? user;

  const _UserDialog({this.user});

  @override
  State<_UserDialog> createState() => _UserDialogState();
}

class _UserDialogState extends State<_UserDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  String _selectedRole = 'instructor';

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.user?.email ?? '');
    _passwordController = TextEditingController();
    _firstNameController = TextEditingController(text: widget.user?.firstName ?? '');
    _lastNameController = TextEditingController(text: widget.user?.lastName ?? '');
    _phoneController = TextEditingController(text: widget.user?.phoneNumber ?? '');
    _selectedRole = widget.user?.role ?? 'instructor';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isEditMode = widget.user != null;

    return AlertDialog(
      title: Text(isEditMode ? t.editUser : t.addUser),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _firstNameController,
                decoration: InputDecoration(
                  labelText: t.firstName,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return t.firstNameRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastNameController,
                decoration: InputDecoration(
                  labelText: t.lastName,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return t.lastNameRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: t.phoneNumber,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return t.phoneNumberRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: "Email",
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                enabled: !isEditMode, // Can't change email in edit mode
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return t.emailRequired;
                  }
                  if (!value.contains('@')) {
                    return t.invalidEmail;
                  }
                  return null;
                },
              ),
              if (!isEditMode) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: t.password,
                    border: const OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return t.passwordRequired;
                    }
                    if (value.length < 6) {
                      return t.passwordMinLength;
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedRole,
                decoration: InputDecoration(
                  labelText: t.selectRole,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(value: 'instructor', child: Text(t.instructor)),
                  DropdownMenuItem(value: 'secretary', child: Text(t.secretary)),
                  DropdownMenuItem(value: 'developer', child: Text(t.developer)),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedRole = value!;
                  });
                },
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
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final result = <String, dynamic>{
                'firstName': _firstNameController.text,
                'lastName': _lastNameController.text,
                'phoneNumber': _phoneController.text,
                'role': _selectedRole,
              };

              if (!isEditMode) {
                result['email'] = _emailController.text;
                result['password'] = _passwordController.text;
              }

              // Update displayName when editing
              if (isEditMode) {
                result['displayName'] = '${_firstNameController.text} ${_lastNameController.text}';
              }

              Navigator.pop(context, result);
            }
          },
          child: Text(isEditMode ? t.save : t.addUser),
        ),
      ],
    );
  }
}
