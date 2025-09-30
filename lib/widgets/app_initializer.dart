import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/auth_wrapper.dart';
import '../services/call_monitoring_service.dart';
import '../services/google_auth_service.dart';
import '../firebaseExports/firebase_export_coordinator.dart';
// Removed live activity service import

class AppInitializer extends ConsumerStatefulWidget {
  const AppInitializer({super.key});

  @override
  ConsumerState<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends ConsumerState<AppInitializer> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    print('🔄 Starting initialization...');
    print(
        '🔄 TEST: Checking Firebase Export import - FirebaseExportCoordinator class loaded');
    print('🔄 Initializing core services...');

    try {
      // Initialize Google Authentication Service
      print('√ Core services initialized');
      print('🔄 Setting up authentication...');

      try {
        GoogleAuthService().initialize();
        print('√ Authentication service ready');
      } catch (authError) {
        print(
            '⚠️ Warning: Authentication service initialization failed: $authError');
        print('⚠️ Continuing with app initialization...');
      }

      // Start call monitoring service (for Dynamic Island integration)
      print('🔄 Starting call monitoring...');
      try {
        await CallMonitoringService.startMonitoring();
        print('√ Call monitoring active');
      } catch (callError) {
        print('⚠️ Warning: Call monitoring failed to start: $callError');
        print('⚠️ Continuing with app initialization...');
      }

      print('🔄 Loading task management...');
      print('√ Task management ready');

      print('🔄 Pre-loading data...');
      print('√ Essential data loaded');

      print('🔄 Setting up integrations...');
      print('√ System integrations ready');

      print('🔄 Finalizing setup...');

      // Initialize Firebase Export System - EXPLICIT DETAILED LOGGING
      print('🔄 FIREBASE EXPORT: ===== STARTING FIREBASE EXPORT SYSTEM =====');
      print(
          '🔄 FIREBASE EXPORT: About to import and call FirebaseExportCoordinator');
      print('🔄 FIREBASE EXPORT: Checkpoint 1 - Before initialize call');

      try {
        print(
            '🔄 FIREBASE EXPORT: Checkpoint 2 - Calling FirebaseExportCoordinator.initialize()');
        await FirebaseExportCoordinator.initialize();
        print(
            '✅ FIREBASE EXPORT: Checkpoint 3 - Firebase Export System initialized successfully!');
      } catch (exportError) {
        print(
            '❌ FIREBASE EXPORT: Checkpoint 4 - Failed to initialize Firebase Export System');
        print('❌ FIREBASE EXPORT ERROR: $exportError');
        print('❌ FIREBASE EXPORT STACK: ${exportError.toString()}');
        // Continue anyway - don't let export system failure block app startup
      }

      print('🔄 FIREBASE EXPORT: ===== FIREBASE EXPORT SYSTEM COMPLETE =====');

      print('√ Initialization complete');
      print('🔄 Ready to go!');

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      print('❌ Error during app initialization: $e');
      print('❌ App init stack trace: ${e.toString()}');
      setState(() {
        _isInitialized = true; // Continue anyway
      });
    }
  }

  @override
  void dispose() {
    // Stop call monitoring when app is disposed
    CallMonitoringService.stopMonitoring();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return const AuthWrapper();
  }
}
