import 'dart:collection';
import 'notification_service.dart';

/// Queue processor to handle background notification processing efficiently
/// Prevents system overload and ensures sequential processing
class NotificationQueueProcessor {
  static NotificationQueueProcessor? _instance;
  static NotificationQueueProcessor get instance =>
      _instance ??= NotificationQueueProcessor._();

  NotificationQueueProcessor._();

  final Queue<NotificationQueueItem> _processingQueue =
      Queue<NotificationQueueItem>();
  bool _isProcessingQueue = false;

  /// Add notification to processing queue
  void enqueue(
      AppNotification notification, Future<void> Function() processor) {
    final queueItem = NotificationQueueItem(
      notification: notification,
      processor: processor,
      timestamp: DateTime.now(),
    );

    _processingQueue.add(queueItem);
    print(
        '📥 Queued notification from ${notification.appName} (Queue size: ${_processingQueue.length})');

    _startProcessingIfNeeded();
  }

  /// Start processing queue if not already processing
  void _startProcessingIfNeeded() {
    if (_isProcessingQueue) return;

    _isProcessingQueue = true;
    _processNextItem();
  }

  /// Process next item in queue
  Future<void> _processNextItem() async {
    if (_processingQueue.isEmpty) {
      _isProcessingQueue = false;
      print('✅ Queue processing completed');
      return;
    }

    final item = _processingQueue.removeFirst();

    try {
      print(
          '🔄 Processing queued notification from ${item.notification.appName}...');
      await item.processor();
      print(
          '✅ Completed processing notification from ${item.notification.appName}');
    } catch (e) {
      print(
          '❌ Failed to process notification from ${item.notification.appName}: $e');
    }

    // Add small delay to prevent system overload
    await Future.delayed(const Duration(milliseconds: 500));

    // Process next item
    _processNextItem();
  }

  /// Get queue statistics
  Map<String, dynamic> getQueueStats() {
    return {
      'queueSize': _processingQueue.length,
      'isProcessing': _isProcessingQueue,
      'queueItems': _processingQueue
          .map((item) => {
                'app': item.notification.appName,
                'timestamp': item.timestamp.toIso8601String(),
              })
          .toList(),
    };
  }

  /// Clear queue (for emergency situations)
  void clearQueue() {
    _processingQueue.clear();
    _isProcessingQueue = false;
    print('🗑️ Notification processing queue cleared');
  }
}

/// Queue item representing a notification to be processed
class NotificationQueueItem {
  final AppNotification notification;
  final Future<void> Function() processor;
  final DateTime timestamp;

  NotificationQueueItem({
    required this.notification,
    required this.processor,
    required this.timestamp,
  });
}
