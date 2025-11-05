import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'l10n/app_localizations.dart';

// Screens
import 'screens/dashboard_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/candidates_list_screen.dart';
import 'screens/settings_screens/settings_page.dart';

class BottomNavbar extends StatefulWidget {
  const BottomNavbar({super.key});

  static void switchToPage(BuildContext context, int index) {
    final state = context.findAncestorStateOfType<_HomePageState>();
    if (state != null) {
      state._onItemTapped(index);
    }
  }

  @override
  State<BottomNavbar> createState() => _HomePageState();
}

class _HomePageState extends State<BottomNavbar> {
  int _selectedIndex = 0;
  String? role;
  DateTime? lastPressed;

  late List<Widget> _pages;
  late List<Widget> _pageWidgets;
  late List<BottomNavigationBarItem> _navItems;

  @override
  void initState() {
    super.initState();
    role = "instructor"; // Set a default role since we don't have RBAC
  }

  void _setupPages() {

    final loc = AppLocalizations.of(context)!;
      _pages = [
        const DashboardScreen(),
        const CalendarScreen(),
        const CandidatesListScreen(),
        const SettingsPage(),
      ];

      _navItems = [
        BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard), label: loc.dashboard),
        BottomNavigationBarItem(
            icon: const Icon(Icons.calendar_today), label: loc.calendar),
        BottomNavigationBarItem(
            icon: const Icon(Icons.people), label: loc.candidates),
        BottomNavigationBarItem(
            icon: const Icon(Icons.settings), label: loc.settings),
      ];

    _pageWidgets = _pages.asMap().entries.map((entry) {
      return Offstage(
        offstage: _selectedIndex != entry.key,
        child: TickerMode(
          enabled: _selectedIndex == entry.key,
          child: entry.value,
        ),
      );
    }).toList();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      for (int i = 0; i < _pageWidgets.length; i++) {
        _pageWidgets[i] = Offstage(
          offstage: _selectedIndex != i,
          child: TickerMode(
            enabled: _selectedIndex == i,
            child: _pages[i],
          ),
        );
      }
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        final now = DateTime.now();
        if (lastPressed == null ||
            now.difference(lastPressed!) > const Duration(seconds: 2)) {
          lastPressed = now;
          Fluttertoast.showToast(msg: loc.tapAgainToExit);
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: _pageWidgets,
                ),
              ),
              BottomNavigationBar(
                currentIndex: _selectedIndex,
                backgroundColor: theme.cardColor,
                onTap: _onItemTapped,
                selectedItemColor: theme.primaryColor,
                unselectedItemColor: theme.colorScheme.tertiary,
                showSelectedLabels: true,
                showUnselectedLabels: true,
                items: _navItems,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
