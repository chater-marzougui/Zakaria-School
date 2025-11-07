import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../bottom_navbar.dart';
import '../widgets/widgets.dart';
import '../models/structs.dart' as structs;
import 'user_controller.dart';
import '../screens/user_management/login.dart';
import '../l10n/app_localizations.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState != ConnectionState.active) {
          return _loadingScreen(context);
        }

        // Check if user is authenticated
        if (!snapshot.hasData || snapshot.data == null) {
          // User is NOT authenticated - go directly to login
          return const LoginScreen();
        }

        // User IS authenticated - now fetch their data
        final user = snapshot.data!;
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState != ConnectionState.done) {
              return _loadingScreen(context);
            }

            if (userSnapshot.hasError) {
              // Handle Firestore errors (like permission denied)
              return _errorScreen(context, userSnapshot.error.toString());
            }

            if (userSnapshot.hasData && userSnapshot.data!.exists) {
              final appUser = structs.User.fromFirestore(userSnapshot.data!);
              UserController().setUser(appUser); // Save user globally
              return const BottomNavbar();
            } else {
              // User is authenticated but doesn't have a Firestore document
              // This shouldn't normally happen, but handle it gracefully
              return _errorScreen(context, 'User profile not found');
            }
          },
        );
      },
    );
  }

  Widget _loadingScreen(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      body: Center(
        child: CustomLoadingScreen(
          message: t.loading,
        ),
      ),
    );
  }

  Widget _errorScreen(BuildContext context, String error) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            const Text('Error loading user data'),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                error,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
              },
              child: const Text('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }
}