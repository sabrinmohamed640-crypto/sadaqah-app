import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // Required for kIsWeb
import 'firebase_options.dart';
import 'services/database_service.dart';
import 'services/notification_service.dart';
import 'utils/theme.dart';
import 'utils/localization.dart';
import 'screens/splash_screen.dart';

/// Global flag so the rest of the app knows whether Firebase is available.
/// When false the UI falls back to offline / degraded mode.
bool firebaseInitialized = false;

void main() async {
  // 1. Ensure Flutter binding is ready before any async work
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialise Firebase — handle every platform scenario
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Debug-only: disable local Firestore cache so stale "missing index"
    // errors from before index creation are not replayed from disk.
    if (kDebugMode) {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: false,
      );
      debugPrint('🔧 Debug: Firestore persistence disabled (cache bypassed)');
    }

    firebaseInitialized = true;
    debugPrint('✅ Firebase Initialized Successfully on ${defaultTargetPlatform.name}');

    // Legacy muzakki doc init — debug only (requires admin write in production rules).
    if (kDebugMode) {
      try {
        await DatabaseService().initializeMuzakkiIfEmpty();
      } catch (e) {
        debugPrint('⚠️ muzakki init skipped: $e');
      }
    }
  } on UnsupportedError catch (e) {
    // Thrown by DefaultFirebaseOptions for platforms without config
    debugPrint('⚠️ Firebase Unsupported Platform: $e');
    debugPrint('   ➜ Running in offline / demo mode.');
    firebaseInitialized = false;
  } catch (e, stackTrace) {
    // Catch-all for any other init failure (network, config corruption, etc.)
    debugPrint('❌ Firebase Initialization Error: $e');
    debugPrint('   StackTrace: $stackTrace');
    firebaseInitialized = false;
  }

  // 3. Dev-only seeding (blocked by Firestore rules in production builds).
  if (firebaseInitialized && kDebugMode) {
    try {
      debugPrint('🚀 Starting Database Seeding (debug mode)...');
      final db = DatabaseService();
      await db.seedProjectsIfEmpty();
      await db.seedMustahikIfEmpty();
      await db.seedMuzakkiIfEmpty();
      debugPrint('✅ Database Seeding Complete.');
    } catch (e) {
      debugPrint('❌ Database Seeding Failed: $e');
      debugPrint(
        '   ➜ Seed as an admin user, or import data via Firebase Console.',
      );
    }
  } else if (firebaseInitialized) {
    debugPrint('⏭️ Skipping database seeding (release build).');
  } else {
    debugPrint('⏭️ Skipping database seeding (Firebase not available).');
  }

  // 4. Initialize Notification Service (FCM) if Firebase is available
  if (firebaseInitialized) {
    try {
      final notificationService = NotificationService();
      await notificationService.initialize();
      debugPrint('✅ Notification Service Initialized');
    } catch (e) {
      debugPrint('⚠️ Notification Service Initialization Error: $e');
      debugPrint('   ➜ App will continue without notifications.');
    }
  }

  // 5. Launch the app
  runApp(
    const LocalizationManager(
      child: ZakatSadaqahApp(),
    ),
  );
}

class ZakatSadaqahApp extends StatelessWidget {
  const ZakatSadaqahApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Khairat',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // auto-follows device light/dark setting
      home: const SplashScreen(),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: child ?? const Scaffold(body: Center(child: Text("Loading..."))),
        );
      },
    );
  }
}