import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/automation_coordinator.dart';
import '../models/automation_models.dart';

class AutomationDashboardScreen extends ConsumerStatefulWidget {
  const AutomationDashboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AutomationDashboardScreen> createState() =>
      _AutomationDashboardScreenState();
}

class _AutomationDashboardScreenState
    extends ConsumerState<AutomationDashboardScreen> {
  final AutomationCoordinator _coordinator = AutomationCoordinator();
  bool _isRecording = false;
  bool _isInitialized = false;
  AutomationSettings? _settings;
  DailySchedule? _todaysSchedule;

  @override
  void initState() {
    super.initState();
    _initializeAutomation();
  }

  Future<void> _initializeAutomation() async {
    final initialized = await _coordinator.initializeAllServices();
    final settings = await _coordinator.getAutomationSettings();
    final schedule = await _coordinator.getTodaysScheduleWithInsights();

    setState(() {
      _isInitialized = initialized;
      _settings = settings;
      _todaysSchedule = schedule;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Automation Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettingsDialog,
          ),
        ],
      ),
      body: !_isInitialized
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusCard(),
                  const SizedBox(height: 16),
                  _buildCallRecordingCard(),
                  const SizedBox(height: 16),
                  _buildSmartSchedulingCard(),
                  const SizedBox(height: 16),
                  _buildNotificationCard(),
                  const SizedBox(height: 16),
                  _buildTodaysScheduleCard(),
                  const SizedBox(height: 16),
                  _buildAutomationStatsCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Automation Status',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatusRow(
                'Call Recording', _settings?.enableCallRecording ?? false),
            _buildStatusRow(
                'Smart Replies', _settings?.enableSmartReplies ?? false),
            _buildStatusRow(
                'Smart Scheduling', _settings?.enableSmartScheduling ?? false),
            _buildStatusRow('Notification Summary',
                _settings?.enableNotificationSummary ?? false),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String feature, bool enabled) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(feature),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: enabled ? Colors.green.shade100 : Colors.red.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              enabled ? 'Active' : 'Inactive',
              style: TextStyle(
                color: enabled ? Colors.green.shade800 : Colors.red.shade800,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallRecordingCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.mic,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Call Recording & Analysis',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Record calls and get AI-powered insights, action items, and automatic scheduling.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isRecording ? _stopRecording : _startRecording,
                    icon: Icon(_isRecording ? Icons.stop : Icons.play_arrow),
                    label: Text(
                        _isRecording ? 'Stop Recording' : 'Start Recording'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isRecording
                          ? Colors.red
                          : Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _showCallHistory,
                  icon: const Icon(Icons.history),
                  tooltip: 'Call History',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmartSchedulingCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Smart Scheduling',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'AI-powered meeting scheduling with conflict detection and optimal time finding.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _scheduleSmartMeeting,
              icon: const Icon(Icons.add_circle),
              label: const Text('Schedule Smart Meeting'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.notifications_active,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Smart Notifications',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'AI analyzes notifications, generates smart replies, and creates tasks automatically.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _generateDailySummary,
                    icon: const Icon(Icons.summarize),
                    label: const Text('Daily Summary'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _showNotificationHistory,
                  icon: const Icon(Icons.inbox),
                  tooltip: 'Notification History',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaysScheduleCard() {
    if (_todaysSchedule == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.today,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Today\'s Schedule',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildScheduleItem(
                      'Events', _todaysSchedule!.totalEvents),
                ),
                Expanded(
                  child:
                      _buildScheduleItem('Tasks', _todaysSchedule!.totalTasks),
                ),
              ],
            ),
            if (_todaysSchedule!.aiInsights.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'AI Insights',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ..._todaysSchedule!.aiInsights.take(3).map(
                    (insight) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Icon(Icons.lightbulb, size: 16, color: Colors.amber),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(insight,
                                  style:
                                      Theme.of(context).textTheme.bodySmall)),
                        ],
                      ),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleItem(String label, int count) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildAutomationStatsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Automation Statistics',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Mock statistics - in real app, this would come from analytics
            _buildStatRow('Calls Analyzed', '12', 'This week'),
            _buildStatRow('Tasks Auto-Created', '28', 'This month'),
            _buildStatRow('Meetings Scheduled', '6', 'This week'),
            _buildStatRow('Time Saved', '4.5 hrs', 'This month'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, String period) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodyMedium),
              Text(period,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey)),
            ],
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  // Action methods
  Future<void> _startRecording() async {
    final success = await _coordinator.startCallRecording();
    if (success) {
      setState(() => _isRecording = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Call recording started')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to start recording')),
      );
    }
  }

  Future<void> _stopRecording() async {
    final result = await _coordinator.processCallRecording();
    setState(() => _isRecording = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Call analyzed: ${result.message}')),
      );
      _refreshSchedule();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Analysis failed: ${result.message}')),
      );
    }
  }

  Future<void> _scheduleSmartMeeting() async {
    // Show dialog to collect meeting details
    showDialog(
      context: context,
      builder: (context) => _SmartMeetingDialog(coordinator: _coordinator),
    ).then((_) => _refreshSchedule());
  }

  Future<void> _generateDailySummary() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generating daily notification summary...')),
    );
    // This would trigger the notification service to generate daily summary
  }

  Future<void> _refreshSchedule() async {
    final schedule = await _coordinator.getTodaysScheduleWithInsights();
    setState(() => _todaysSchedule = schedule);
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => _AutomationSettingsDialog(
        settings: _settings!,
        onSave: (newSettings) async {
          await _coordinator.updateAutomationSettings(newSettings);
          setState(() => _settings = newSettings);
        },
      ),
    );
  }

  void _showCallHistory() {
    // Navigate to call history screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening call history...')),
    );
  }

  void _showNotificationHistory() {
    // Navigate to notification history screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening notification history...')),
    );
  }
}

// Smart Meeting Dialog
class _SmartMeetingDialog extends StatefulWidget {
  final AutomationCoordinator coordinator;

  const _SmartMeetingDialog({required this.coordinator});

  @override
  State<_SmartMeetingDialog> createState() => _SmartMeetingDialogState();
}

class _SmartMeetingDialogState extends State<_SmartMeetingDialog> {
  final _titleController = TextEditingController();
  final _emailsController = TextEditingController();
  Duration _duration = const Duration(hours: 1);
  DateTime? _preferredDate;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Schedule Smart Meeting'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Meeting Title'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _emailsController,
            decoration: const InputDecoration(
              labelText: 'Participant Emails (comma-separated)',
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<Duration>(
            value: _duration,
            decoration: const InputDecoration(labelText: 'Duration'),
            items: const [
              DropdownMenuItem(
                  value: Duration(minutes: 30), child: Text('30 minutes')),
              DropdownMenuItem(
                  value: Duration(hours: 1), child: Text('1 hour')),
              DropdownMenuItem(
                  value: Duration(hours: 2), child: Text('2 hours')),
            ],
            onChanged: (value) => setState(() => _duration = value!),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _scheduleMeeting,
          child: const Text('Schedule'),
        ),
      ],
    );
  }

  Future<void> _scheduleMeeting() async {
    if (_titleController.text.isEmpty) return;

    final emails = _emailsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final result = await widget.coordinator.scheduleSmartMeeting(
      title: _titleController.text,
      participantEmails: emails,
      duration: _duration,
      preferredDateTime: _preferredDate,
    );

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
    }
  }
}

// Automation Settings Dialog
class _AutomationSettingsDialog extends StatefulWidget {
  final AutomationSettings settings;
  final Function(AutomationSettings) onSave;

  const _AutomationSettingsDialog({
    required this.settings,
    required this.onSave,
  });

  @override
  State<_AutomationSettingsDialog> createState() =>
      _AutomationSettingsDialogState();
}

class _AutomationSettingsDialogState extends State<_AutomationSettingsDialog> {
  late AutomationSettings _currentSettings;

  @override
  void initState() {
    super.initState();
    _currentSettings = AutomationSettings(
      enableCallRecording: widget.settings.enableCallRecording,
      enableSmartReplies: widget.settings.enableSmartReplies,
      enableSmartScheduling: widget.settings.enableSmartScheduling,
      enableNotificationSummary: widget.settings.enableNotificationSummary,
      enableAutoTaskCreation: widget.settings.enableAutoTaskCreation,
      replyTone: widget.settings.replyTone,
      priorityApps: List.from(widget.settings.priorityApps),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Automation Settings'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Call Recording'),
              value: _currentSettings.enableCallRecording,
              onChanged: (value) =>
                  setState(() => _currentSettings = AutomationSettings(
                        enableCallRecording: value,
                        enableSmartReplies: _currentSettings.enableSmartReplies,
                        enableSmartScheduling:
                            _currentSettings.enableSmartScheduling,
                        enableNotificationSummary:
                            _currentSettings.enableNotificationSummary,
                        enableAutoTaskCreation:
                            _currentSettings.enableAutoTaskCreation,
                        replyTone: _currentSettings.replyTone,
                        priorityApps: _currentSettings.priorityApps,
                      )),
            ),
            SwitchListTile(
              title: const Text('Smart Replies'),
              value: _currentSettings.enableSmartReplies,
              onChanged: (value) =>
                  setState(() => _currentSettings = AutomationSettings(
                        enableCallRecording:
                            _currentSettings.enableCallRecording,
                        enableSmartReplies: value,
                        enableSmartScheduling:
                            _currentSettings.enableSmartScheduling,
                        enableNotificationSummary:
                            _currentSettings.enableNotificationSummary,
                        enableAutoTaskCreation:
                            _currentSettings.enableAutoTaskCreation,
                        replyTone: _currentSettings.replyTone,
                        priorityApps: _currentSettings.priorityApps,
                      )),
            ),
            SwitchListTile(
              title: const Text('Smart Scheduling'),
              value: _currentSettings.enableSmartScheduling,
              onChanged: (value) =>
                  setState(() => _currentSettings = AutomationSettings(
                        enableCallRecording:
                            _currentSettings.enableCallRecording,
                        enableSmartReplies: _currentSettings.enableSmartReplies,
                        enableSmartScheduling: value,
                        enableNotificationSummary:
                            _currentSettings.enableNotificationSummary,
                        enableAutoTaskCreation:
                            _currentSettings.enableAutoTaskCreation,
                        replyTone: _currentSettings.replyTone,
                        priorityApps: _currentSettings.priorityApps,
                      )),
            ),
            SwitchListTile(
              title: const Text('Notification Summary'),
              value: _currentSettings.enableNotificationSummary,
              onChanged: (value) =>
                  setState(() => _currentSettings = AutomationSettings(
                        enableCallRecording:
                            _currentSettings.enableCallRecording,
                        enableSmartReplies: _currentSettings.enableSmartReplies,
                        enableSmartScheduling:
                            _currentSettings.enableSmartScheduling,
                        enableNotificationSummary: value,
                        enableAutoTaskCreation:
                            _currentSettings.enableAutoTaskCreation,
                        replyTone: _currentSettings.replyTone,
                        priorityApps: _currentSettings.priorityApps,
                      )),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSave(_currentSettings);
            Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
