import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/google_auth_service.dart';
import '../services/tasks_service.dart';
import '../models/floating_pill_data.dart';
import '../services/calendar_service.dart';

class GoogleWorkspaceTestPage extends StatefulWidget {
  const GoogleWorkspaceTestPage({Key? key}) : super(key: key);

  @override
  State<GoogleWorkspaceTestPage> createState() =>
      _GoogleWorkspaceTestPageState();
}

class _GoogleWorkspaceTestPageState extends State<GoogleWorkspaceTestPage> {
  final GoogleAuthService _authService = GoogleAuthService();
  final TasksService _tasksService = TasksService();

  bool _isLoading = false;
  bool _isSignedIn = false;
  String _statusMessage = 'Ready to test Google Workspace integration';
  FloatingPillData? _pillData;

  static const MethodChannel _channel =
      MethodChannel('com.example.uacc/google_workspace');

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Initializing services...';
    });

    try {
      _authService.initialize();
      await _tasksService.initialize();

      setState(() {
        _isSignedIn = _authService.isSignedIn;
        _statusMessage = _isSignedIn
            ? 'Signed in as ${_authService.userEmail}'
            : 'Services initialized - ready to sign in';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error initializing: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Signing in to Google...';
    });

    try {
      final success = await _authService.signIn();
      if (success) {
        await _tasksService.initialize();

        setState(() {
          _isSignedIn = true;
          _statusMessage =
              'Successfully signed in as ${_authService.userEmail}';
        });

        // Fetch initial data
        await _fetchGoogleData();
      } else {
        setState(() {
          _statusMessage = 'Sign in failed or cancelled';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Sign in error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signOut() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Signing out...';
    });

    try {
      await _authService.signOut();
      setState(() {
        _isSignedIn = false;
        _pillData = null;
        _statusMessage = 'Successfully signed out';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Sign out error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchGoogleData() async {
    if (!_isSignedIn) return;

    setState(() {
      _isLoading = true;
      _statusMessage = 'Fetching Google Calendar and Tasks data...';
    });

    try {
      // Fetch calendar events
      final todayEvents = await CalendarService.getTodayEvents();
      final upcomingEvents = await CalendarService.getUpcomingEvents();

      // Fetch tasks
      final dueTodayTasks = await _tasksService.getDueTodayTasks();
      final overdueTasks = await _tasksService.getOverdueTasks();

      // Filter current meetings
      final now = DateTime.now();
      final currentMeetings = todayEvents.where((event) {
        return now.isAfter(event.startTime) && now.isBefore(event.endTime);
      }).toList();

      // Create floating pill data
      final userInfo = UserInfo(
        name: _authService.userName,
        email: _authService.userEmail,
        photoUrl: _authService.userPhotoUrl,
        isSignedIn: true,
      );

      final pillData = FloatingPillData(
        userInfo: userInfo,
        currentMeetings: currentMeetings,
        upcomingEvents: upcomingEvents.take(3).toList(),
        dueTodayTasks: dueTodayTasks,
        overdueTasks: overdueTasks,
        lastUpdated: DateTime.now(),
      );

      setState(() {
        _pillData = pillData;
        _statusMessage =
            'Data fetched successfully! Found ${currentMeetings.length} current meetings, ${upcomingEvents.length} upcoming events, ${dueTodayTasks.length} due today tasks, ${overdueTasks.length} overdue tasks';
      });

      // Send to Android service
      await _sendToAndroid(pillData);
    } catch (e) {
      setState(() {
        _statusMessage = 'Error fetching data: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendToAndroid(FloatingPillData data) async {
    try {
      await _channel.invokeMethod('updateFloatingPillData', data.toJson());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data sent to floating pill!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending to Android: $e')),
      );
    }
  }

  Future<void> _startTranscript() async {
    try {
      await MethodChannel('com.example.uacc/live_transcript')
          .invokeMethod('startLiveTranscript');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Floating pill started!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting transcript: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Workspace Test'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isSignedIn
                              ? Icons.check_circle
                              : Icons.account_circle,
                          color: _isSignedIn ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isSignedIn ? 'Signed In' : 'Not Signed In',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                color: _isSignedIn ? Colors.green : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(_statusMessage),
                    if (_isLoading) ...[
                      const SizedBox(height: 16),
                      const LinearProgressIndicator(),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Action Buttons
            if (!_isSignedIn) ...[
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _signIn,
                icon: const Icon(Icons.login),
                label: const Text('Sign in to Google'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _fetchGoogleData,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Fetch Data'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _signOut,
                      icon: const Icon(Icons.logout),
                      label: const Text('Sign Out'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _startTranscript,
                icon: const Icon(Icons.picture_in_picture),
                label: const Text('Start Floating Pill'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Data Preview
            if (_pillData != null) ...[
              Text(
                'Preview Data:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDataSection('Current Meetings',
                              _pillData!.currentMeetings, Colors.red),
                          _buildDataSection('Upcoming Events',
                              _pillData!.upcomingEvents, Colors.blue),
                          _buildDataSection(
                              'Due Today Tasks',
                              _pillData!.dueTodayTasks
                                  .map((t) => {
                                        'title': t.title,
                                        'subtitle': t.dueDateString
                                      })
                                  .toList(),
                              Colors.orange),
                          _buildDataSection(
                              'Overdue Tasks',
                              _pillData!.overdueTasks
                                  .map((t) => {
                                        'title': t.title,
                                        'subtitle': t.dueDateString
                                      })
                                  .toList(),
                              Colors.red.shade800),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDataSection(String title, List<dynamic> items, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$title (${items.length})',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        if (items.isEmpty) ...[
          const Text('No items', style: TextStyle(color: Colors.grey)),
        ] else ...[
          for (final item in items.take(3))
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 4),
              child: Text(
                '• ${item is Map ? item['title'] ?? 'Unknown' : item.toString()}',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          if (items.length > 3)
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text(
                '... and ${items.length - 3} more',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
        ],
        const SizedBox(height: 12),
      ],
    );
  }
}
