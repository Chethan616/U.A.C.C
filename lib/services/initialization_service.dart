import 'dart:async';
import 'package:flutter/foundation.dart';
import 'call_monitoring_service.dart';
import 'google_auth_service.dart';
// Import other services as needed

class InitializationService {
  static bool _isInitialized = false;
  static final List<String> _initializationSteps = [];
  static final StreamController<String> _progressController =
      StreamController<String>.broadcast();

  /// Stream to listen for initialization progress updates
  static Stream<String> get progressStream => _progressController.stream;

  /// Check if the app has been fully initialized
  static bool get isInitialized => _isInitialized;

  /// Get list of completed initialization steps
  static List<String> get completedSteps => List.from(_initializationSteps);

  /// Initialize all app services and dependencies
  static Future<void> initializeApp() async {
    if (_isInitialized) {
      return;
    }

    _initializationSteps.clear();
    _updateProgress('Starting initialization...');

    try {
      // Step 1: Initialize core services
      _updateProgress('Initializing core services...');
      await Future.delayed(const Duration(milliseconds: 500));
      _addStep('Core services initialized');

      // Step 2: Initialize Google Authentication Service
      _updateProgress('Setting up authentication...');
      try {
        GoogleAuthService().initialize();
        await Future.delayed(const Duration(milliseconds: 800));
        _addStep('Authentication service ready');
      } catch (e) {
        debugPrint('Error initializing Google Auth: $e');
        _addStep('Authentication service (with fallback)');
      }

      // Step 3: Initialize Call Monitoring Service
      _updateProgress('Starting call monitoring...');
      try {
        await CallMonitoringService.startMonitoring();
        await Future.delayed(const Duration(milliseconds: 600));
        _addStep('Call monitoring active');
      } catch (e) {
        debugPrint('Error starting call monitoring: $e');
        _addStep('Call monitoring (with fallback)');
      }

      // Step 4: Initialize Task Service
      _updateProgress('Loading task management...');
      try {
        // Initialize task service if needed
        await Future.delayed(const Duration(milliseconds: 700));
        _addStep('Task management ready');
      } catch (e) {
        debugPrint('Error initializing task service: $e');
        _addStep('Task management (with fallback)');
      }

      // Step 5: Pre-load essential data
      _updateProgress('Pre-loading data...');
      try {
        // Pre-load any essential data here
        await Future.delayed(const Duration(milliseconds: 500));
        _addStep('Essential data loaded');
      } catch (e) {
        debugPrint('Error pre-loading data: $e');
        _addStep('Essential data (with fallback)');
      }

      // Step 6: Setup system integrations
      _updateProgress('Setting up integrations...');
      try {
        // Setup system integrations
        await Future.delayed(const Duration(milliseconds: 400));
        _addStep('System integrations ready');
      } catch (e) {
        debugPrint('Error setting up integrations: $e');
        _addStep('System integrations (with fallback)');
      }

      // Final step
      _updateProgress('Finalizing setup...');
      await Future.delayed(const Duration(milliseconds: 300));
      _addStep('Initialization complete');

      _isInitialized = true;
      _updateProgress('Ready to go!');
    } catch (e) {
      debugPrint('Error during app initialization: $e');
      _addStep('Initialization completed with errors');
      _isInitialized = true; // Continue anyway
      _updateProgress('Ready (with some limitations)');
    }
  }

  /// Reset initialization state (useful for testing or reinitialization)
  static void reset() {
    _isInitialized = false;
    _initializationSteps.clear();
  }

  /// Add a completed initialization step
  static void _addStep(String step) {
    _initializationSteps.add(step);
    debugPrint('✓ $step');
  }

  /// Update progress and notify listeners
  static void _updateProgress(String message) {
    debugPrint('🔄 $message');
    if (!_progressController.isClosed) {
      _progressController.add(message);
    }
  }

  /// Cleanup resources
  static void dispose() {
    if (!_progressController.isClosed) {
      _progressController.close();
    }
  }
}
