import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'screens/auth_wrapper.dart';
import 'services/seed_data.dart';

// Conditional import: use firebase_options.dart if it exists, otherwise use stub
// To use this, you need to create firebase_options.dart by running:
// dart pub global run flutterfire_cli:flutterfire configure
import 'firebase_options_stub.dart' 
    if (dart.library.io) 'firebase_options.dart' 
    if (dart.library.html) 'firebase_options.dart'
    as firebase_options;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Global error handler to catch and log Firestore assertion errors without crashing the UI
  FlutterError.onError = (FlutterErrorDetails details) {
    if (details.exception.toString().contains('FIRESTORE')) {
      debugPrint('Caught Firestore Background Error: ${details.exception}');
      return; 
    }
    FlutterError.presentError(details);
  };
  
  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: firebase_options.DefaultFirebaseOptions.currentPlatform,
    );
    
    // Set Firestore settings before first use
    if (kIsWeb) {
      try {
        FirebaseFirestore.instance.settings = const Settings(
          persistenceEnabled: false,
        );
      } catch (e) {
        // Settings might have been already set by a hot restart or previous attempt
        debugPrint('Firestore settings already set or error: $e');
      }
    }
    
    debugPrint('✓ Firebase initialized successfully!');
    
    // Run seeding in background only if init succeeded
    SeedDataService.seedData().catchError((e) {
      debugPrint('Background Seeding Error: $e');
    });
  } catch (e) {
    debugPrint('Firebase Init Error: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Grace Tailor Studio',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5B5FFF), // Vibrant Indigo
          brightness: Brightness.light,
        ).copyWith(
          primary: const Color(0xFF5B5FFF), // Vibrant Indigo
          secondary: const Color(0xFF9333EA), // Rich Purple
          tertiary: const Color(0xFFEC4899), // Hot Pink
          surface: Colors.white,
          surfaceVariant: const Color(0xFFF1F5F9),
          error: const Color(0xFFEF4444),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: const Color(0xFF1E293B),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        cardTheme: CardThemeData(
          elevation: 6,
          shadowColor: const Color(0xFF5B5FFF).withOpacity(0.15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 4,
            shadowColor: const Color(0xFF5B5FFF).withOpacity(0.3),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            backgroundColor: const Color(0xFF5B5FFF),
            foregroundColor: Colors.white,
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          elevation: 6,
          backgroundColor: const Color(0xFF5B5FFF),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF5B5FFF), width: 2.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
          ),
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          elevation: 8,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF5B5FFF),
          unselectedItemColor: Colors.grey.shade500,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          type: BottomNavigationBarType.fixed,
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
          headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            color: Color(0xFF475569),
          ),
        ),
      ),
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}
