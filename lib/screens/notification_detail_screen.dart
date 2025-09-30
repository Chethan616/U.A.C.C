// lib/screens/notification_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/enums.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/priority_badge.dart';
import '../services/ai_analysis_service.dart';
import '../services/app_launcher_service.dart';
import '../services/intelligent_scheduling_service.dart';

import '../services/calendar_service.dart';

class NotificationDetailScreen extends StatefulWidget {
  final NotificationData notificationData;

  const NotificationDetailScreen({
    Key? key,
    required this.notificationData,
  }) : super(key: key);

  @override
  State<NotificationDetailScreen> createState() =>
      _NotificationDetailScreenState();
}

class _NotificationDetailScreenState extends State<NotificationDetailScreen> {
  bool _isActionExpanded = false;
  final TextEditingController _noteController = TextEditingController();
  final AIAnalysisService _aiService = AIAnalysisService();
  final AppLauncherService _appLauncher = AppLauncherService();
  final IntelligentSchedulingService _schedulingService =
      IntelligentSchedulingService();

  bool _isAnalyzing = false;
  bool _isRegenerating = false;
  bool _isCreatingEvent = false;
  bool _isCreatingTask = false;
  NotificationAnalysis? _aiAnalysis;
  AutoSchedulingResult? _autoSchedulingResult;

  // Cache for AI analysis results with size management
  static final Map<String, NotificationAnalysis> _analysisCache = {};
  static const int _maxCacheSize = 100; // Limit cache to 100 entries

  @override
  void initState() {
    super.initState();
    _performAIAnalysis();
  }

  /// Perform AI analysis of the notification
  Future<void> _performAIAnalysis() async {
    if (_isAnalyzing) return;

    // Create cache key from notification content including unique ID to ensure each notification gets its own analysis
    final cacheKey =
        '${widget.notificationData.id}_${widget.notificationData.appName}_${widget.notificationData.title}_${widget.notificationData.body}_${widget.notificationData.timestamp.millisecondsSinceEpoch}'
            .hashCode
            .toString();

    // Check if we have cached analysis
    if (_analysisCache.containsKey(cacheKey)) {
      setState(() {
        _aiAnalysis = _analysisCache[cacheKey];
        _isAnalyzing = false;
      });
      return;
    }

    setState(() {
      _isAnalyzing = true;
    });

    try {
      // Check if notification has any content at all
      final hasAnyContent = widget.notificationData.appName.isNotEmpty ||
          widget.notificationData.title.isNotEmpty ||
          widget.notificationData.body.isNotEmpty ||
          widget.notificationData.bigText.isNotEmpty ||
          (widget.notificationData.subText.isNotEmpty);

      if (!hasAnyContent) {
        print(
            '⚠️ Warning: Completely empty notification detected - this indicates a notification capture issue');
      }

      // Perform AI analysis with comprehensive notification content
      final analysis = await _aiService.analyzeNotification(
        appName: widget.notificationData.appName,
        title: widget.notificationData.title,
        body: widget.notificationData.body,
        bigText: widget.notificationData.bigText,
        subText: widget.notificationData.subText,
      );

      // Cache the analysis result with size management
      _analysisCache[cacheKey] = analysis;
      _cleanupCacheIfNeeded();

      // Perform intelligent scheduling analysis
      final autoScheduling = await _schedulingService.analyzeAndSchedule(
        appName: widget.notificationData.appName,
        title: widget.notificationData.title,
        body: widget.notificationData.body,
        bigText: widget.notificationData.bigText,
        subText: widget.notificationData.subText,
        urgency: analysis.urgency,
        requiresAction: analysis.requiresAction,
      );

      setState(() {
        _aiAnalysis = analysis;
        _autoSchedulingResult = autoScheduling;
        _isAnalyzing = false;
      });

      // Show auto-creation feedback
      if (autoScheduling.hasAnyCreated) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Auto-created: ${autoScheduling.summary}'),
              backgroundColor: Theme.of(context).colorScheme.tertiary,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      print('Error performing AI analysis: $e');
      setState(() {
        _isAnalyzing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('AI analysis failed: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// Clean up cache when it exceeds maximum size to prevent memory leaks
  static void _cleanupCacheIfNeeded() {
    if (_analysisCache.length > _maxCacheSize) {
      // Remove oldest entries (first half of the cache)
      final keys = _analysisCache.keys.toList();
      final keysToRemove = keys.take(_maxCacheSize ~/ 2);
      for (String key in keysToRemove) {
        _analysisCache.remove(key);
      }
    }
  }

  /// Regenerate AI analysis with new focus
  Future<void> _regenerateAnalysis() async {
    if (_isRegenerating) return;

    setState(() {
      _isRegenerating = true;
    });

    try {
      final content = '''
App: ${widget.notificationData.appName}
Title: ${widget.notificationData.title}
Body: ${widget.notificationData.body}
SubText: ${widget.notificationData.subText}
Additional: ${widget.notificationData.bigText}
''';

      final newSummary = await _aiService.regenerateSummary(
        content: content,
        focusArea: 'actionable insights and key information',
      );

      if (_aiAnalysis != null) {
        setState(() {
          _aiAnalysis = NotificationAnalysis(
            summary: newSummary,
            sentiment: _aiAnalysis!.sentiment,
            urgency: _aiAnalysis!.urgency,
            requiresAction: _aiAnalysis!.requiresAction,
            containsPersonalInfo: _aiAnalysis!.containsPersonalInfo,
            category: _aiAnalysis!.category,
            suggestedActions: _aiAnalysis!.suggestedActions,
          );
          _isRegenerating = false;
        });
      }
    } catch (e) {
      print('Error regenerating analysis: $e');
      setState(() {
        _isRegenerating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to regenerate analysis: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'Notification Details',
        showBackButton: true,
        actions: [
          IconButton(
            onPressed: _shareNotification,
            icon: const Icon(Icons.share),
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                  value: 'mark_read', child: Text('Mark as Read')),
              const PopupMenuItem(value: 'archive', child: Text('Archive')),
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Notification Header
            _buildNotificationHeader(),

            const SizedBox(height: 16),

            // AI Summary Section
            _buildSummarySection(),

            const SizedBox(height: 16),

            // Auto-scheduling Results
            if (_autoSchedulingResult?.hasAnyCreated ?? false)
              _buildAutoSchedulingResults(),

            const SizedBox(height: 16),

            // Original Notification Content
            _buildOriginalContent(),

            const SizedBox(height: 16),

            // Suggested Actions
            _buildSuggestedActions(),

            const SizedBox(height: 16),

            // Related Notifications
            if (widget.notificationData.relatedNotifications.isNotEmpty)
              _buildRelatedNotifications(),

            const SizedBox(height: 16),

            // Notes Section
            _buildNotesSection(),

            const SizedBox(height: 100), // Space for FAB
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActions(),
    );
  }

  Widget _buildNotificationHeader() {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getAppColor(widget.notificationData.appName)
                      .withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: widget.notificationData.appIcon.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          widget.notificationData.appIcon,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Icon(
                        _getAppIcon(widget.notificationData.appName),
                        color: _getAppColor(widget.notificationData.appName),
                        size: 24,
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            widget.notificationData.appName,
                            style: Theme.of(context).textTheme.titleLarge,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        PriorityBadge(
                            priority: widget.notificationData.priority),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.notificationData.category,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  _formatDateTime(widget.notificationData.timestamp),
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.notificationData.isRead
                      ? Theme.of(context)
                          .colorScheme
                          .secondary
                          .withOpacity(0.15)
                      : Theme.of(context).colorScheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.notificationData.isRead ? 'Read' : 'Unread',
                  style: TextStyle(
                    color: widget.notificationData.isRead
                        ? Theme.of(context).colorScheme.tertiary
                        : Theme.of(context).colorScheme.secondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAutoSchedulingResults() {
    if (_autoSchedulingResult == null ||
        !_autoSchedulingResult!.hasAnyCreated) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        color: Theme.of(context).colorScheme.tertiary.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.auto_fix_high,
                    color: Theme.of(context).colorScheme.tertiary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Auto-created Items',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.tertiary,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_autoSchedulingResult!.taskCreated) ...[
                ListTile(
                  leading: Icon(
                    Icons.task_alt,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    _autoSchedulingResult!.taskTitle ?? 'Task Created',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: const Text('Google Tasks'),
                  trailing: Icon(
                    Icons.check_circle,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummarySection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: Theme.of(context).colorScheme.secondary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'AI Analysis',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  if (_isAnalyzing)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    PopupMenuButton<String>(
                      onSelected: _handleAnalysisAction,
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'regenerate',
                          child: Row(
                            children: [
                              Icon(Icons.refresh, size: 18),
                              SizedBox(width: 8),
                              Text('Regenerate'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'copy',
                          child: Row(
                            children: [
                              Icon(Icons.copy, size: 18),
                              SizedBox(width: 8),
                              Text('Copy Analysis'),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (_isAnalyzing)
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Analyzing notification with AI...',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ),
                    ],
                  ),
                )
              else if (_aiAnalysis != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _aiAnalysis!.summary,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    // Analysis Tags
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildAnalysisChip('Sentiment', _aiAnalysis!.sentiment,
                            _getSentimentColor(_aiAnalysis!.sentiment)),
                        _buildAnalysisChip('Urgency', _aiAnalysis!.urgency,
                            _getUrgencyColor(_aiAnalysis!.urgency)),
                        _buildAnalysisChip('Category', _aiAnalysis!.category,
                            Theme.of(context).colorScheme.primary),
                        if (_aiAnalysis!.requiresAction)
                          _buildAnalysisChip('Action Required', '',
                              Theme.of(context).colorScheme.error),
                        if (_aiAnalysis!.containsPersonalInfo)
                          _buildAnalysisChip('Personal Info', '',
                              Theme.of(context).colorScheme.secondary),
                      ],
                    ),
                  ],
                )
              else
                Text(
                  widget.notificationData.aiSummary,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOriginalContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Original Notification',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .scaffoldBackgroundColor
                      .withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: Theme.of(context).colorScheme.outline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.notificationData.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (widget.notificationData.body.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        widget.notificationData.body,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                    if (widget.notificationData.bigText.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        widget.notificationData.bigText,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestedActions() {
    // Use AI analysis actions if available, otherwise fall back to default
    final List<dynamic> actions = _aiAnalysis?.suggestedActions ??
        widget.notificationData.suggestedActions;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      'Suggested Actions',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  if (_aiAnalysis != null)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .secondary
                            .withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'AI',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () =>
                        setState(() => _isActionExpanded = !_isActionExpanded),
                    icon: Icon(
                      _isActionExpanded ? Icons.expand_less : Icons.expand_more,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // AI-Suggested Actions with descriptions
              if (actions.isNotEmpty)
                ...actions.take(3).map((action) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => _executeAIAction(action),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Icon(
                                  _getActionIcon(_getActionIconString(action)),
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _getActionTitle(action),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _getActionDescription(action),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ))
              else
                // Fallback - Open App Button when no AI actions available
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _openApp,
                    icon: Icon(_getAppIcon(widget.notificationData.appName)),
                    label: Text('Open ${widget.notificationData.appName}'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _getAppColor(widget.notificationData.appName),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),

              if (_isAnalyzing)
                Text(
                  'Generating action suggestions...',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRelatedNotifications() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Related Notifications',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children:
                  widget.notificationData.relatedNotifications.map((related) {
                final index = widget.notificationData.relatedNotifications
                    .indexOf(related);
                return Column(
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withOpacity(0.15),
                        child: Icon(
                          _getAppIcon(related.appName),
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                      ),
                      title: Text(related.title),
                      subtitle: Text(related.appName),
                      trailing: Text(
                        _formatTimeAgo(related.timestamp),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      onTap: () => _openRelatedNotification(related),
                    ),
                    if (index <
                        widget.notificationData.relatedNotifications.length - 1)
                      const Divider(height: 1),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Personal Notes',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _noteController,
                decoration: const InputDecoration(
                  hintText: 'Add your notes about this notification...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isCreatingTask ? null : _openTaskCreationDialog,
                  icon: _isCreatingTask
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_task, size: 16),
                  label: const Text('Create Task'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalysisChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        value.isEmpty ? label : '$label: $value',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildFloatingActions() {
    return FloatingActionButton(
      heroTag: "create_event_unique",
      onPressed: _isCreatingEvent ? null : _createCalendarEvent,
      backgroundColor: Theme.of(context).colorScheme.secondary,
      child: _isCreatingEvent
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.calendar_month),
    );
  }

  Color _getAppColor(String appName) {
    final colorScheme = Theme.of(context).colorScheme;
    final appLower = appName.toLowerCase();

    switch (appLower) {
      case 'whatsapp':
        return Colors.green;
      case 'gmail':
      case 'email':
        return Colors.red;
      case 'instagram':
        return Colors.purple;
      case 'facebook':
        return Colors.blue;
      case 'phone':
        return Colors.green;
      default:
        return colorScheme.onSurfaceVariant;
    }
  }

  IconData _getAppIcon(String appName) {
    final appLower = appName.toLowerCase();

    switch (appLower) {
      case 'whatsapp':
        return Icons.message;
      case 'gmail':
      case 'email':
        return Icons.email;
      case 'instagram':
        return Icons.camera_alt;
      case 'facebook':
        return Icons.facebook;
      case 'phone':
        return Icons.phone;
      default:
        return Icons.notification_important;
    }
  }

  Color _getSentimentColor(String sentiment) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (sentiment.toLowerCase()) {
      case 'positive':
        return colorScheme.tertiary;
      case 'negative':
        return colorScheme.error;
      default:
        return colorScheme.secondary;
    }
  }

  Color _getUrgencyColor(String urgency) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (urgency.toLowerCase()) {
      case 'high':
        return colorScheme.error;
      case 'medium':
        return colorScheme.secondary;
      default:
        return colorScheme.tertiary;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _shareNotification() {
    // Implementation for sharing notification
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'mark_read':
        _markAsRead();
        break;
      case 'archive':
        _archiveNotification();
        break;
      case 'delete':
        _deleteNotification();
        break;
    }
  }

  void _handleAnalysisAction(String action) {
    switch (action) {
      case 'regenerate':
        _regenerateAnalysis();
        break;
      case 'copy':
        _copyAnalysis();
        break;
    }
  }

  void _copyAnalysis() {
    if (_aiAnalysis != null) {
      final analysisText = '''
AI Analysis:
${_aiAnalysis!.summary}

Sentiment: ${_aiAnalysis!.sentiment}
Urgency: ${_aiAnalysis!.urgency}
Category: ${_aiAnalysis!.category}
Requires Action: ${_aiAnalysis!.requiresAction ? 'Yes' : 'No'}
Contains Personal Info: ${_aiAnalysis!.containsPersonalInfo ? 'Yes' : 'No'}
''';

      Clipboard.setData(ClipboardData(text: analysisText));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Analysis copied to clipboard'),
          backgroundColor: Theme.of(context).colorScheme.tertiary,
        ),
      );
    }
  }

  Future<void> _executeAIAction(dynamic action) async {
    String title = '';
    String icon = '';

    // Handle both SuggestedActionData and SuggestedAction types
    if (action is SuggestedActionData) {
      title = action.title;
      icon = action.icon;
    } else if (action is SuggestedAction) {
      title = action.title;
      icon = 'open';
    } else {
      title = 'Unknown Action';
      icon = 'open';
    }

    // Show execution feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Executing: $title'),
        backgroundColor: Theme.of(context).colorScheme.tertiary,
      ),
    );

    try {
      bool success = false;

      // Perform action based on type
      switch (icon.toLowerCase()) {
        case 'reply':
        case 'message':
          // For social apps, try to open the specific app
          success =
              await _appLauncher.launchApp(widget.notificationData.appName);
          break;
        case 'call':
          // Extract phone number if available and launch dialer
          success = await _appLauncher.launchPhone('');
          break;
        case 'email':
          // Launch email app
          success = await _appLauncher.launchApp('gmail');
          break;
        case 'payment':
        case 'view':
        case 'open':
        default:
          // Default action - open the app
          success =
              await _appLauncher.launchApp(widget.notificationData.appName);
          break;
      }

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open ${widget.notificationData.appName}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      print('Error executing action: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to execute action: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  String _getActionTitle(dynamic action) {
    if (action is SuggestedActionData) {
      return action.title;
    } else if (action is SuggestedAction) {
      return action.title;
    }
    return 'Action';
  }

  String _getActionIconString(dynamic action) {
    if (action is SuggestedActionData) {
      return action.icon;
    } else if (action is SuggestedAction) {
      return 'open'; // Default for SuggestedAction
    }
    return 'open';
  }

  String _getActionDescription(dynamic action) {
    if (action is SuggestedActionData) {
      return action.description;
    } else if (action is SuggestedAction) {
      return 'Tap to perform this action';
    }
    return 'Perform action';
  }

  IconData _getActionIcon(String iconType) {
    switch (iconType.toLowerCase()) {
      case 'reply':
        return Icons.reply;
      case 'open':
        return Icons.open_in_new;
      case 'payment':
        return Icons.payment;
      case 'view':
        return Icons.visibility;
      case 'call':
        return Icons.call;
      case 'email':
        return Icons.email;
      case 'message':
        return Icons.message;
      default:
        return Icons.touch_app;
    }
  }

  void _openRelatedNotification(RelatedNotification notification) {
    // Implementation for opening related notification
  }

  void _openTaskCreationDialog() {
    setState(() => _isCreatingTask = true);

    showDialog(
      context: context,
      builder: (context) => TaskCreationDialog(
        notificationData: widget.notificationData,
        aiAnalysis: _aiAnalysis,
        schedulingService: _schedulingService,
        onTaskCreated: (taskId, taskTitle) {
          setState(() => _isCreatingTask = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Task "$taskTitle" created successfully'),
                backgroundColor: Theme.of(context).colorScheme.tertiary,
              ),
            );
          }
        },
      ),
    ).then((_) {
      setState(() => _isCreatingTask = false);
    });
  }

  Future<void> _openApp() async {
    try {
      final success =
          await _appLauncher.launchApp(widget.notificationData.appName);

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open ${widget.notificationData.appName}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      print('Error opening app: $e');
    }
  }

  Future<void> _createCalendarEvent() async {
    if (_isCreatingEvent) return;

    setState(() => _isCreatingEvent = true);

    try {
      final event = await CalendarService.createEvent(
        title: 'Follow-up: ${widget.notificationData.title}',
        description: '''
From: ${widget.notificationData.appName}
Content: ${widget.notificationData.body}

AI Summary: ${_aiAnalysis?.summary ?? 'No AI analysis available'}
        ''',
        startTime: DateTime.now().add(const Duration(hours: 1)),
        endTime: DateTime.now().add(const Duration(hours: 2)),
        isAllDay: false,
        priority: EventPriority.normal,
      );

      setState(() => _isCreatingEvent = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Calendar event created: ${event.title}'),
            backgroundColor: Theme.of(context).colorScheme.tertiary,
          ),
        );
      }
    } catch (e) {
      print('Error creating calendar event: $e');
      setState(() => _isCreatingEvent = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create calendar event: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _markAsRead() {
    setState(() {
      // Update read status
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Marked as read'),
        backgroundColor: Theme.of(context).colorScheme.tertiary,
      ),
    );
  }

  void _archiveNotification() {
    // Implementation for archiving notification
  }

  void _deleteNotification() {
    // Implementation for deleting notification
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }
}

// Data Models
class NotificationData {
  final String id;
  final String appName;
  final String appIcon;
  final String title;
  final String body;
  final String bigText;
  final String subText;
  final String category;
  final DateTime timestamp;
  final bool isRead;
  final PriorityLevel priority;
  final String aiSummary;
  final String sentiment;
  final String urgency;
  final bool requiresAction;
  final bool containsPersonalInfo;
  final List<SuggestedAction> suggestedActions;
  final List<RelatedNotification> relatedNotifications;

  NotificationData({
    required this.id,
    required this.appName,
    required this.appIcon,
    required this.title,
    required this.body,
    required this.bigText,
    required this.subText,
    required this.category,
    required this.timestamp,
    required this.isRead,
    required this.priority,
    required this.aiSummary,
    required this.sentiment,
    required this.urgency,
    required this.requiresAction,
    required this.containsPersonalInfo,
    required this.suggestedActions,
    required this.relatedNotifications,
  });
}

class SuggestedAction {
  final String id;
  final String title;
  final IconData icon;
  final String description;

  SuggestedAction({
    required this.id,
    required this.title,
    required this.icon,
    required this.description,
  });
}

class RelatedNotification {
  final String id;
  final String appName;
  final String title;
  final DateTime timestamp;

  RelatedNotification({
    required this.id,
    required this.appName,
    required this.title,
    required this.timestamp,
  });
}

/// Task Creation Dialog with AI suggestions
class TaskCreationDialog extends StatefulWidget {
  final NotificationData notificationData;
  final NotificationAnalysis? aiAnalysis;
  final IntelligentSchedulingService schedulingService;
  final Function(String?, String) onTaskCreated;

  const TaskCreationDialog({
    Key? key,
    required this.notificationData,
    required this.aiAnalysis,
    required this.schedulingService,
    required this.onTaskCreated,
  }) : super(key: key);

  @override
  State<TaskCreationDialog> createState() => _TaskCreationDialogState();
}

class _TaskCreationDialogState extends State<TaskCreationDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isCreating = false;
  DateTime? _selectedDueDate;
  String _selectedPriority = 'medium';

  @override
  void initState() {
    super.initState();
    _generateAISuggestions();
  }

  void _generateAISuggestions() {
    final appName = widget.notificationData.appName;
    final title = widget.notificationData.title;
    final body = widget.notificationData.body;

    String suggestedTitle = '';
    if (title.isNotEmpty) {
      if (appName.toLowerCase().contains('payment') ||
          appName.toLowerCase().contains('bank') ||
          appName.toLowerCase().contains('pay')) {
        suggestedTitle = 'Follow up on: $title';
      } else if (appName.toLowerCase().contains('email') ||
          appName.toLowerCase().contains('gmail')) {
        suggestedTitle = 'Respond to: $title';
      } else {
        suggestedTitle = 'Action required: $title';
      }
    }

    String suggestedDescription = '''
From: $appName
Original: $title
${body.isNotEmpty ? '\nDetails: $body' : ''}

${widget.aiAnalysis?.summary ?? 'No AI analysis available'}
''';

    _titleController.text = suggestedTitle;
    _descriptionController.text = suggestedDescription;

    if (widget.aiAnalysis != null) {
      _selectedPriority = widget.aiAnalysis!.urgency.toLowerCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.add_task,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          const Text('Create Task'),
          if (widget.aiAnalysis != null)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color:
                    Theme.of(context).colorScheme.secondary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'AI',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Task Title',
                border: OutlineInputBorder(),
              ),
              maxLength: 100,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              maxLength: 500,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedPriority,
              decoration: const InputDecoration(
                labelText: 'Priority',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'low', child: Text('Low')),
                DropdownMenuItem(value: 'medium', child: Text('Medium')),
                DropdownMenuItem(value: 'high', child: Text('High')),
              ],
              onChanged: (value) => setState(() => _selectedPriority = value!),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(_selectedDueDate == null
                  ? 'Select Due Date (Optional)'
                  : 'Due: ${_formatDate(_selectedDueDate!)}'),
              trailing: _selectedDueDate != null
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _selectedDueDate = null),
                    )
                  : null,
              onTap: _selectDueDate,
            ),
            if (widget.aiAnalysis != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        Theme.of(context).colorScheme.outline.withOpacity(0.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 16,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'AI Analysis',
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.aiAnalysis!.summary,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isCreating ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isCreating ? null : _createTask,
          child: _isCreating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create Task'),
        ),
      ],
    );
  }

  Future<void> _selectDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() => _selectedDueDate = date);
    }
  }

  Future<void> _createTask() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a task title'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      final taskId = await widget.schedulingService.createManualTask(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        priority: _selectedPriority,
        dueDate: _selectedDueDate,
      );

      setState(() => _isCreating = false);

      if (taskId != null) {
        widget.onTaskCreated(taskId, _titleController.text.trim());
        Navigator.pop(context);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to create task'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isCreating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating task: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
