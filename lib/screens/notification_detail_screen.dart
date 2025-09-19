// lib/screens/notification_detail_screen.dart
import 'package:flutter/material.dart';
import '../models/enums.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/priority_badge.dart';

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
                        Expanded(
                          child: Text(
                            widget.notificationData.appName,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
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
              Text(
                _formatDateTime(widget.notificationData.timestamp),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Spacer(),
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
                ],
              ),
              const SizedBox(height: 12),
              Text(
                widget.notificationData.aiSummary,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),

              // Analysis Tags
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildAnalysisChip(
                      'Sentiment',
                      widget.notificationData.sentiment,
                      _getSentimentColor(widget.notificationData.sentiment)),
                  _buildAnalysisChip('Urgency', widget.notificationData.urgency,
                      _getUrgencyColor(widget.notificationData.urgency)),
                  if (widget.notificationData.requiresAction)
                    _buildAnalysisChip('Action Required', '',
                        Theme.of(context).colorScheme.error),
                  if (widget.notificationData.containsPersonalInfo)
                    _buildAnalysisChip('Personal Info', '',
                        Theme.of(context).colorScheme.secondary),
                ],
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
                  Text(
                    'Suggested Actions',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
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

              // Primary Action
              if (widget.notificationData.suggestedActions.isNotEmpty) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _executeAction(
                        widget.notificationData.suggestedActions.first),
                    icon: Icon(
                        widget.notificationData.suggestedActions.first.icon),
                    label: Text(
                        widget.notificationData.suggestedActions.first.title),
                  ),
                ),
                if (_isActionExpanded &&
                    widget.notificationData.suggestedActions.length > 1) ...[
                  const SizedBox(height: 12),
                  ...widget.notificationData.suggestedActions
                      .skip(1)
                      .map((action) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _executeAction(action),
                          icon: Icon(action.icon),
                          label: Text(action.title),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ],

              if (widget.notificationData.suggestedActions.isEmpty)
                Text(
                  'No specific actions recommended',
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
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _saveNote,
                      icon: const Icon(Icons.save, size: 16),
                      label: const Text('Save Note'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _createTask,
                    icon: const Icon(Icons.add_task, size: 16),
                    label: const Text('Create Task'),
                  ),
                ],
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!widget.notificationData.isRead)
          FloatingActionButton(
            heroTag: "mark_read",
            onPressed: _markAsRead,
            backgroundColor: Theme.of(context).colorScheme.tertiary,
            child: const Icon(Icons.mark_email_read),
          ),
        const SizedBox(height: 16),
        FloatingActionButton.extended(
          heroTag: "main_action",
          onPressed: _createTask,
          icon: const Icon(Icons.add_task),
          label: const Text('Create Task'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
        ),
      ],
    );
  }

  Color _getAppColor(String appName) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (appName.toLowerCase()) {
      case 'whatsapp':
        return Colors.green;
      case 'gmail':
      case 'email':
        return Colors.red;
      case 'instagram':
        return Colors.purple;
      case 'facebook':
        return Colors.blue;
      case 'gpay':
      case 'payment':
        return colorScheme.secondary;
      case 'bank':
      case 'sbi':
        return colorScheme.primary;
      default:
        return colorScheme.onSurfaceVariant;
    }
  }

  IconData _getAppIcon(String appName) {
    switch (appName.toLowerCase()) {
      case 'whatsapp':
        return Icons.message;
      case 'gmail':
      case 'email':
        return Icons.email;
      case 'instagram':
        return Icons.camera_alt;
      case 'facebook':
        return Icons.facebook;
      case 'gpay':
      case 'payment':
        return Icons.payment;
      case 'bank':
      case 'sbi':
        return Icons.account_balance;
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

  void _executeAction(SuggestedAction action) {
    // Implementation for executing suggested actions
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Executing: ${action.title}'),
        backgroundColor: Theme.of(context).colorScheme.tertiary,
      ),
    );
  }

  void _openRelatedNotification(RelatedNotification notification) {
    // Implementation for opening related notification
  }

  void _saveNote() {
    if (_noteController.text.isNotEmpty) {
      // Implementation for saving notes
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Note saved'),
          backgroundColor: Theme.of(context).colorScheme.tertiary,
        ),
      );
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
