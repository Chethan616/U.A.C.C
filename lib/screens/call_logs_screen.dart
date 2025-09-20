import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/call_log_service.dart';

final callLogsProvider = FutureProvider<List<CallLog>>((ref) async {
  return CallLogService.getCallLogs();
});

class CallLogsScreen extends ConsumerStatefulWidget {
  const CallLogsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CallLogsScreen> createState() => _CallLogsScreenState();
}

class _CallLogsScreenState extends ConsumerState<CallLogsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncLogs = ref.watch(callLogsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text('Call Logs',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        iconTheme:
            IconThemeData(color: Theme.of(context).colorScheme.onSurface),
        actions: [
          IconButton(
              onPressed: _showSearchDialog, icon: const Icon(Icons.search)),
          IconButton(
              onPressed: _showOptionsMenu, icon: const Icon(Icons.more_vert)),
        ],
      ),
      body: asyncLogs.when(
        data: (logs) {
          final filtered = _filterCallLogs(logs);
          if (filtered.isEmpty) return _buildEmptyState();

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final log = filtered[index];
              return Card(
                color: Theme.of(context).colorScheme.surfaceContainer,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  leading: _buildAvatar(log),
                  title: Text(log.contactName ?? log.phoneNumber,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                      '${_formatTime(log.timestamp)} • ${_formatDuration(log.duration)}',
                      style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.7))),
                  trailing: IconButton(
                      icon: Icon(Icons.info_outline,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.7)),
                      onPressed: () => _showCallDetails(log)),
                  onTap: () => _makeCall(log.phoneNumber),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => _buildErrorState(err.toString()),
      ),
    );
  }

  Widget _buildAvatar(CallLog log) {
    final photoUrl = log.photoUrl;
    if (photoUrl != null &&
        (photoUrl.startsWith('http://') || photoUrl.startsWith('https://'))) {
      return CircleAvatar(backgroundImage: NetworkImage(photoUrl));
    }

    final base = (log.contactName ?? log.phoneNumber).trim();
    final initials = base.isEmpty
        ? '?'
        : base
            .split(' ')
            .where((s) => s.isNotEmpty)
            .map((s) => s[0])
            .take(2)
            .join();

    return CircleAvatar(
        backgroundColor: Colors.grey[700],
        child: Text(initials,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer)));
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 64),
          const SizedBox(height: 16),
          const Text('Error loading call logs',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(error,
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton(
              onPressed: () => ref.invalidate(callLogsProvider),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF)),
              child: const Text('Retry'))
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.call_outlined,
              color: Theme.of(context).colorScheme.outline, size: 80),
          const SizedBox(height: 24),
          Text('No call logs found',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Your call history will appear here',
              style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.7))),
        ],
      ),
    );
  }

  List<CallLog> _filterCallLogs(List<CallLog> logs) {
    if (_searchQuery.isEmpty) return logs;
    final q = _searchQuery.toLowerCase();
    return logs.where((log) {
      final name = (log.contactName ?? '').toLowerCase();
      final number = log.phoneNumber.toLowerCase();
      return name.contains(q) || number.contains(q);
    }).toList();
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final period = hour >= 12 ? 'PM' : 'AM';
    return '$displayHour:$minute $period';
  }

  String _formatDuration(int seconds) {
    if (seconds == 0) return 'Not answered';
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    if (minutes == 0) return '${secs}s';
    return '${minutes}m ${secs}s';
  }

  void _makeCall(String phoneNumber) async {
    try {
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Calling $phoneNumber...'),
          backgroundColor: const Color(0xFF6C63FF)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error making call: $e'), backgroundColor: Colors.red));
    }
  }

  void _showCallDetails(CallLog log) {
    showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) => CallDetailsBottomSheet(callLog: log));
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        title: Text('Search Call Logs',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        content: TextField(
            controller: _searchController,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: 'Enter name or number',
              hintStyle: TextStyle(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
              border: UnderlineInputBorder(
                  borderSide:
                      BorderSide(color: Theme.of(context).colorScheme.outline)),
              enabledBorder: UnderlineInputBorder(
                  borderSide:
                      BorderSide(color: Theme.of(context).colorScheme.outline)),
              focusedBorder: UnderlineInputBorder(
                  borderSide:
                      BorderSide(color: Theme.of(context).colorScheme.primary)),
            ),
            autofocus: true,
            onChanged: (value) => setState(() => _searchQuery = value)),
        actions: [
          TextButton(
              onPressed: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
                Navigator.pop(context);
              },
              child: const Text('Clear')),
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close')),
        ],
      ),
    );
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
              leading: Icon(Icons.refresh,
                  color: Theme.of(context).colorScheme.onSurface),
              title: Text('Refresh',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface)),
              onTap: () {
                Navigator.pop(context);
                ref.invalidate(callLogsProvider);
              }),
          ListTile(
              leading: Icon(Icons.delete_outline,
                  color: Theme.of(context).colorScheme.onSurface),
              title: Text('Clear History',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface)),
              onTap: () {
                Navigator.pop(context);
                _showClearHistoryDialog();
              }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showClearHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        title: Text('Clear History?',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        content: Text(
            'This will clear all call logs from your device. This action cannot be undone.',
            style: TextStyle(
                color:
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.8))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('History cleared'),
                    backgroundColor: Colors.green));
              },
              child: const Text('Clear', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}

class CallDetailsBottomSheet extends StatelessWidget {
  final CallLog callLog;

  const CallDetailsBottomSheet({Key? key, required this.callLog})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          Row(children: [
            CircleAvatar(
                radius: 30,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(Icons.person,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    size: 24)),
            const SizedBox(width: 16),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(callLog.contactName ?? callLog.phoneNumber,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  if (callLog.contactName != null)
                    Text(callLog.phoneNumber,
                        style: TextStyle(color: Colors.white.withOpacity(0.7))),
                ])),
          ]),
          const SizedBox(height: 24),
          _detailRow('Call Type', _getCallTypeText(callLog.type)),
          _detailRow('Date & Time', _formatDateTime(callLog.timestamp)),
          _detailRow('Duration', _formatDuration(callLog.duration)),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(
                child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.call),
                    label: const Text('Call'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF)))),
            const SizedBox(width: 12),
            Expanded(
                child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.message),
                    label: const Text('Message'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: const Color(0xFF6C63FF),
                        side: const BorderSide(color: Color(0xFF6C63FF))))),
          ]),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        SizedBox(
            width: 100,
            child: Text(label,
                style: TextStyle(color: Colors.white.withOpacity(0.7)))),
        Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w500)))
      ]),
    );
  }

  String _getCallTypeText(CallType type) {
    switch (type) {
      case CallType.incoming:
        return 'Incoming';
      case CallType.outgoing:
        return 'Outgoing';
      case CallType.missed:
        return 'Missed';
    }
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final callDate = DateTime(dt.year, dt.month, dt.day);

    String dateStr;
    if (callDate == today) {
      dateStr = 'Today';
    } else if (callDate == yesterday) {
      dateStr = 'Yesterday';
    } else {
      dateStr = '${dt.day}/${dt.month}/${dt.year}';
    }

    final hour = dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final period = hour >= 12 ? 'PM' : 'AM';
    return '$dateStr at $displayHour:$minute $period';
  }

  String _formatDuration(int seconds) {
    if (seconds == 0) return 'Not answered';
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    if (minutes == 0) return '${secs}s';
    if (minutes == 1) return '1 minute ${secs} seconds';
    return '$minutes minutes ${secs} seconds';
  }
}
