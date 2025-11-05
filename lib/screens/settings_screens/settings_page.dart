import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../controllers/app_preferences.dart';
import '../../l10n/app_localizations.dart';
import '../../main.dart';
import '../../services/export_service.dart';
import '../../widgets/widgets.dart';
import 'developer_screen.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _selectedLanguage = 'en';
  String _selectedThemeMode = 'light';
  bool _notificationsEnabled = true;
  bool _isLoading = true;
  bool _isUpdating = false;

  late AppPreferences appPreferences;

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    appPreferences = AppPreferences(prefs);

    setState(() {
      _selectedLanguage = appPreferences.getPreferredLanguage();
      _selectedThemeMode = appPreferences.getThemeMode();
      _notificationsEnabled = appPreferences.getNotificationsEnabled();
      _isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _updateLanguage(String language) async {
    setState(() {
      _isUpdating = true;
    });

    await appPreferences.setPreferredLanguage(language);

    setState(() {
      _selectedLanguage = language;
      _isUpdating = false;
    });
    // Update the app's locale when we do the languages
    if (mounted) {
      MyApp.of(context)?.updateLocale(Locale(language));
    }
  }

  Future<void> _updateThemeMode(String themeMode) async {
    setState(() {
      _isUpdating = true;
    });

    await appPreferences.setThemeMode(themeMode);

    setState(() {
      _selectedThemeMode = themeMode;
      _isUpdating = false;
    });

    if (mounted) {
      MyApp.of(context)?.updateThemeMode(
          themeMode == 'dark' ? ThemeMode.dark : ThemeMode.light);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.settings),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              ListTile(
                title: const Text("Language"),
                subtitle: Text('Current: ${_selectedLanguage == 'en' ? 'English' : _selectedLanguage== 'fr' ? 'French' : 'العربية'}'),
                  trailing: DropdownButton<String>(
                  value: _selectedLanguage,
                  onChanged: (String? newLocale) {
                    if (newLocale != null) {
                      _updateLanguage(newLocale);
                    }
                  },
                  items: const [
                    DropdownMenuItem(value: 'en', child: Text('English')),
                    DropdownMenuItem(value: 'fr', child: Text('French')),
                    DropdownMenuItem(value: 'ar', child: Text('العربية')),
                  ],
                ),
              ),
              ListTile(
                title: Text(loc.themeMode),
                subtitle: Text(loc.currentSelectedThemeMode(_selectedThemeMode)),
                trailing: DropdownButton<String>(
                  value: _selectedThemeMode,
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      _updateThemeMode(newValue);
                    }
                  },
                  items: <String>['light', 'dark'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value), // Localized theme mode options
                    );
                  }).toList(),
                ),
              ),
              SwitchListTile(
                title: Text(loc.enableNotifications),
                value: _notificationsEnabled,
                onChanged: (bool newValue) {
                  _toggleNotifications(newValue);
                },
              ),
              const Divider(),

              // Export Data Section
              ListTile(
                leading: Icon(Icons.download, color: theme.colorScheme.primary),
                title: Text(loc.exportData),
                subtitle: const Text('Export candidates and sessions to CSV'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _exportData,
              ),
              const Divider(),

              // Developer Tools Section
              ListTile(
                leading: Icon(Icons.developer_mode, color: theme.colorScheme.tertiary),
                title: const Text('🛠️ Developer Tools'),
                subtitle: const Text('Testing and database management'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DeveloperScreen(),
                    ),
                  );
                },
              ),
              const Divider(),

              // About Section
              ListTile(
                leading: Icon(Icons.info_outline, color: theme.colorScheme.primary),
                title: Text(loc.about),
                trailing: const Icon(Icons.chevron_right),
                onTap: _showAboutDialog,
              ),

              // Logout Button
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ElevatedButton(
                  onPressed: _logout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.error,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.logout),
                      const SizedBox(width: 8),
                      Text(
                        loc.logout,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            ],
          ),
          if (_isUpdating)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }

  Future<void> _toggleNotifications(bool isEnabled) async {
    setState(() {
      _isUpdating = true;
    });

    await appPreferences.setNotificationsEnabled(isEnabled);

    setState(() {
      _notificationsEnabled = isEnabled;
      _isUpdating = false;
    });
  }

  Future<void> _exportData() async {
    final loc = AppLocalizations.of(context)!;
    setState(() {
      _isUpdating = true;
    });

    try {
      final path = await ExportService.exportAllDataToCSV();
      if (mounted) {
        showCustomSnackBar(context, '${loc.dataExported}\n$path');
      }
    } catch (e) {
      if (mounted) {
        showCustomSnackBar(context, '${loc.exportFailed}: $e');
      }
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  void _showAboutDialog() {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.about),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'École de Conduite Zakaria',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text('${loc.appVersion}: 1.0.0'),
            const SizedBox(height: 16),
            Text(
              loc.developerInfo,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text('Developed for driving school management'),
            const SizedBox(height: 4),
            const Text('© 2024 All rights reserved'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.close),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    final loc = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.logout),
        content: Text(loc.areYouSureYouWantToLogout),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(loc.logout),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseAuth.instance.signOut();
        // Navigation will be handled by AuthWrapper
      } catch (e) {
        if (mounted) {
          showCustomSnackBar(context, '${loc.errorSigningOut}: $e');
        }
      }
    }
  }
}
