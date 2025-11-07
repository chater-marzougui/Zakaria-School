import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controllers/auth_wrapper.dart';
import '../firebase_options.dart';
import '../widgets/widgets.dart';
import '../l10n/app_localizations.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _loadingMessage = '...';
  String? _error;
  late AppLocalizations _localizations;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _localizations = AppLocalizations.of(context)!;
    if (_loadingMessage == '...') {
      _initializeApp();
    }
  }

  Future<void> _initializeApp() async {
    try {
      // Step 1: Initialize Firebase
      setState(() {
        _loadingMessage = _localizations.initializingApp;
      });

      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        FirebaseFirestore.instance.settings = const Settings(
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
          persistenceEnabled: true,
        );
      }

      // Step 2: Complete initialization
      setState(() {
        _loadingMessage = _localizations.loadingCandidates;
      });

      // Navigate to AuthWrapper which will load user data
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const AuthWrapper(),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    
    if (_error != null) {
      print('Error during app initialization: $_error');
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                t.errorInitializingApp,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _error!,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _error = null;
                  });
                  _initializeApp();
                },
                child: Text(t.retry),
              ),
            ],
          ),
        ),
      );
    }

    return CustomLoadingScreen(
      message: _loadingMessage,
    );
  }
}
