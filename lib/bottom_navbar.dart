import 'package:flutter/material.dart';
import 'l10n/app_localizations.dart';

// Screens
import 'screens/dashboard_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/candidates_list_screen.dart';
import 'screens/settings_screens/settings_page.dart';

class BottomNavbar extends StatefulWidget {
  const BottomNavbar({super.key});

  static void switchToPage(BuildContext context, int index) {
    final state = context.findAncestorStateOfType<_BottomNavbarState>();
    if (state != null) {
      state._onItemTapped(index);
    }
  }

  @override
  State<BottomNavbar> createState() => _BottomNavbarState();
}

class _BottomNavbarState extends State<BottomNavbar> {
  int _selectedIndex = 0;
  String? role;
  DateTime? lastPressed;

  @override
  void initState() {
    super.initState();
    role = "instructor"; // Set a default role since we don't have RBAC
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    // Show loading until role is fetched
    if (role == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Define pages and navigation items in build method
    final pages = [
      const DashboardScreen(),
      const CalendarScreen(),
      const CandidatesListScreen(),
      const SettingsPage(),
    ];

    final navItems = [
      BottomNavigationBarItem(
        icon: const Icon(Icons.dashboard),
        label: loc.dashboard,
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.calendar_today),
        label: loc.calendar,
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.people),
        label: loc.candidates,
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.settings),
        label: loc.settings,
      ),
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: pages,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        backgroundColor: theme.cardColor,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
        selectedItemColor: theme.primaryColor,
        unselectedItemColor: theme.colorScheme.tertiary,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        items: navItems,
      ),
    );
  }
}