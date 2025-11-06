import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controllers/auth_wrapper.dart';
import '../firebase_options.dart';
import '../helpers/seed_db.dart';
import '../widgets/widgets.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _loadingMessage = 'Initializing app...';
  bool _initialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Step 1: Initialize Firebase
      setState(() {
        _loadingMessage = 'Initializing app...';
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

      // Step 2: Load user data
      setState(() {
        _loadingMessage = 'Loading user data...';
      });

      // Step 3: Check and load candidates
      setState(() {
        _loadingMessage = 'Loading candidates...';
      });

      // Check if we need to create test data
      final candidatesSnapshot = await FirebaseFirestore.instance
          .collection('candidates')
          .limit(1)
          .get();

      // Step 4: Check and load sessions
      setState(() {
        _loadingMessage = 'Loading sessions...';
      });

      final sessionsSnapshot = await FirebaseFirestore.instance
          .collection('sessions')
          .limit(1)
          .get();

      // Step 5: Ensure test data if needed
      if (candidatesSnapshot.docs.isEmpty || sessionsSnapshot.docs.isEmpty) {
        setState(() {
          _loadingMessage = 'Setting up initial data...';
        });
        await TestDataGenerator.ensureTestData();
      }

      // Mark as initialized
      setState(() {
        _initialized = true;
      });

      // Navigate to AuthWrapper
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
    if (_error != null) {
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
                'Error initializing app',
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
                    _initialized = false;
                  });
                  _initializeApp();
                },
                child: const Text('Retry'),
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
