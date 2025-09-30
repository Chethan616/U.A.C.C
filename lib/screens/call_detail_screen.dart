// lib/screens/call_detail_screen.dart
import 'package:flutter/material.dart';
import '../models/enums.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/priority_badge.dart';
import '../services/ai_analysis_service.dart'
    show AIAnalysisService, CallAnalysis, TranscriptMessage;

class CallDetailScreen extends StatefulWidget {
  final CallData callData;

  const CallDetailScreen({
    Key? key,
    required this.callData,
  }) : super(key: key);

  /// Quickly spin up the screen with richly detailed mock data.
  ///
  /// This is handy for storybook previews, design reviews, or
  /// simply showcasing the end-to-end experience without wiring
  /// live call information.
  factory CallDetailScreen.sample({Key? key}) {
    return CallDetailScreen(
      key: key,
      callData: CallDetailSampleData.enterpriseDiscovery,
    );
  }

  @override
  State<CallDetailScreen> createState() => _CallDetailScreenState();
}

class _CallDetailScreenState extends State<CallDetailScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _taskController = TextEditingController();
  bool _isExpanded = false;

  final AIAnalysisService _aiService = AIAnalysisService();
  bool _isAnalyzing = false;
  bool _isRegenerating = false;
  CallAnalysis? _aiAnalysis;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _performCallAnalysis();
  }

  /// Perform AI analysis of the call
  Future<void> _performCallAnalysis() async {
    if (_isAnalyzing || widget.callData.transcript.isEmpty) return;

    setState(() {
      _isAnalyzing = true;
    });

    try {
      final analysis = await _aiService.analyzeCall(
        contactName: widget.callData.contactName,
        transcript: widget.callData.transcript,
        duration: widget.callData.duration,
        isIncoming: widget.callData.isIncoming,
      );

      setState(() {
        _aiAnalysis = analysis;
        _isAnalyzing = false;
      });
    } catch (e) {
      print('Error performing call analysis: $e');
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

  /// Regenerate AI summary
  Future<void> _regenerateCallSummary() async {
    if (_isRegenerating || widget.callData.transcript.isEmpty) return;

    setState(() {
      _isRegenerating = true;
    });

    try {
      final transcriptText = widget.callData.transcript
          .map((msg) => '${msg.speaker}: ${msg.text}')
          .join('\n');

      final newSummary = await _aiService.regenerateSummary(
        content: transcriptText,
        focusArea: 'call summary with key decisions and action items',
      );

      if (_aiAnalysis != null) {
        setState(() {
          _aiAnalysis = CallAnalysis(
            summary: newSummary,
            keyPoints: _aiAnalysis!.keyPoints,
            sentiment: _aiAnalysis!.sentiment,
            urgency: _aiAnalysis!.urgency,
            category: _aiAnalysis!.category,
            priority: _aiAnalysis!.priority,
            actionItems: _aiAnalysis!.actionItems,
          );
          _isRegenerating = false;
        });
      }
    } catch (e) {
      print('Error regenerating summary: $e');
      setState(() {
        _isRegenerating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to regenerate summary: ${e.toString()}'),
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
        title: 'Call Details',
        showBackButton: true,
        actions: [
          IconButton(
            onPressed: _shareCall,
            icon: const Icon(Icons.share),
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit Summary')),
              const PopupMenuItem(
                  value: 'export', child: Text('Export Transcript')),
              const PopupMenuItem(value: 'delete', child: Text('Delete Call')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Call Header
          _buildCallHeader(),

          // Tab Bar
          Container(
            color: Theme.of(context).colorScheme.surface,
            child: TabBar(
              controller: _tabController,
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor:
                  Theme.of(context).colorScheme.onSurfaceVariant,
              indicatorColor: Theme.of(context).colorScheme.primary,
              tabs: const [
                Tab(text: 'Summary', icon: Icon(Icons.summarize, size: 18)),
                Tab(
                    text: 'Transcript',
                    icon: Icon(Icons.text_fields, size: 18)),
                Tab(text: 'Actions', icon: Icon(Icons.task_alt, size: 18)),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSummaryTab(),
                _buildTranscriptTab(),
                _buildActionsTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createTask,
        icon: const Icon(Icons.add_task),
        label: const Text('Create Task'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }

  Widget _buildCallHeader() {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor:
                    Theme.of(context).colorScheme.primary.withOpacity(0.15),
                radius: 24,
                child: Icon(
                  Icons.person,
                  color: Theme.of(context).colorScheme.primary,
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
                        Expanded(
                          child: Text(
                            widget.callData.contactName,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        PriorityBadge(priority: widget.callData.priority),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          widget.callData.isIncoming
                              ? Icons.call_received
                              : Icons.call_made,
                          size: 16,
                          color: widget.callData.isIncoming
                              ? Theme.of(context).colorScheme.tertiary
                              : Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.callData.phoneNumber,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDuration(widget.callData.duration),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
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
                Icons.calendar_today,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Text(
                _formatDateTime(widget.callData.timestamp),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Spacer(),
              if (widget.callData.hasRecording)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.mic,
                        size: 12,
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Recorded',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.tertiary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI Analysis Loading State
          if (_isAnalyzing)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'AI analyzing call...',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),

          // AI Summary Card
          if (!_isAnalyzing)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          color: _aiAnalysis != null
                              ? Theme.of(context).colorScheme.secondary
                              : Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'AI Summary',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        if (_aiAnalysis != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'AI',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                    fontSize: 10,
                                  ),
                            ),
                          ),
                        ],
                        const Spacer(),
                        if (_aiAnalysis != null &&
                            widget.callData.transcript.isNotEmpty)
                          IconButton(
                            onPressed:
                                _isRegenerating ? null : _regenerateCallSummary,
                            icon: _isRegenerating
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.refresh, size: 18),
                            tooltip: 'Regenerate AI summary',
                          ),
                        IconButton(
                          onPressed: () =>
                              setState(() => _isExpanded = !_isExpanded),
                          icon: Icon(
                            _isExpanded ? Icons.expand_less : Icons.expand_more,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _aiAnalysis?.summary ?? widget.callData.summary,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: _isExpanded ? null : 3,
                      overflow: _isExpanded ? null : TextOverflow.ellipsis,
                    ),
                    if (_isExpanded) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => _shareCall(),
                            icon: const Icon(Icons.share, size: 18),
                            label: const Text('Share'),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: () => _editSummary(),
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text('Edit'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Key Points - Use AI analysis if available
          if (_isExpanded &&
              !_isAnalyzing &&
              (_aiAnalysis?.keyPoints.isNotEmpty == true ||
                  widget.callData.keyPoints.isNotEmpty)) ...[
            Text(
              'Key Points',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:
                      (_aiAnalysis?.keyPoints ?? widget.callData.keyPoints)
                          .map((point) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(top: 8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              point,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Call Analysis - Use AI analysis if available
          if (!_isAnalyzing) ...[
            Text(
              'Call Analysis',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildAnalysisItem(
                      'Sentiment',
                      _aiAnalysis?.sentiment ?? widget.callData.sentiment,
                      _getSentimentColor(
                          _aiAnalysis?.sentiment ?? widget.callData.sentiment),
                    ),
                    const Divider(),
                    _buildAnalysisItem(
                      'Urgency',
                      _aiAnalysis?.urgency ?? widget.callData.urgency,
                      _getUrgencyColor(
                          _aiAnalysis?.urgency ?? widget.callData.urgency),
                    ),
                    const Divider(),
                    _buildAnalysisItem(
                      'Category',
                      _aiAnalysis?.category ?? widget.callData.category,
                      Theme.of(context).colorScheme.primary,
                    ),
                    const Divider(),
                    _buildAnalysisItem(
                      'Priority',
                      _getDisplayPriority(),
                      _getDisplayPriorityColor(),
                    ),
                  ],
                ),
              ),
            ),

            // AI Action Items
            if (_isExpanded &&
                (_aiAnalysis?.actionItems.isNotEmpty == true ||
                    widget.callData.actionItems.isNotEmpty)) ...[
              const SizedBox(height: 16),
              _buildActionItemsCard(),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildTranscriptTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Transcript',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _copyTranscript,
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Copy'),
              ),
              TextButton.icon(
                onPressed: _exportTranscript,
                icon: const Icon(Icons.download, size: 16),
                label: const Text('Export'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.callData.transcript.map((message) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: message.isUser
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Theme.of(context)
                                    .colorScheme
                                    .secondaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              message.isUser ? 'Y' : 'C',
                              style: TextStyle(
                                color: message.isUser
                                    ? Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer
                                    : Theme.of(context)
                                        .colorScheme
                                        .onSecondaryContainer,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    message.speaker,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    message.timestamp,
                                    style:
                                        Theme.of(context).textTheme.labelSmall,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                message.text,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Action Items',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),

          // Existing Action Items
          ...widget.callData.actionItems.map((action) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: Checkbox(
                  value: action.isCompleted,
                  onChanged: (value) => _toggleActionItem(action),
                  activeColor: Theme.of(context).colorScheme.tertiary,
                ),
                title: Text(
                  action.title,
                  style: TextStyle(
                    decoration:
                        action.isCompleted ? TextDecoration.lineThrough : null,
                    color: action.isCompleted
                        ? Theme.of(context).colorScheme.onSurfaceVariant
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                subtitle: Text(
                  'Due: ${action.dueDate}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) => _handleActionMenu(value, action),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ),
            );
          }).toList(),

          const SizedBox(height: 16),

          // Add New Action Item
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create New Task',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _taskController,
                    decoration: const InputDecoration(
                      hintText: 'Enter task description...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _addActionItem,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add Task'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: _generateActionItems,
                        icon: const Icon(Icons.auto_awesome, size: 16),
                        label: const Text('AI Generate'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisItem(String label, String value, Color color) {
    return Row(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Color _getSentimentColor(String sentiment) {
    switch (sentiment.toLowerCase()) {
      case 'positive':
        return Theme.of(context).colorScheme.tertiary;
      case 'negative':
        return Theme.of(context).colorScheme.error;
      default:
        return Theme.of(context).colorScheme.secondary;
    }
  }

  Color _getUrgencyColor(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'high':
        return Theme.of(context).colorScheme.error;
      case 'medium':
        return Theme.of(context).colorScheme.secondary;
      default:
        return Theme.of(context).colorScheme.tertiary;
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _shareCall() {
    // Implementation for sharing call details
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'edit':
        _editSummary();
        break;
      case 'export':
        _exportTranscript();
        break;
      case 'delete':
        _deleteCall();
        break;
    }
  }

  void _createTask() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Task'),
        content: const Text('Task creation dialog will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  /// Helper methods for priority handling
  String _getPriorityText(PriorityLevel priority) {
    return priority.label;
  }

  Color _getPriorityColor(PriorityLevel priority) {
    switch (priority) {
      case PriorityLevel.low:
        return Colors.green;
      case PriorityLevel.medium:
        return Colors.orange;
      case PriorityLevel.high:
        return Colors.red;
      case PriorityLevel.urgent:
        return Colors.red.shade800;
    }
  }

  /// Get display priority text from AI analysis or fallback data
  String _getDisplayPriority() {
    if (_aiAnalysis?.priority != null) {
      // AI analysis returns string, convert to display format
      final priority = _aiAnalysis!.priority.toString().toLowerCase();
      switch (priority) {
        case 'low':
          return 'Low';
        case 'medium':
          return 'Medium';
        case 'high':
          return 'High';
        case 'urgent':
          return 'Urgent';
        default:
          return priority.toUpperCase();
      }
    }
    return _getPriorityText(widget.callData.priority);
  }

  /// Get display priority color from AI analysis or fallback data
  Color _getDisplayPriorityColor() {
    if (_aiAnalysis?.priority != null) {
      final priority = _aiAnalysis!.priority.toString().toLowerCase();
      switch (priority) {
        case 'low':
          return Colors.green;
        case 'medium':
          return Colors.orange;
        case 'high':
          return Colors.red;
        case 'urgent':
          return Colors.red.shade800;
        default:
          return Theme.of(context).colorScheme.primary;
      }
    }
    return _getPriorityColor(widget.callData.priority);
  }

  /// Get action priority color for AI action items
  Color _getActionPriorityColor(String? priority) {
    final priorityStr = priority?.toLowerCase() ?? 'medium';
    switch (priorityStr) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.red;
      case 'urgent':
        return Colors.red.shade800;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  /// Build action items card with AI analysis data
  Widget _buildActionItemsCard() {
    final hasAIActions = _aiAnalysis?.actionItems.isNotEmpty == true;
    final hasLocalActions = widget.callData.actionItems.isNotEmpty;

    if (!hasAIActions && !hasLocalActions) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Action Items',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (_aiAnalysis != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'AI Generated',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontSize: 10,
                      ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Render AI action items if available
                if (hasAIActions)
                  ...(_aiAnalysis!.actionItems.map((action) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            size: 20,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  action.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  action.description,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                if (action.priority.toLowerCase() != 'low') ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Priority: ${action.priority}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: _getActionPriorityColor(
                                              action.priority),
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList()),

                // Render local action items if no AI actions or as fallback
                if (!hasAIActions && hasLocalActions)
                  ...(widget.callData.actionItems.map((action) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            action.isCompleted
                                ? Icons.check_circle
                                : Icons.check_circle_outline,
                            size: 20,
                            color: action.isCompleted
                                ? Colors.green
                                : Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  action.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w500,
                                        decoration: action.isCompleted
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                ),
                                if (action.dueDate.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Due: ${action.dueDate}',
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
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList()),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _editSummary() {
    // Implementation for editing summary
  }

  void _copyTranscript() {
    // Implementation for copying transcript
  }

  void _exportTranscript() {
    // Implementation for exporting transcript
  }

  void _deleteCall() {
    // Implementation for deleting call
  }

  void _toggleActionItem(ActionItem action) {
    // Implementation for toggling action item completion
  }

  void _handleActionMenu(String action, ActionItem item) {
    // Implementation for handling action item menu
  }

  void _addActionItem() {
    if (_taskController.text.isNotEmpty) {
      // Implementation for adding new action item
      _taskController.clear();
    }
  }

  void _generateActionItems() {
    // Implementation for AI-generated action items
  }

  @override
  void dispose() {
    _tabController.dispose();
    _taskController.dispose();
    super.dispose();
  }
}

// Data Models
class CallData {
  final String contactName;
  final String phoneNumber;
  final DateTime timestamp;
  final Duration duration;
  final bool isIncoming;
  final bool hasRecording;
  final String summary;
  final List<String> keyPoints;
  final String sentiment;
  final String urgency;
  final String category;
  final PriorityLevel priority;
  final List<TranscriptMessage> transcript;
  final List<ActionItem> actionItems;

  CallData({
    required this.contactName,
    required this.phoneNumber,
    required this.timestamp,
    required this.duration,
    required this.isIncoming,
    required this.hasRecording,
    required this.summary,
    required this.keyPoints,
    required this.sentiment,
    required this.urgency,
    required this.category,
    required this.priority,
    required this.transcript,
    required this.actionItems,
  });
}

class ActionItem {
  final String id;
  final String title;
  final String dueDate;
  final bool isCompleted;

  ActionItem({
    required this.id,
    required this.title,
    required this.dueDate,
    required this.isCompleted,
  });
}

/// Centralized sample call data used for demos, QA, and design reviews.
///
/// The data purposefully mirrors a realistic post-sales discovery call with
/// a mix of positive sentiment, medium urgency, and actionable next steps.
class CallDetailSampleData {
  CallDetailSampleData._();

  /// A rich demonstration call that exercises the entire screen surface.
  static final CallData enterpriseDiscovery = CallData(
    contactName: 'Aisha Rahman',
    phoneNumber: '+1 (415) 555-0138',
    timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
    duration: const Duration(minutes: 26, seconds: 48),
    isIncoming: true,
    hasRecording: true,
    summary:
        'Aisha confirmed the rollout timeline, aligned on success metrics, and'
        ' committed to looping in procurement by mid-week. The conversation'
        ' ended with a clear plan for pilot activation and two follow-up tasks.',
    keyPoints: const [
      'Pilot launch confirmed for next Tuesday with a two-week success window',
      'Sentiment remained confident; customer is eager but needs procurement buy-in',
      'Next touchpoint scheduled for Wednesday at 2:30 PM PT',
    ],
    sentiment: 'Positive',
    urgency: 'Medium',
    category: 'Customer Success',
    priority: PriorityLevel.high,
    transcript: [
      TranscriptMessage(
        speaker: 'You',
        text:
            'Aisha, thanks for making the time. I wanted to confirm the rollout plan for the analytics dashboard.',
        timestamp: '0:00',
        isUser: true,
      ),
      TranscriptMessage(
        speaker: 'Aisha Rahman',
        text:
            'Absolutely. We are targeting next Tuesday for the pilot start and expect to have the success metrics finalized by Friday.',
        timestamp: '0:18',
        isUser: false,
      ),
      TranscriptMessage(
        speaker: 'You',
        text:
            'Great. I will prepare the onboarding checklist and share the enablement deck today.',
        timestamp: '1:02',
        isUser: true,
      ),
      TranscriptMessage(
        speaker: 'Aisha Rahman',
        text:
            'Perfect. Could you also send over the SOC 2 compliance summary? Procurement asked for it.',
        timestamp: '2:11',
        isUser: false,
      ),
      TranscriptMessage(
        speaker: 'You',
        text:
            'I have it ready. I will attach it to the follow-up email and loop in your procurement partner.',
        timestamp: '2:32',
        isUser: true,
      ),
      TranscriptMessage(
        speaker: 'Aisha Rahman',
        text:
            'Sounds good. Let us sync again Wednesday at 2:30 so I can share feedback from the ops team.',
        timestamp: '3:02',
        isUser: false,
      ),
      TranscriptMessage(
        speaker: 'You',
        text:
            'Booked. You will get the calendar invite in a couple of minutes. Anything else on your list?',
        timestamp: '3:19',
        isUser: true,
      ),
      TranscriptMessage(
        speaker: 'Aisha Rahman',
        text:
            'That covers it for now. Really appreciate the quick turnaround on the training assets.',
        timestamp: '3:38',
        isUser: false,
      ),
    ],
    actionItems: [
      ActionItem(
        id: 'task-001',
        title: 'Email onboarding deck and SOC 2 summary to Aisha',
        dueDate: 'Today, 5:00 PM',
        isCompleted: false,
      ),
      ActionItem(
        id: 'task-002',
        title: 'Send procurement contact introduction',
        dueDate: 'Tomorrow, 11:00 AM',
        isCompleted: false,
      ),
      ActionItem(
        id: 'task-003',
        title: 'Prepare agenda for Wednesday sync',
        dueDate: 'Wednesday, 1:30 PM',
        isCompleted: true,
      ),
    ],
  );
}
