import 'dart:async';
import 'package:flutter/services.dart';
import 'notification_service.dart';
import 'ai_analysis_service.dart';
import 'intelligent_scheduling_service.dart';
import 'tasks_service.dart';

/// Background service that automatically processes notifications without UI
/// Handles AI analysis, task creation, and event scheduling in the background
class BackgroundNotificationProcessor {
  static BackgroundNotificationProcessor? _instance;
  static BackgroundNotificationProcessor get instance =>
      _instance ??= BackgroundNotificationProcessor._();

  BackgroundNotificationProcessor._();

  final AIAnalysisService _aiService = AIAnalysisService();
  final IntelligentSchedulingService _schedulingService =
      IntelligentSchedulingService();
  final TasksService _tasksService = TasksService();

  StreamSubscription<AppNotification>? _notificationSubscription;
  bool _isProcessing = false;
  bool _isInitialized = false;

  // Android method channel for background processing communication
  static const MethodChannel _backgroundChannel =
      MethodChannel('com.example.uacc/background_processor');

  /// Initialize the background processor
  Future<void> initialize() async {
    if (_isInitialized) return;

    print('🚀 Initializing Background Notification Processor...');

    try {
      // Initialize services
      await _tasksService.initialize();

      // Setup Android background processing
      await _setupAndroidBackgroundProcessing();

      // Start listening to notifications
      _startListening();

      _isInitialized = true;
      print('✅ Background Notification Processor initialized successfully');
    } catch (e) {
      print('❌ Failed to initialize Background Notification Processor: $e');
    }
  }

  /// Setup Android background processing service
  Future<void> _setupAndroidBackgroundProcessing() async {
    try {
      // Start the Android background processing service
      await _backgroundChannel.invokeMethod('startBackgroundProcessingService');
      print('🚀 Android background processing service started');

      // Setup method call handler for background processing requests from Android
      _backgroundChannel.setMethodCallHandler(_handleAndroidBackgroundRequest);
      print('📱 Android background processing method handler setup complete');
    } catch (e) {
      print('⚠️ Failed to setup Android background processing: $e');
      // Continue without Android background processing
    }
  }

  /// Handle background processing requests from Android
  Future<dynamic> _handleAndroidBackgroundRequest(MethodCall call) async {
    try {
      switch (call.method) {
        case 'processNotificationBackground':
          return await _processAndroidNotification(call.arguments);
        default:
          print('⚠️ Unknown Android background method: ${call.method}');
          return null;
      }
    } catch (e) {
      print('❌ Error handling Android background request: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Process notification from Android background service
  Future<Map<String, dynamic>> _processAndroidNotification(
      dynamic arguments) async {
    try {
      final data = Map<String, dynamic>.from(arguments as Map);

      // Convert Android notification data to AppNotification
      final notification = AppNotification(
        id: data['id'] ?? '',
        packageName: data['packageName'] ?? '',
        appName: data['appName'] ?? '',
        title: data['title'] ?? '',
        content: data['content'] ?? '',
        bigText: data['bigText'],
        subText: data['subText'],
        timestamp: DateTime.fromMillisecondsSinceEpoch(data['timestamp'] ?? 0),
        priority: data['priority'] ?? 'NORMAL',
      );

      print(
          '🔄 Processing Android background notification: ${notification.appName}');

      // Process the notification in background
      final result = await _processNotificationInBackground(notification);

      return {
        'success': true,
        'tasksCreated': result?.taskCreated ?? false,
        'eventsCreated': result?.eventCreated ?? false,
        'processed': true,
      };
    } catch (e) {
      print('❌ Failed to process Android background notification: $e');
      return {
        'success': false,
        'error': e.toString(),
        'tasksCreated': false,
        'eventsCreated': false,
      };
    }
  }

  /// Start listening to incoming notifications
  void _startListening() {
    _notificationSubscription?.cancel();

    _notificationSubscription = NotificationService.notificationStream.listen(
      (notification) async {
        final result = await _processNotificationInBackground(notification);
        if (result?.hasAnyCreated == true) {
          print(
              '🎉 Background processing created items for ${notification.appName}');
        }
      },
      onError: (error) {
        print('❌ Background processor notification stream error: $error');
      },
    );

    print('👂 Background processor listening for notifications...');
  }

  /// Process notification in background without UI
  Future<BackgroundProcessingResult?> _processNotificationInBackground(
      AppNotification notification) async {
    if (_isProcessing) {
      print(
          '⏳ Background processor busy, queuing notification: ${notification.appName}');
      // TODO: Add to queue for later processing
      return null;
    }

    _isProcessing = true;

    try {
      print(
          '🔄 Background processing notification from ${notification.appName}...');

      // Step 1: Perform AI Analysis
      final analysisResult = await _performBackgroundAIAnalysis(notification);
      if (analysisResult == null) {
        print('⚠️ Skipping background processing - AI analysis failed');
        return BackgroundProcessingResult();
      }

      // Step 2: Check if auto-scheduling is needed (medium/high urgency only)
      BackgroundProcessingResult? processingResult;
      if (_shouldAutoProcess(analysisResult)) {
        processingResult =
            await _performBackgroundScheduling(notification, analysisResult);
      } else {
        print('ℹ️ Low urgency notification - skipping auto-task creation');
        processingResult = BackgroundProcessingResult();
      }

      print('✅ Background processing completed for ${notification.appName}');
      return processingResult;
    } catch (e) {
      print('❌ Background processing failed: $e');
      return BackgroundProcessingResult();
    } finally {
      _isProcessing = false;
    }
  }

  /// Perform AI analysis in background
  Future<BackgroundAnalysisResult?> _performBackgroundAIAnalysis(
      AppNotification notification) async {
    try {
      print('🤖 Running background AI analysis...');

      // Check if notification has any content
      final hasContent = notification.title.isNotEmpty ||
          notification.content.isNotEmpty ||
          (notification.bigText?.isNotEmpty ?? false) ||
          (notification.subText?.isNotEmpty ?? false);

      if (!hasContent) {
        print('⚠️ Empty notification content - using fallback analysis');
        return BackgroundAnalysisResult.fallback(notification.appName);
      }

      // Perform AI analysis
      final analysis = await _aiService.analyzeNotification(
        appName: notification.appName,
        title: notification.title,
        body: notification.content,
        bigText: notification.bigText ?? '',
        subText: notification.subText,
      );

      return BackgroundAnalysisResult(
        summary: analysis.summary,
        urgency: analysis.urgency,
        requiresAction: analysis.requiresAction,
        category: analysis.category,
        containsPersonalInfo: analysis.containsPersonalInfo,
      );
    } catch (e) {
      print('❌ Background AI analysis failed: $e');
      return BackgroundAnalysisResult.fallback(notification.appName);
    }
  }

  /// Check if notification should be auto-processed
  bool _shouldAutoProcess(BackgroundAnalysisResult analysis) {
    // Only process medium and high urgency notifications
    final urgency = analysis.urgency.toLowerCase();
    final shouldProcess =
        urgency == 'medium' || urgency == 'high' || urgency == 'urgent';

    print('📊 Urgency: $urgency - Auto-process: $shouldProcess');
    return shouldProcess;
  }

  /// Perform background scheduling (task/event creation)
  Future<BackgroundProcessingResult> _performBackgroundScheduling(
      AppNotification notification, BackgroundAnalysisResult analysis) async {
    try {
      print('📅 Running background scheduling analysis...');

      final schedulingResult = await _schedulingService.analyzeAndSchedule(
        appName: notification.appName,
        title: notification.title,
        body: notification.content,
        bigText: notification.bigText ?? '',
        subText: notification.subText,
        urgency: analysis.urgency,
        requiresAction: analysis.requiresAction,
      );

      // Log results
      if (schedulingResult.taskCreated && schedulingResult.taskId != null) {
        print('✅ Background task created: ${schedulingResult.taskTitle}');

        // Optionally show a silent notification about task creation
        _showBackgroundTaskCreationFeedback(
            schedulingResult.taskTitle ?? 'Task');
      }

      if (schedulingResult.eventCreated && schedulingResult.eventId != null) {
        print('✅ Background event created: ${schedulingResult.eventTitle}');
      }

      if (!schedulingResult.hasAnyCreated) {
        print(
            'ℹ️ No tasks/events created - content did not meet auto-creation criteria');
      }

      // Return processing result
      return BackgroundProcessingResult(
        taskCreated: schedulingResult.taskCreated,
        eventCreated: schedulingResult.eventCreated,
        taskId: schedulingResult.taskId,
        eventId: schedulingResult.eventId,
        taskTitle: schedulingResult.taskTitle,
        eventTitle: schedulingResult.eventTitle,
      );
    } catch (e) {
      print('❌ Background scheduling failed: $e');
      return BackgroundProcessingResult();
    }
  }

  /// Show subtle feedback for background task creation (optional)
  void _showBackgroundTaskCreationFeedback(String taskTitle) {
    // This could trigger a silent notification or just log
    // No UI popups to maintain background processing
    print('🔔 Silent notification: Task created - $taskTitle');

    // TODO: Could implement a minimal notification banner here if needed
    // But keeping it truly background for now
  }

  /// Get processing statistics
  Map<String, dynamic> getProcessingStats() {
    return {
      'isInitialized': _isInitialized,
      'isProcessing': _isProcessing,
      'isListening': _notificationSubscription != null,
    };
  }

  /// Stop the background processor
  Future<void> stop() async {
    print('🛑 Stopping Background Notification Processor...');

    await _notificationSubscription?.cancel();
    _notificationSubscription = null;
    _isInitialized = false;
    _isProcessing = false;

    print('✅ Background Notification Processor stopped');
  }

  /// Restart the background processor
  Future<void> restart() async {
    await stop();
    await initialize();
  }
}

/// Result of background notification processing
class BackgroundProcessingResult {
  final bool taskCreated;
  final bool eventCreated;
  final String? taskId;
  final String? eventId;
  final String? taskTitle;
  final String? eventTitle;

  BackgroundProcessingResult({
    this.taskCreated = false,
    this.eventCreated = false,
    this.taskId,
    this.eventId,
    this.taskTitle,
    this.eventTitle,
  });

  bool get hasAnyCreated => taskCreated || eventCreated;

  @override
  String toString() {
    return 'BackgroundProcessingResult(taskCreated: $taskCreated, eventCreated: $eventCreated)';
  }
}

/// Simplified analysis result for background processing
class BackgroundAnalysisResult {
  final String summary;
  final String urgency;
  final bool requiresAction;
  final String category;
  final bool containsPersonalInfo;

  BackgroundAnalysisResult({
    required this.summary,
    required this.urgency,
    required this.requiresAction,
    required this.category,
    required this.containsPersonalInfo,
  });

  /// Create fallback result for failed analysis
  factory BackgroundAnalysisResult.fallback(String appName) {
    return BackgroundAnalysisResult(
      summary: 'Notification from $appName (processed in background)',
      urgency: 'low', // Default to low to avoid unnecessary processing
      requiresAction: false,
      category: 'General',
      containsPersonalInfo: false,
    );
  }

  @override
  String toString() {
    return 'BackgroundAnalysis(urgency: $urgency, action: $requiresAction, category: $category)';
  }
}
