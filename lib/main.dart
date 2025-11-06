import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'controllers/app_preferences.dart';
import 'controllers/auth_wrapper.dart';
import 'firebase_options.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'helpers/seed_db.dart';
import 'l10n/app_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/add_session_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    FirebaseFirestore.instance.settings = Settings(cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED);
    FirebaseFirestore.instance.settings = Settings(persistenceEnabled: true);
  }
  final prefs = await SharedPreferences.getInstance();
  await TestDataGenerator.ensureTestData();
  final appPreferences = AppPreferences(prefs);
  await appPreferences.initDefaults();
  runApp(MyApp(appPreferences: appPreferences));
}


class MyApp extends StatefulWidget {
  final AppPreferences appPreferences;

  const MyApp({required this.appPreferences, super.key});

  static MyAppState? of(BuildContext context) {
    return context.findAncestorStateOfType<MyAppState>();
  }

  @override
  State<MyApp> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;
  Locale _locale = const Locale('en');

  void updateThemeMode(ThemeMode themeMode) {
    setState(() {
      _themeMode = themeMode;
    });
  }

  void updateLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final themeMode = widget.appPreferences.getThemeMode();
    final locale = widget.appPreferences.getPreferredLanguage();
    setState(() {
      _themeMode = themeMode == 'dark' ? ThemeMode.dark : ThemeMode.light;
      _locale = Locale(locale);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'École de Conduite Zakaria',
      themeMode: _themeMode,
      locale: _locale,
      theme: _lightTheme(),
      darkTheme: _darkTheme(),
      initialRoute: "auth",
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: child!,
        );
      },
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('fr'),
        Locale('ar'),
      ],
      routes: {
        'auth': (context) => const AuthWrapper(),
        '/add-session': (context) => const AddSessionScreen(),
      },
    );
  }

  ThemeData _lightTheme() {
    return ThemeData(
      primarySwatch: Colors.blue,
      primaryColor: const Color(0xFF1D3557), // Navy blue from logo
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: Color(0xFF1D3557), // Navy blue
        foregroundColor: Color(0xFFF5E6D3), // Cream/gold
        titleTextStyle: TextStyle(color: Color(0xFFF5E6D3), fontSize: 18),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: Color(0xFF1D3557), fontSize: 57),
        displayMedium: TextStyle(color: Color(0xFF1D3557), fontSize: 45),
        displaySmall: TextStyle(color: Color(0xFF1D3557), fontSize: 36),
        headlineLarge: TextStyle(color: Color(0xFF1D3557), fontSize: 32),
        headlineMedium: TextStyle(color: Color(0xFF1D3557), fontSize: 28),
        headlineSmall: TextStyle(color: Color(0xFF1D3557), fontSize: 24),
        titleLarge: TextStyle(color: Color(0xFF1D3557), fontSize: 22),
        titleMedium: TextStyle(color: Color(0xFF1D3557), fontSize: 16),
        titleSmall: TextStyle(color: Color(0xFF1D3557), fontSize: 14),
        bodyLarge: TextStyle(color: Color(0xFF1D3557), fontSize: 20),
        bodyMedium: TextStyle(color: Color(0xFF1D3557), fontSize: 18),
        bodySmall: TextStyle(color: Color(0xFF1D3557), fontSize: 15),
        labelLarge: TextStyle(color: Color(0xFF1D3557), fontSize: 14),
        labelMedium: TextStyle(color: Color(0xFF1D3557), fontSize: 12),
        labelSmall: TextStyle(color: Color(0xFF1D3557), fontSize: 10),
      ),
      scaffoldBackgroundColor: const Color(0xFFFAF8F5), // Off-white background
      cardColor: Colors.white,
      dividerColor: const Color(0xFFD4C5B0), // Light gold divider
      splashColor: const Color(0xFFD4A574), // Gold accent
      iconTheme: const IconThemeData(color: Color(0xFF1D3557)),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(const Color(0xFF1D3557)), // Navy
          foregroundColor: WidgetStateProperty.all(const Color(0xFFF5E6D3)), // Cream
          textStyle: WidgetStateProperty.all(
            const TextStyle(color: Color(0xFFF5E6D3), fontSize: 16),
          ),
        ),
      ),
      buttonTheme: const ButtonThemeData(
        buttonColor: Color(0xFF1D3557),
        textTheme: ButtonTextTheme.primary,
      ),
      colorScheme: ColorScheme.light(
        primary: const Color(0xFF1D3557), // Navy blue
        secondary: const Color(0xFFD4A574), // Gold
        surface: Colors.white,
        tertiary: const Color(0xFFF5E6D3), // Cream
        error: Colors.red[700]!,
      ),
      dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
    );
  }

  ThemeData _darkTheme() {
    return ThemeData(
      primarySwatch: Colors.blue,
      primaryColor: const Color(0xFF2A4A6F), // Lighter navy for dark mode
      brightness: Brightness.dark,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: Color(0xFF1D3557), // Navy blue
        foregroundColor: Color(0xFFF5E6D3), // Cream/gold
        titleTextStyle: TextStyle(color: Color(0xFFF5E6D3), fontSize: 18),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: Color(0xFFFFFFFF), fontSize: 57, fontWeight: FontWeight.w400),
        displayMedium: TextStyle(color: Color(0xFFFFFFFF), fontSize: 45, fontWeight: FontWeight.w400),
        displaySmall: TextStyle(color: Color(0xFFFFFFFF), fontSize: 36, fontWeight: FontWeight.w400),
        headlineLarge: TextStyle(color: Color(0xFFFFFFFF), fontSize: 32, fontWeight: FontWeight.w400),
        headlineMedium: TextStyle(color: Color(0xFFFFFFFF), fontSize: 28, fontWeight: FontWeight.w400),
        headlineSmall: TextStyle(color: Color(0xFFFFFFFF), fontSize: 24, fontWeight: FontWeight.w400),
        titleLarge: TextStyle(color: Color(0xFFFFFFFF), fontSize: 22, fontWeight: FontWeight.w500),
        titleMedium: TextStyle(color: Color(0xFFFFFFFF), fontSize: 16, fontWeight: FontWeight.w500),
        titleSmall: TextStyle(color: Color(0xFFFFFFFF), fontSize: 14, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: Color(0xFFE0E0E0), fontSize: 20, fontWeight: FontWeight.w400),
        bodyMedium: TextStyle(color: Color(0xFFE0E0E0), fontSize: 18, fontWeight: FontWeight.w400),
        bodySmall: TextStyle(color: Color(0xFFE0E0E0), fontSize: 15, fontWeight: FontWeight.w400),
        labelLarge: TextStyle(color: Color(0xFFE0E0E0), fontSize: 14, fontWeight: FontWeight.w500),
        labelMedium: TextStyle(color: Color(0xFFB0B0B0), fontSize: 12, fontWeight: FontWeight.w500),
        labelSmall: TextStyle(color: Color(0xFFB0B0B0), fontSize: 10, fontWeight: FontWeight.w500),
      ),
      scaffoldBackgroundColor: const Color(0xFF0F1A2B), // Dark navy background
      cardColor: const Color(0xFF1D3557), // Navy cards
      dividerColor: const Color(0xFF2A4A6F), // Subtle navy divider
      splashColor: const Color(0xFFD4A574), // Gold splash
      iconTheme: const IconThemeData(color: Color(0xFFE0E0E0)),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(const Color(0xFFD4A574)), // Gold
          foregroundColor: WidgetStateProperty.all(const Color(0xFF0F1A2B)), // Dark background for contrast
          textStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.all(const Color(0xFFD4A574)), // Gold for text buttons
        ),
      ),
      buttonTheme: const ButtonThemeData(
        buttonColor: Color(0xFFD4A574),
        textTheme: ButtonTextTheme.primary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: const TextStyle(color: Color(0xFFE0E0E0)),
        hintStyle: const TextStyle(color: Color(0xFFB0B0B0)),
        border: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF2A4A6F)),
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF2A4A6F)),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFFD4A574)),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      colorScheme: ColorScheme.dark(
        primary: const Color(0xFFD4A574), // Gold as primary for better visibility
        secondary: const Color(0xFFD4A574), // Gold
        surface: const Color(0xFF1D3557), // Navy
        tertiary: const Color(0xFFF5E6D3), // Cream
        error: Colors.red[400]!,
        onPrimary: const Color(0xFF0F1A2B), // Dark text on gold
        onSecondary: const Color(0xFF0F1A2B), // Dark text on gold
        onSurface: const Color(0xFFFFFFFF), // White text on surface
        onError: Colors.white,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF1D3557),
        titleTextStyle: const TextStyle(
          color: Color(0xFFFFFFFF),
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: const TextStyle(
          color: Color(0xFFE0E0E0),
          fontSize: 16,
        ),
      ),
    );
  }
}