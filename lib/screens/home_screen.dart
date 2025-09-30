import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lottie/lottie.dart';
import '../models/enums.dart';
import '../services/user_service.dart';
import '../services/call_log_service.dart' as call_service;
import '../services/notification_service.dart';
import '../services/task_service.dart' hide Task, TaskPriority;
import '../services/tasks_service.dart' as google_tasks;

import '../models/task.dart';
import '../services/call_monitoring_service.dart';
import '../widgets/summary_card.dart';
import '../widgets/calendar_widget.dart';
import '../widgets/upcoming_events_carousel.dart';
import '../firebaseExports/firebase_export_coordinator.dart';

import 'profile_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<_TasksTabState> _tasksTabKey = GlobalKey<_TasksTabState>();
  late final AnimationController _fabController;
  late final List<_NavigationItem> _navItems;
  late final List<Widget> _screens;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    print(
        '🟢 HOME SCREEN: initState method called - starting initialization...');
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();

    print(
        '🟢 HOME SCREEN: Firebase export system will only initialize when user manually triggers backup');

    _navItems = [
      _NavigationItem(
        icon: Icon(Icons.dashboard_outlined),
        activeIcon: Icon(Icons.dashboard),
        label: 'Home',
      ),
      _NavigationItem(
        icon: Icon(Icons.call_outlined),
        activeIcon: Icon(Icons.call),
        label: 'Calls',
      ),
      _NavigationItem(
        icon: Icon(Icons.task_alt_outlined),
        activeIcon: Icon(Icons.task_alt),
        label: 'Tasks',
      ),
      _NavigationItem(
        icon: Icon(Icons.notifications_outlined),
        activeIcon: Icon(Icons.notifications),
        label: 'Alerts',
      ),
      _NavigationItem(
        icon: Icon(Icons.person_outline),
        activeIcon: Icon(Icons.person),
        label: 'Profile',
      ),
    ];

    _screens = [
      const DashboardTab(),
      const CallsTab(),
      TasksTab(key: _tasksTabKey),
      const NotificationsTab(),
      const ProfileTab(),
    ];
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      floatingActionButton: _selectedIndex == 0
          ? ScaleTransition(
              scale: Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(
                  parent: _fabController,
                  curve: Curves.elasticOut,
                ),
              ),
              child: FloatingActionButton.extended(
                onPressed: _showQuickActions,
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                icon: const Icon(Icons.add),
                label: const Text('Quick Add'),
                heroTag: 'dashboard_fab',
              ),
            )
          : null,
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          indicatorColor:
              Theme.of(context).colorScheme.primary.withOpacity(0.12),
          backgroundColor: Theme.of(context).colorScheme.surface,
          labelTextStyle: MaterialStateProperty.all(
            Theme.of(context).textTheme.labelSmall,
          ),
        ),
        child: PhysicalShape(
          color: Theme.of(context).colorScheme.surface,
          elevation: 8,
          clipper: ShapeBorderClipper(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
          ),
          child: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              if (index != _selectedIndex) {
                setState(() {
                  _selectedIndex = index;
                });

                if (index == 0) {
                  _fabController.forward();
                } else {
                  _fabController.reverse();
                }
              }
            },
            destinations: _navItems
                .map(
                  (entry) => NavigationDestination(
                    icon: entry.icon,
                    selectedIcon: entry.activeIcon,
                    label: entry.label,
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }

  void _showQuickActions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: _buildQuickAction(
                    label: 'Add Call',
                    icon: Icons.phone_outlined,
                    color: Theme.of(context).colorScheme.primary,
                    onTap: () => Navigator.pop(context),
                  ),
                ),
                Expanded(
                  child: _buildQuickAction(
                    label: 'Add Task',
                    icon: Icons.task_alt_outlined,
                    color: Theme.of(context).colorScheme.secondary,
                    onTap: () {
                      Navigator.pop(context);
                      // Use a more robust approach to show task dialog
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _showTaskDialog(context);
                      });
                    },
                  ),
                ),
                Expanded(
                  child: _buildQuickAction(
                    label: 'Add Note',
                    icon: Icons.note_add_outlined,
                    color: Theme.of(context).colorScheme.tertiary,
                    onTap: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: _buildQuickAction(
                    label: 'Test Call',
                    icon: Icons.live_help_outlined,
                    color: Theme.of(context).colorScheme.error,
                    onTap: () {
                      Navigator.pop(context);
                      CallMonitoringService.simulateIncomingCall(
                        callerName: 'Test Contact',
                        phoneNumber: '+91 98765 43210',
                      );
                    },
                  ),
                ),
                Expanded(
                  child: _buildQuickAction(
                    label: 'View Calendar',
                    icon: Icons.calendar_today_outlined,
                    color: Theme.of(context).colorScheme.inversePrimary,
                    onTap: () => Navigator.pop(context),
                  ),
                ),
                Expanded(
                  child: _buildQuickAction(
                    label: 'Settings',
                    icon: Icons.settings_outlined,
                    color: Theme.of(context).colorScheme.outline,
                    onTap: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showTaskDialog(BuildContext context) {
    // Navigate to Tasks tab and show dialog
    setState(() {
      _selectedIndex = 1; // Navigate to Tasks tab (assuming index 1)
    });

    // Wait for navigation to complete, then show dialog
    Future.delayed(const Duration(milliseconds: 300), () {
      final state = _tasksTabKey.currentState;
      if (state != null) {
        state.showTaskDialog();
      }
    });
  }

  /// Initialize Firebase Export System
  // Removed _initializeFirebaseExportSystem - now only backup when user clicks cloud icon
}

class _NavigationItem {
  final Icon icon;
  final Icon activeIcon;
  final String label;

  const _NavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class DashboardTab extends ConsumerStatefulWidget {
  const DashboardTab({Key? key}) : super(key: key);

  @override
  ConsumerState<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends ConsumerState<DashboardTab>
    with TickerProviderStateMixin {
  late AnimationController _dashboardController;
  late AnimationController _cardController;

  // Real data state
  Map<String, int> _callStats = {'todayCalls': 0};
  Map<String, int> _notificationStats = {'todayNotifications': 0};
  Map<String, int> _taskStats = {'pendingTasks': 0};
  List<AppNotification> _recentNotifications = [];
  List<call_service.CallLog> _recentCalls = [];
  bool _isLoading = true;

  final List<SummaryItem> _recentSummaries = [];

  @override
  void initState() {
    super.initState();
    _dashboardController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _dashboardController.forward();
    _cardController.forward();
    _loadRealData();
  }

  @override
  void dispose() {
    _dashboardController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  Future<void> _loadRealData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Load data from all services in parallel
      final futures = await Future.wait([
        call_service.CallLogService.getCallStats(),
        NotificationService.getNotificationStats(),
        _getGoogleTaskStats(), // Use Google Tasks stats instead of method channel
        NotificationService.getNotifications(limit: 5),
        call_service.CallLogService.getCallLogs(limit: 5),
      ]);

      _callStats = futures[0] as Map<String, int>;
      _notificationStats = futures[1] as Map<String, int>;
      _taskStats = futures[2] as Map<String, int>;
      _recentNotifications = futures[3] as List<AppNotification>;
      _recentCalls = futures[4] as List<call_service.CallLog>;

      // Generate recent summaries from real data
      _generateRecentSummaries();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading dashboard data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _generateRecentSummaries() {
    _recentSummaries.clear();

    // Add call summaries
    for (final call in _recentCalls.take(2)) {
      _recentSummaries.add(SummaryItem(
        title: '${call.type.name.toUpperCase()} - ${call.displayName}',
        summary:
            'Duration: ${_formatDuration(call.duration)} • ${call.type == call_service.CallType.missed ? 'Missed call' : 'Call completed'}',
        subtitle: _formatTimeAgo(call.timestamp),
        type: SummaryType.call,
        priority: call.type == call_service.CallType.missed
            ? PriorityLevel.high
            : PriorityLevel.medium,
      ));
    }

    // Add notification summaries
    for (final notification in _recentNotifications.take(3)) {
      _recentSummaries.add(SummaryItem(
        title: '${notification.appName} - ${notification.title}',
        summary: notification.displayContent,
        subtitle: _formatTimeAgo(notification.timestamp),
        type: SummaryType.notification,
        priority: notification.priority == NotificationPriority.high
            ? PriorityLevel.high
            : notification.priority == NotificationPriority.urgent
                ? PriorityLevel.urgent
                : PriorityLevel.medium,
      ));
    }

    // Sort by timestamp (most recent first)
    _recentSummaries.sort((a, b) {
      final aTime = _parseTimeAgo(a.subtitle);
      final bTime = _parseTimeAgo(b.subtitle);
      return bTime.compareTo(aTime);
    });
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (minutes > 0) {
      return '${minutes}m ${remainingSeconds}s';
    }
    return '${seconds}s';
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  DateTime _parseTimeAgo(String timeAgo) {
    final now = DateTime.now();
    if (timeAgo.contains('day')) {
      final days = int.tryParse(timeAgo.split(' ')[0]) ?? 0;
      return now.subtract(Duration(days: days));
    } else if (timeAgo.contains('hour')) {
      final hours = int.tryParse(timeAgo.split(' ')[0]) ?? 0;
      return now.subtract(Duration(hours: hours));
    } else if (timeAgo.contains('minute')) {
      final minutes = int.tryParse(timeAgo.split(' ')[0]) ?? 0;
      return now.subtract(Duration(minutes: minutes));
    }
    return now;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshData,
      color: Theme.of(context).colorScheme.primary,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Theme.of(context).colorScheme.surface,
            foregroundColor: Theme.of(context).colorScheme.onSurface,
            elevation: 0,
            floating: true,
            snap: true,
            expandedHeight: 140,
            flexibleSpace: FlexibleSpaceBar(
              title: FadeTransition(
                opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(
                    parent: _dashboardController,
                    curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
                  ),
                ),
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.5),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: _dashboardController,
                      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      // Allow the title texts to shrink when the app bar
                      // is collapsed to avoid RenderFlex overflow.
                      Flexible(
                        child: Consumer(
                          builder: (context, ref, child) {
                            final userProfile =
                                ref.watch(currentUserProfileProvider);
                            return userProfile.when(
                              data: (user) {
                                final firstName = user?.firstName ?? 'User';
                                return Text(
                                  'Good ${_getGreeting()}, $firstName',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                      ),
                                );
                              },
                              loading: () => Text(
                                'Good ${_getGreeting()}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                    ),
                              ),
                              error: (_, __) => Text(
                                'Good ${_getGreeting()}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                    ),
                              ),
                            );
                          },
                        ),
                      ),
                      Flexible(
                        child: Text(
                          'Here\'s your daily summary',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontSize: 14,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              titlePadding:
                  const EdgeInsets.only(left: 16, bottom: 16, top: 32),
            ),
            actions: [
              // Firebase Export Test Button (Debug/Testing)
              IconButton(
                onPressed: _testFirebaseExport,
                icon: const Icon(Icons.cloud_upload),
                tooltip: 'Test Firebase Export',
              ),
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: _dashboardController,
                    curve: const Interval(0.4, 0.9, curve: Curves.easeOut),
                  ),
                ),
                child: IconButton(
                  onPressed: _showNotifications,
                  icon: Stack(
                    children: [
                      const Icon(Icons.notifications_outlined),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.0, end: 1.0).animate(
                            CurvedAnimation(
                              parent: _dashboardController,
                              curve: const Interval(0.7, 1.0,
                                  curve: Curves.elasticOut),
                            ),
                          ),
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.error,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Add a bit more space between the app bar header and the
                // stats/icon box below to improve visual separation.
                const SizedBox(height: 16),
                // Stats Container with staggered animation
                SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 1.0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: _cardController,
                      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
                    ),
                  ),
                  child: FadeTransition(
                    opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                      CurvedAnimation(
                        parent: _cardController,
                        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Card(
                        elevation: 4,
                        // use theme shadow for correct light/dark behavior
                        shadowColor:
                            Theme.of(context).shadowColor.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            // match the calendar outline exactly (no extra opacity)
                            color: Theme.of(context).colorScheme.outline,
                            width: 1.0,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildStatItem(
                                    'Calls Today',
                                    _callStats['todayCalls']?.toString() ?? '0',
                                    'phone',
                                    Theme.of(context).colorScheme.primary,
                                    0),
                              ),
                              Container(
                                width: 1,
                                height: 60,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                              Expanded(
                                child: _buildStatItem(
                                    'Notifications',
                                    _notificationStats['todayNotifications']
                                            ?.toString() ??
                                        '0',
                                    'notifications',
                                    Theme.of(context).colorScheme.primary,
                                    1),
                              ),
                              Container(
                                width: 1,
                                height: 60,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                              Expanded(
                                child: _buildStatItem(
                                    'Tasks',
                                    _taskStats['pendingTasks']?.toString() ??
                                        '0',
                                    'tasks',
                                    Theme.of(context).colorScheme.primary,
                                    2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Calendar Widget with animation
                SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(-1.0, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: _cardController,
                      curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
                    ),
                  ),
                  child: FadeTransition(
                    opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                      CurvedAnimation(
                        parent: _cardController,
                        curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
                      ),
                    ),
                    child: const CalendarWidget(),
                  ),
                ),

                const SizedBox(height: 16),

                // Upcoming Events Carousel with animation
                SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1.0, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: _cardController,
                      curve: const Interval(0.4, 0.8, curve: Curves.easeOut),
                    ),
                  ),
                  child: FadeTransition(
                    opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                      CurvedAnimation(
                        parent: _cardController,
                        curve: const Interval(0.4, 0.8, curve: Curves.easeOut),
                      ),
                    ),
                    child: const UpcomingEventsCarousel(),
                  ),
                ),

                const SizedBox(height: 8),

                // Recent Summaries Header with animation
                SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.5),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: _cardController,
                      curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
                    ),
                  ),
                  child: FadeTransition(
                    opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                      CurvedAnimation(
                        parent: _cardController,
                        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Summaries',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          TextButton.icon(
                            onPressed: _viewAllSummaries,
                            icon: const Icon(Icons.arrow_forward_ios, size: 16),
                            label: const Text('View All'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),

          // Recent Summaries List with staggered animation
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = _recentSummaries[index];
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 1.0),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: _cardController,
                        curve: Interval(
                          0.7 + (index * 0.1).clamp(0.0, 0.9),
                          1.0,
                          curve: Curves.easeOut,
                        ),
                      ),
                    ),
                    child: FadeTransition(
                      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                        CurvedAnimation(
                          parent: _cardController,
                          curve: Interval(
                            0.7 + (index * 0.1).clamp(0.0, 0.9),
                            1.0,
                            curve: Curves.easeOut,
                          ),
                        ),
                      ),
                      child: SummaryCard(
                        title: item.title,
                        summary: item.summary,
                        subtitle: item.subtitle,
                        leadingIcon: item.type == SummaryType.call
                            ? Icons.phone
                            : Icons.notifications,
                        accentColor: _getPriorityColor(item.priority),
                        onTap: () => _openSummaryDetail(item),
                      ),
                    ),
                  );
                },
                childCount: _recentSummaries.length,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, String iconType,
      Color color, int animationIndex) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _cardController,
          curve: Interval(
            0.1 + (animationIndex * 0.1).clamp(0.0, 0.8),
            0.4 + (animationIndex * 0.1).clamp(0.0, 0.8),
            curve: Curves.elasticOut,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 800 + (animationIndex * 200)),
            curve: Curves.easeInOutCubic,
            builder: (context, animationValue, child) {
              return Transform.rotate(
                angle: animationValue * 2 * 3.14159,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: color.withOpacity(0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: () {
                      switch (iconType) {
                        case 'phone':
                          return Icon(Icons.phone, size: 24.0, color: color);
                        case 'notifications':
                          return Icon(Icons.notifications,
                              size: 24.0, color: color);
                        case 'tasks':
                          return Icon(Icons.task_alt, size: 24.0, color: color);
                        default:
                          return Icon(Icons.dashboard,
                              size: 24.0, color: color);
                      }
                    }(),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: int.parse(value)),
            duration: Duration(milliseconds: 1200 + (animationIndex * 200)),
            curve: Curves.easeOutCubic,
            builder: (context, animatedValue, child) {
              return Text(
                animatedValue.toString(),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 20,
                    ),
              );
            },
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }

  Color _getPriorityColor(PriorityLevel priority) {
    switch (priority) {
      case PriorityLevel.urgent:
        return Theme.of(context).colorScheme.error;
      case PriorityLevel.high:
        return Theme.of(context).colorScheme.error;
      case PriorityLevel.medium:
        return Theme.of(context).colorScheme.secondary;
      case PriorityLevel.low:
        return Theme.of(context).colorScheme.tertiary;
    }
  }

  Future<void> _refreshData() async {
    await _loadRealData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Dashboard refreshed'),
          backgroundColor: Theme.of(context).colorScheme.tertiary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showNotifications() {
    Navigator.pushNamed(context, '/notifications');
  }

  void _viewAllSummaries() {
    if (_recentSummaries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No summaries available yet'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.secondary,
        ),
      );
      return;
    }

    Navigator.pushNamed(
      context,
      '/all-summaries',
      arguments: List<SummaryItem>.from(_recentSummaries),
    );
  }

  void _openSummaryDetail(SummaryItem item) {
    if (item.type == SummaryType.call) {
      Navigator.pushNamed(context, '/call-detail', arguments: item);
    } else {
      // All notifications (including payment/banking apps) go to notification detail screen
      Navigator.pushNamed(context, '/notification-detail', arguments: item);
    }
  }

  /// Manual Firebase Backup
  void _testFirebaseExport() async {
    print('🧪 Starting manual backup...');
    try {
      print('🔄 Backing up user data to Firebase...');
      // Initialize if needed, then export data
      if (!FirebaseExportCoordinator.isInitialized) {
        await FirebaseExportCoordinator.initialize();
      }
      await FirebaseExportCoordinator.exportAllData();
      print('✅ Manual backup completed successfully!');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Backup complete')),
        );
      }
    } catch (e) {
      print('❌ Manual backup failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Backup failed: $e')),
        );
      }
    }
  }

  /// Get Google Tasks statistics for dashboard
  Future<Map<String, int>> _getGoogleTaskStats() async {
    try {
      // Initialize Google Tasks service
      final tasksService = google_tasks.TasksService();
      await tasksService.initialize();

      // Get Google tasks
      final googleTaskItems = await tasksService.getAllTasks();

      if (googleTaskItems.isNotEmpty) {
        final now = DateTime.now();

        // Calculate stats directly from TaskItem objects
        int totalTasks = googleTaskItems.length;
        int completedTasks =
            googleTaskItems.where((task) => task.isCompleted).length;
        int pendingTasks =
            googleTaskItems.where((task) => !task.isCompleted).length;
        int overdueTasks = 0;
        int todayTasks = 0;

        // Count overdue and today's tasks
        for (final task in googleTaskItems) {
          if (task.dueDate != null) {
            final dueDate = task.dueDate!;
            if (!task.isCompleted && dueDate.isBefore(now)) {
              overdueTasks++;
            }
            if (dueDate.year == now.year &&
                dueDate.month == now.month &&
                dueDate.day == now.day) {
              todayTasks++;
            }
          }
        }

        final stats = {
          'totalTasks': totalTasks,
          'completedTasks': completedTasks,
          'pendingTasks': pendingTasks,
          'overdueTasks': overdueTasks,
          'todayTasks': todayTasks,
        };

        print('📊 Dashboard Task Stats (from Google Tasks): $stats');
        print(
            '📝 Google Tasks breakdown: ${googleTaskItems.length} tasks found');
        return stats;
      } else {
        // Fallback to method channel if no Google Tasks
        print('📊 Dashboard: No Google Tasks found, using fallback');
        return await TaskService.getTaskStats();
      }
    } catch (e) {
      print('❌ Error getting Google Tasks stats for dashboard: $e');
      // Fallback to method channel
      return await TaskService.getTaskStats();
    }
  }
}

// Placeholder tabs
class CallsTab extends StatefulWidget {
  const CallsTab({Key? key}) : super(key: key);

  @override
  State<CallsTab> createState() => _CallsTabState();
}

class _CallsTabState extends State<CallsTab> {
  List<call_service.CallLog> _callLogs = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadCallLogs();
  }

  Future<void> _loadCallLogs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final logs = await call_service.CallLogService.getCallLogs(limit: 50);
      setState(() {
        _callLogs = logs;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading call logs: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<call_service.CallLog> get _filteredLogs {
    switch (_selectedFilter) {
      case 'missed':
        return _callLogs
            .where((log) => log.type == call_service.CallType.missed)
            .toList();
      case 'incoming':
        return _callLogs
            .where((log) => log.type == call_service.CallType.incoming)
            .toList();
      case 'outgoing':
        return _callLogs
            .where((log) => log.type == call_service.CallType.outgoing)
            .toList();
      default:
        return _callLogs;
    }
  }

  Future<void> _launchDialer(String phoneNumber) async {
    final sanitizedNumber =
        phoneNumber.replaceAll(RegExp(r'[^0-9+#*pwPW]'), '');

    if (sanitizedNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone number is unavailable for this contact'),
        ),
      );
      return;
    }

    final uri = Uri(scheme: 'tel', path: sanitizedNumber);

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open the dialer'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to launch the dialer'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: Theme.of(context).colorScheme.surface,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          elevation: 0,
          floating: true,
          snap: true,
          title: const Text('Call History'),
          actions: [
            IconButton(
              onPressed: _loadCallLogs,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () {
                      setState(() {
                        _selectedFilter = 'all';
                      });
                    },
                    icon: const Icon(Icons.phone, size: 20),
                    label: const Text('All'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _selectedFilter == 'all'
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.surfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedFilter = 'missed';
                      });
                    },
                    icon: const Icon(Icons.missed_video_call_outlined),
                    label: const Text('Missed'),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: _selectedFilter == 'missed'
                          ? Theme.of(context).colorScheme.errorContainer
                          : null,
                      foregroundColor: _selectedFilter == 'missed'
                          ? Theme.of(context).colorScheme.onErrorContainer
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_isLoading)
          const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_filteredLogs.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.phone_disabled,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No call logs found',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Check permissions in Settings',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildCallItem(context, _filteredLogs[index]),
              childCount: _filteredLogs.length,
            ),
          ),
      ],
    );
  }

  Widget _buildCallItem(BuildContext context, call_service.CallLog callLog) {
    IconData callIcon;
    Color callColor;

    switch (callLog.type) {
      case call_service.CallType.incoming:
        callIcon = Icons.call_received;
        callColor = Colors.green;
        break;
      case call_service.CallType.outgoing:
        callIcon = Icons.call_made;
        callColor = Colors.blue;
        break;
      case call_service.CallType.missed:
        callIcon = Icons.call_received;
        callColor = Colors.red;
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        onTap: () => _launchDialer(callLog.phoneNumber),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          // Only use NetworkImage for http/https URLs. content:// or file:// URIs are not supported by NetworkImage
          backgroundImage: (callLog.photoUrl != null &&
                  (callLog.photoUrl!.startsWith('http://') ||
                      callLog.photoUrl!.startsWith('https://')))
              ? NetworkImage(callLog.photoUrl!)
              : null,
          child: (callLog.photoUrl == null ||
                  !(callLog.photoUrl!.startsWith('http://') ||
                      callLog.photoUrl!.startsWith('https://')))
              ? Text(
                  callLog.displayName.isNotEmpty
                      ? callLog.displayName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: Text(
          callLog.displayName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(callIcon, size: 16, color: callColor),
                const SizedBox(width: 4),
                // Use Flexible to avoid overflow on narrow screens
                Flexible(
                  child: Text(
                    _formatTimeAgo(callLog.timestamp),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (callLog.duration > 0) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '• ${callLog.formattedDuration}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
            if (callLog.phoneNumber != callLog.displayName)
              Text(
                callLog.phoneNumber,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.info_outline),
              iconSize: 20,
            ),
            IconButton(
              onPressed: () => _launchDialer(callLog.phoneNumber),
              icon: Icon(
                Icons.phone,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}

class NotificationsTab extends StatefulWidget {
  const NotificationsTab({Key? key}) : super(key: key);

  @override
  State<NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends State<NotificationsTab> {
  List<AppNotification> _notifications = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final notifications =
          await NotificationService.getNotifications(limit: 50);
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading notifications: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<AppNotification> get _filteredNotifications {
    switch (_selectedFilter) {
      case 'priority':
        return _notifications
            .where((n) =>
                n.priority == NotificationPriority.high ||
                n.priority == NotificationPriority.urgent)
            .toList();
      case 'unread':
        return _notifications.where((n) => !n.isRead).toList();
      default:
        return _notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: Theme.of(context).colorScheme.surface,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          elevation: 0,
          floating: true,
          snap: true,
          title: const Text('Notifications'),
          actions: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.tune),
            ),
            IconButton(
              onPressed: _loadNotifications,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () {
                      setState(() {
                        _selectedFilter = 'all';
                      });
                    },
                    icon: const Icon(Icons.notifications, size: 20),
                    label: const Text('All'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _selectedFilter == 'all'
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.surfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedFilter = 'priority';
                      });
                    },
                    icon: const Icon(Icons.priority_high),
                    label: const Text('Priority'),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: _selectedFilter == 'priority'
                          ? Theme.of(context).colorScheme.errorContainer
                          : null,
                      foregroundColor: _selectedFilter == 'priority'
                          ? Theme.of(context).colorScheme.onErrorContainer
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_isLoading)
          const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_filteredNotifications.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications found',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Check notification permissions in Settings',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildNotificationItem(
                  context, _filteredNotifications[index]),
              childCount: _filteredNotifications.length,
            ),
          ),
      ],
    );
  }

  Widget _buildNotificationItem(
      BuildContext context, AppNotification notification) {
    Color priorityColor;
    switch (notification.priority) {
      case NotificationPriority.urgent:
        priorityColor = Colors.red;
        break;
      case NotificationPriority.high:
        priorityColor = Colors.orange;
        break;
      case NotificationPriority.normal:
        priorityColor = Colors.green;
        break;
      case NotificationPriority.low:
        priorityColor = Colors.blue;
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: priorityColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child:
              notification.appIcon != null && notification.appIcon!.isNotEmpty
                  ? Image.network(
                      notification.appIcon!,
                      width: 20,
                      height: 20,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.notifications,
                          size: 20,
                          color: priorityColor,
                        );
                      },
                    )
                  : Icon(
                      Icons.notifications,
                      size: 20,
                      color: priorityColor,
                    ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.w400 : FontWeight.w600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.displayContent,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    notification.appName,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '• ${_formatTimeAgo(notification.timestamp)}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: priorityColor,
                  shape: BoxShape.circle,
                ),
              ),
            const SizedBox(height: 4),
            Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
        onTap: () {
          // Navigate to notification detail
          if (!notification.isRead) {
            NotificationService.markAsRead(notification.id);
            setState(() {
              // Update the notification as read
              final index =
                  _notifications.indexWhere((n) => n.id == notification.id);
              if (index != -1) {
                // Note: Since AppNotification is immutable, we'd need to update the whole list
                // For now, just reload
                _loadNotifications();
              }
            });
          }
          // Navigate to notification detail page
          Navigator.pushNamed(context, '/notification-detail',
              arguments: notification);
        },
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}

class TasksTab extends StatefulWidget {
  const TasksTab({Key? key}) : super(key: key);

  @override
  State<TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<TasksTab> {
  List<Task> _tasks = [];
  Map<String, int> _taskStats = {};
  bool _isLoading = true;
  String _selectedFilter = 'today';

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final futures = await Future.wait([
        TaskService.getTasks(),
        TaskService.getTaskStats(),
        _loadGoogleTasks(),
      ]);

      final localTasks = futures[0] as List<dynamic>;
      final androidStats = futures[1] as Map<String, int>;
      final googleTasks = futures[2] as List<Task>;

      // Convert local tasks to the correct Task model type
      final allLocalTasks = localTasks.whereType<Task>().toList();

      // Combine local and Google tasks for display
      final allTasks = <Task>[...allLocalTasks, ...googleTasks];

      Map<String, int> combinedStats;

      if (googleTasks.isNotEmpty) {
        // Prioritize Google Tasks for statistics when available
        final now = DateTime.now();
        combinedStats = {
          'totalTasks': googleTasks.length,
          'completedTasks': googleTasks.where((task) => task.completed).length,
          'pendingTasks': googleTasks
              .where((task) =>
                  !task.completed &&
                  (task.dueDate == null || !task.dueDate!.isBefore(now)))
              .length,
          'overdueTasks': googleTasks
              .where((task) =>
                  !task.completed &&
                  task.dueDate != null &&
                  task.dueDate!.isBefore(now))
              .length,
          'todayTasks': googleTasks
              .where((task) =>
                  task.dueDate != null &&
                  task.dueDate!.year == now.year &&
                  task.dueDate!.month == now.month &&
                  task.dueDate!.day == now.day)
              .length,
        };
        print('📊 Task Stats (from Google Tasks): $combinedStats');
        print('📝 Google Tasks details:');
        for (final task in googleTasks) {
          print(
              '   - ${task.title}: completed=${task.completed}, due=${task.dueDate}');
        }
      } else if (allLocalTasks.isNotEmpty) {
        // Use local tasks if Google Tasks are not available
        final now = DateTime.now();
        combinedStats = {
          'totalTasks': allLocalTasks.length,
          'completedTasks':
              allLocalTasks.where((task) => task.completed).length,
          'pendingTasks': allLocalTasks
              .where((task) =>
                  !task.completed &&
                  (task.dueDate == null || !task.dueDate!.isBefore(now)))
              .length,
          'overdueTasks': allLocalTasks
              .where((task) =>
                  !task.completed &&
                  task.dueDate != null &&
                  task.dueDate!.isBefore(now))
              .length,
          'todayTasks': allLocalTasks
              .where((task) =>
                  task.dueDate != null &&
                  task.dueDate!.year == now.year &&
                  task.dueDate!.month == now.month &&
                  task.dueDate!.day == now.day)
              .length,
        };
        print('📊 Task Stats (from local tasks): $combinedStats');
      } else {
        // Fall back to Android method channel stats when no tasks are loaded
        combinedStats = androidStats;
        print('📊 Task Stats (from Android fallback): $combinedStats');
      }
      setState(() {
        _tasks = allTasks;
        _taskStats = combinedStats;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading tasks: $e');
      // Try to get Android stats as fallback
      try {
        final fallbackStats = await TaskService.getTaskStats();
        setState(() {
          _taskStats = fallbackStats;
          _isLoading = false;
        });
        print('📊 Task Stats (error fallback): $fallbackStats');
      } catch (fallbackError) {
        print('Error getting fallback stats: $fallbackError');
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> refreshTasks() async => _loadTasks();

  Future<void> showTaskDialog({Task? task}) async {
    final isEditing = task != null;

    Task? editingTask;
    if (task != null) {
      editingTask = task;
      if (!editingTask.taskId.startsWith('google_')) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Editing local tasks isn't supported yet."),
          ),
        );
        return;
      }
    }

    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: task?.title ?? '');
    final descriptionController =
        TextEditingController(text: task?.description ?? '');
    DateTime? selectedDueDate = task?.dueDate;

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit Task' : 'Add Task'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a task title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descriptionController,
                      decoration:
                          const InputDecoration(labelText: 'Description'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            selectedDueDate != null
                                ? 'Due: ${DateFormat('MMM d, yyyy').format(selectedDueDate!)}'
                                : 'No due date',
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: dialogContext,
                              initialDate: selectedDueDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setDialogState(() {
                                selectedDueDate = picked;
                              });
                            }
                          },
                          child: const Text('Pick Date'),
                        ),
                        if (selectedDueDate != null)
                          TextButton(
                            onPressed: () {
                              setDialogState(() {
                                selectedDueDate = null;
                              });
                            },
                            child: const Text('Clear'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() ?? false) {
                      Navigator.of(dialogContext).pop(true);
                    }
                  },
                  child: Text(isEditing ? 'Save' : 'Create'),
                ),
              ],
            );
          },
        );
      },
    );

    final trimmedTitle = titleController.text.trim();
    final trimmedDescription = descriptionController.text.trim();
    titleController.dispose();
    descriptionController.dispose();

    if (shouldSave == true) {
      final tasksService = google_tasks.TasksService();
      await tasksService.initialize();

      bool success = false;

      if (editingTask != null) {
        final listId = editingTask.metadata['taskListId'] as String?;
        final googleTaskId = editingTask.metadata['googleTaskId'] as String?;

        if (listId == null || googleTaskId == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Missing Google task metadata.'),
            ),
          );
          return;
        }

        success = await tasksService.updateTask(
          taskListId: listId,
          taskId: googleTaskId,
          title: trimmedTitle,
          description: trimmedDescription.isEmpty ? null : trimmedDescription,
          dueDate: selectedDueDate,
        );
      } else {
        final createdId = await tasksService.createTask(
          title: trimmedTitle,
          description: trimmedDescription.isEmpty ? null : trimmedDescription,
          dueDate: selectedDueDate,
        );
        success = createdId != null;
      }

      if (!mounted) return;

      if (success) {
        await _loadTasks();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing
                  ? 'Task updated in Google Tasks'
                  : 'Task created in Google Tasks',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing
                  ? 'Failed to update Google Task'
                  : 'Failed to create Google Task',
            ),
          ),
        );
      }
    }
  }

  Future<List<Task>> _loadGoogleTasks() async {
    try {
      // Initialize Google Tasks service
      final tasksService = google_tasks.TasksService();
      await tasksService.initialize();

      // Debug: List all tasks with their IDs
      await tasksService.debugListAllTasksWithIds();

      // Get Google tasks
      final googleTaskItems = await tasksService.getAllTasks();

      // Convert TaskItem objects to Task objects
      final convertedTasks = googleTaskItems
          .map((taskItem) => _convertTaskItemToTask(taskItem))
          .toList();

      print("🔄 Converted ${convertedTasks.length} Google tasks");
      for (final task in convertedTasks) {
        print("   📝 Converted task: '${task.title}' -> ID: ${task.taskId}");
        print("       Metadata: ${task.metadata}");
      }

      return convertedTasks;
    } catch (e) {
      print('Error loading Google tasks: $e');
      return [];
    }
  }

  Task _convertTaskItemToTask(google_tasks.TaskItem taskItem) {
    return Task(
      taskId: 'google_${taskItem.id}',
      title: taskItem.title,
      description: taskItem.description,
      dueDate: taskItem.dueDate,
      completed: taskItem.isCompleted,
      source:
          TaskSource.ai_generated, // Using existing enum value for Google tasks
      sourceRef: taskItem.id,
      priority: TaskPriority
          .medium, // Google Tasks don't have priority, default to medium
      category: 'Google Tasks',
      createdAt:
          DateTime.now(), // Google API doesn't provide creation date directly
      completedAt: taskItem.completedDate,
      tags: [taskItem.taskListName], // Use task list name as tag
      assignedTo: null,
      metadata: {
        'taskListId': taskItem.taskListId,
        'taskListName': taskItem.taskListName,
        'googleTaskId': taskItem.id,
      },
    );
  }

  List<Task> get _filteredTasks {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    switch (_selectedFilter) {
      case 'today':
        return _tasks.where((task) {
          if (task.dueDate == null) return false;
          return task.dueDate!.isBefore(tomorrow) && !task.completed;
        }).toList();
      case 'upcoming':
        return _tasks.where((task) {
          if (task.dueDate == null) return false;
          return task.dueDate!.isAfter(tomorrow) && !task.completed;
        }).toList();
      case 'completed':
        return _tasks.where((task) => task.completed).toList();
      case 'overdue':
        return _tasks.where((task) {
          if (task.dueDate == null) return false;
          return task.dueDate!.isBefore(now) && !task.completed;
        }).toList();
      default:
        return _tasks;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Theme.of(context).colorScheme.surface,
            foregroundColor: Theme.of(context).colorScheme.onSurface,
            elevation: 0,
            floating: true,
            snap: true,
            title: const Text('Tasks'),
            actions: [
              IconButton(
                onPressed: () async {
                  // Sign in to Google for Tasks integration
                  final success = await TaskService.signInToGoogle();
                  if (success) {
                    _loadTasks();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Connected to Google Tasks')),
                    );
                  }
                },
                icon: const Icon(Icons.cloud_sync),
              ),
              IconButton(
                onPressed: _loadTasks,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.task_alt,
                            size: 24,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Task Overview',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildProgressItem(
                                context,
                                'Completed',
                                _taskStats['completedTasks']?.toString() ?? '0',
                                Colors.green),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildProgressItem(
                                context,
                                'Pending',
                                _taskStats['pendingTasks']?.toString() ?? '0',
                                Colors.orange),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildProgressItem(
                                context,
                                'Overdue',
                                _taskStats['overdueTasks']?.toString() ?? '0',
                                Colors.red),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: () {
                        setState(() {
                          _selectedFilter = 'today';
                        });
                      },
                      icon: const Icon(Icons.today),
                      label: const Text('Today'),
                      style: FilledButton.styleFrom(
                        backgroundColor: _selectedFilter == 'today'
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.surfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedFilter = 'upcoming';
                        });
                      },
                      icon: const Icon(Icons.schedule),
                      label: const Text('Upcoming'),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: _selectedFilter == 'upcoming'
                            ? Theme.of(context).colorScheme.primaryContainer
                            : null,
                        foregroundColor: _selectedFilter == 'upcoming'
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_filteredTasks.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Lottie animation
                    SizedBox(
                      width: 180,
                      height: 180,
                      child: Lottie.asset(
                        'assets/animations/relax.json',
                        fit: BoxFit.contain,
                        repeat: true,
                        animate: true,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _selectedFilter == 'today'
                          ? 'No tasks for today'
                          : _selectedFilter == 'upcoming'
                              ? 'No upcoming tasks'
                              : _selectedFilter == 'completed'
                                  ? 'No completed tasks'
                                  : 'No overdue tasks',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in to Google to sync your tasks',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) =>
                    _buildTaskItem(context, _filteredTasks[index]),
                childCount: _filteredTasks.length,
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showTaskDialog(),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        icon: const Icon(Icons.add_task),
        label: const Text('Add Task'),
      ),
    );
  }

  Widget _buildProgressItem(
      BuildContext context, String label, String count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            count,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(BuildContext context, Task task) {
    Color priorityColor;
    switch (task.priority) {
      case TaskPriority.urgent:
        priorityColor = Colors.red;
        break;
      case TaskPriority.high:
        priorityColor = Colors.orange;
        break;
      case TaskPriority.medium:
        priorityColor = Colors.green;
        break;
      case TaskPriority.low:
        priorityColor = Colors.blue;
        break;
    }

    final isOverdue = task.dueDate != null &&
        task.dueDate!.isBefore(DateTime.now()) &&
        !task.completed;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: task.completed ? 1 : 3,
        color: task.completed
            ? Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.6)
            : Theme.of(context).colorScheme.surface,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 200),
          scale: task.completed ? 0.97 : 1.0,
          child: ListTile(
            leading: AnimatedScale(
              duration: const Duration(milliseconds: 150),
              scale: task.completed ? 1.1 : 1.0,
              child: Checkbox(
                value: task.completed,
                onChanged: (value) async {
                  try {
                    if (task.taskId.startsWith('google_')) {
                      print("🔍 Processing Google task: ${task.title}");
                      print("   Task ID: ${task.taskId}");
                      print("   Metadata: ${task.metadata}");

                      final listId = task.metadata['taskListId'] as String?;
                      final googleTaskId =
                          task.metadata['googleTaskId'] as String?;

                      print("   Extracted List ID: $listId");
                      print("   Extracted Google Task ID: $googleTaskId");

                      if (listId == null || googleTaskId == null) {
                        print("❌ Missing task identifiers!");
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Missing Google task identifiers.'),
                          ),
                        );
                        return;
                      }

                      final tasksService = google_tasks.TasksService();
                      await tasksService.initialize();

                      final shouldComplete = value ?? false;
                      final success = shouldComplete
                          ? await tasksService.markTaskCompleted(
                              listId, googleTaskId)
                          : await tasksService.markTaskNeedsAction(
                              listId, googleTaskId);

                      if (!success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              shouldComplete
                                  ? 'Failed to mark task as completed.'
                                  : 'Failed to move task back to pending state.',
                            ),
                          ),
                        );
                      }
                    } else {
                      // Handle local task update - need to convert back to TaskService Task
                      // For now, skip updating to avoid type conflicts
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Updating local tasks isn't supported yet.",
                            ),
                          ),
                        );
                      }
                      return;
                    }

                    await _loadTasks();

                    // Show completion celebration for completed tasks
                    if (value == true && mounted) {
                      _showTaskCompletionAnimation(context, task.title);
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error updating task: $e')),
                      );
                    }
                  }
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            title: Text(
              task.title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                decoration: task.completed ? TextDecoration.lineThrough : null,
                color: task.completed
                    ? Theme.of(context).colorScheme.onSurfaceVariant
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (task.description.isNotEmpty)
                  Text(
                    task.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: priorityColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        task.priority.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: priorityColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (task.dueDate != null) ...[
                      Icon(
                        isOverdue ? Icons.warning : Icons.schedule,
                        size: 12,
                        color: isOverdue
                            ? Colors.red
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isOverdue ? 'Overdue' : _formatDueDate(task.dueDate!),
                        style: TextStyle(
                          color: isOverdue
                              ? Colors.red
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight:
                              isOverdue ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            trailing: IconButton(
              onPressed: () {
                _showTaskOptions(context, task);
              },
              icon: const Icon(Icons.more_vert),
              iconSize: 20,
            ),
          ),
        ),
      ),
    );
  }

  void _showTaskCompletionAnimation(BuildContext context, String taskTitle) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '✓ "$taskTitle" completed!',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade50,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  String _formatDueDate(DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final taskDate = DateTime(dueDate.year, dueDate.month, dueDate.day);

    if (taskDate == today) {
      return 'Today';
    } else if (taskDate == tomorrow) {
      return 'Tomorrow';
    } else if (taskDate.isBefore(today)) {
      final difference = today.difference(taskDate).inDays;
      return '$difference day${difference == 1 ? '' : 's'} overdue';
    } else {
      final difference = taskDate.difference(today).inDays;
      return 'In $difference day${difference == 1 ? '' : 's'}';
    }
  }

  void _showTaskOptions(BuildContext context, Task task) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Task'),
              onTap: () {
                Navigator.pop(context);
                Future.microtask(() => showTaskDialog(task: task));
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text(
                'Delete Task',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () async {
                Navigator.pop(context);
                try {
                  if (task.taskId.startsWith('google_')) {
                    final listId = task.metadata['taskListId'] as String?;
                    final googleTaskId =
                        task.metadata['googleTaskId'] as String?;

                    if (listId == null || googleTaskId == null) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Missing Google task identifiers.'),
                          ),
                        );
                      }
                      return;
                    }

                    final tasksService = google_tasks.TasksService();
                    await tasksService.initialize();
                    final success =
                        await tasksService.deleteTask(listId, googleTaskId);

                    if (!success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to delete Google task.'),
                        ),
                      );
                      return;
                    }
                  } else {
                    await TaskService.deleteTask(task.taskId);
                  }

                  await _loadTasks();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Task deleted')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error deleting task: $e')),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class SearchQuery {
  final String title;
  final String subtitle;
  final IconData icon;
  final String query;

  const SearchQuery({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.query,
  });
}

// Dummy search delegate class to avoid errors
class SummarySearchDelegate extends SearchDelegate {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return const Center(child: Text('Search results will appear here'));
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return const Center(child: Text('Search suggestions'));
  }
}
