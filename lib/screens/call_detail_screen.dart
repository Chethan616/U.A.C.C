// lib/screens/call_detail_screen.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/enums.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/priority_badge.dart';

class CallDetailScreen extends StatefulWidget {
  final CallData callData;

  const CallDetailScreen({
    Key? key,
    required this.callData,
  }) : super(key: key);

  @override
  State<CallDetailScreen> createState() => _CallDetailScreenState();
}

class _CallDetailScreenState extends State<CallDetailScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _taskController = TextEditingController();
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.base,
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
            color: AppColors.surface,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.muted,
              indicatorColor: AppColors.primary,
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
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.text,
      ),
    );
  }

  Widget _buildCallHeader() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withOpacity(0.15),
                radius: 24,
                child: const Icon(
                  Icons.person,
                  color: AppColors.primary,
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
                              ? AppColors.success
                              : AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.callData.phoneNumber,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.muted,
                                  ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: AppColors.muted,
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
                color: AppColors.muted,
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
                    color: AppColors.success.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.mic,
                        size: 12,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Recorded',
                        style: TextStyle(
                          color: AppColors.success,
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
          // AI Summary Card
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
                        color: AppColors.accent,
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
                      const Spacer(),
                      IconButton(
                        onPressed: () =>
                            setState(() => _isExpanded = !_isExpanded),
                        icon: Icon(
                          _isExpanded ? Icons.expand_less : Icons.expand_more,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.callData.summary,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: _isExpanded ? null : 3,
                    overflow: _isExpanded ? null : TextOverflow.ellipsis,
                  ),
                  if (_isExpanded) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _regenerateSummary,
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Regenerate'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: _editSummary,
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('Edit'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Key Points
          if (widget.callData.keyPoints.isNotEmpty) ...[
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
                  children: widget.callData.keyPoints.map((point) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(top: 8),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
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

          // Sentiment Analysis
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
                  _buildAnalysisItem('Sentiment', widget.callData.sentiment,
                      _getSentimentColor(widget.callData.sentiment)),
                  const Divider(),
                  _buildAnalysisItem('Urgency', widget.callData.urgency,
                      _getUrgencyColor(widget.callData.urgency)),
                  const Divider(),
                  _buildAnalysisItem(
                      'Category', widget.callData.category, AppColors.primary),
                ],
              ),
            ),
          ),
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
                                ? AppColors.primary.withOpacity(0.15)
                                : AppColors.accent.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              message.isUser ? 'Y' : 'C',
                              style: TextStyle(
                                color: message.isUser
                                    ? AppColors.primary
                                    : AppColors.accent,
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
                  activeColor: AppColors.success,
                ),
                title: Text(
                  action.title,
                  style: TextStyle(
                    decoration:
                        action.isCompleted ? TextDecoration.lineThrough : null,
                    color:
                        action.isCompleted ? AppColors.muted : AppColors.text,
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
        return AppColors.success;
      case 'negative':
        return AppColors.danger;
      default:
        return AppColors.accent;
    }
  }

  Color _getUrgencyColor(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'high':
        return AppColors.danger;
      case 'medium':
        return AppColors.accent;
      default:
        return AppColors.success;
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

  void _regenerateSummary() {
    // Implementation for regenerating summary
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

class TranscriptMessage {
  final String speaker;
  final String text;
  final String timestamp;
  final bool isUser;

  TranscriptMessage({
    required this.speaker,
    required this.text,
    required this.timestamp,
    required this.isUser,
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
