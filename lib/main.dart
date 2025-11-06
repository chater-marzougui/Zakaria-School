import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'controllers/app_preferences.dart';
import 'controllers/auth_wrapper.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'screens/add_session_screen.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
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
      initialRoute: "/",
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
        '/': (context) => const SplashScreen(),
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
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: Color(0xFF1D3557), // Navy blue
        foregroundColor: Color(0xFFF5E6D3), // Cream/gold
        titleTextStyle: TextStyle(color: Color(0xFFF5E6D3), fontSize: 18),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: Color(0xFFF5E6D3), fontSize: 57),
        displayMedium: TextStyle(color: Color(0xFFF5E6D3), fontSize: 45),
        displaySmall: TextStyle(color: Color(0xFFF5E6D3), fontSize: 36),
        headlineLarge: TextStyle(color: Color(0xFFF5E6D3), fontSize: 32),
        headlineMedium: TextStyle(color: Color(0xFFF5E6D3), fontSize: 28),
        headlineSmall: TextStyle(color: Color(0xFFF5E6D3), fontSize: 24),
        titleLarge: TextStyle(color: Color(0xFFF5E6D3), fontSize: 22),
        titleMedium: TextStyle(color: Color(0xFFF5E6D3), fontSize: 16),
        titleSmall: TextStyle(color: Color(0xFFF5E6D3), fontSize: 14),
        bodyLarge: TextStyle(color: Color(0xFFF5E6D3), fontSize: 20),
        bodyMedium: TextStyle(color: Color(0xFFF5E6D3), fontSize: 18),
        bodySmall: TextStyle(color: Color(0xFFF5E6D3), fontSize: 15),
        labelLarge: TextStyle(color: Color(0xFFF5E6D3), fontSize: 14),
        labelMedium: TextStyle(color: Color(0xFFF5E6D3), fontSize: 12),
        labelSmall: TextStyle(color: Color(0xFFF5E6D3), fontSize: 10),
      ),
      scaffoldBackgroundColor: const Color(0xFF0F1A2B), // Dark navy background
      cardColor: const Color(0xFF1D3557), // Navy cards
      dividerColor: const Color(0xFF2A4A6F), // Subtle navy divider
      splashColor: const Color(0xFFD4A574), // Gold splash
      iconTheme: const IconThemeData(color: Color(0xFFF5E6D3)),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(const Color(0xFFD4A574)), // Gold
          foregroundColor: WidgetStateProperty.all(const Color(0xFF1D3557)), // Navy text
          textStyle: WidgetStateProperty.all(
            const TextStyle(color: Color(0xFF1D3557), fontSize: 16),
          ),
        ),
      ),
      buttonTheme: const ButtonThemeData(
        buttonColor: Color(0xFFD4A574),
        textTheme: ButtonTextTheme.primary,
      ),
      colorScheme: ColorScheme.dark(
        primary: const Color(0xFF2A4A6F), // Lighter navy
        secondary: const Color(0xFFD4A574), // Gold
        surface: const Color(0xFF1D3557), // Navy
        tertiary: const Color(0xFFF5E6D3), // Cream
        error: Colors.red[400]!,
      ),
      dialogTheme: const DialogThemeData(backgroundColor: Color(0xFF1D3557)),
    );
  }
}