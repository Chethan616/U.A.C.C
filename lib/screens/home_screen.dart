// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/theme_provider.dart';
import '../models/enums.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../widgets/summary_card.dart';
import '../widgets/calendar_widget.dart';
import '../widgets/upcoming_events_carousel.dart';
import 'package:intl/intl.dart';
import 'profile_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late AnimationController _fabController;

  final List<Widget> _screens = [
    const DashboardTab(),
    const CallsTab(),
    const NotificationsTab(),
    const TasksTab(),
    const ProfileTab(),
  ];

  final List<BottomNavigationBarItem> _navItems = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.dashboard_outlined),
      activeIcon: Icon(Icons.dashboard_rounded),
      label: 'Dashboard',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.phone_outlined),
      activeIcon: Icon(Icons.phone_rounded),
      label: 'Calls',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.notifications_outlined),
      activeIcon: Icon(Icons.notifications_rounded),
      label: 'Notifications',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.task_alt_outlined),
      activeIcon: Icon(Icons.task_alt_rounded),
      label: 'Tasks',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.person_outline_rounded),
      activeIcon: Icon(Icons.person_rounded),
      label: 'Profile',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animationController.forward();
    _fabController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
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
                heroTag: "dashboard_fab",
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
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
          ),
          child: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              if (index != _selectedIndex) {
                setState(() {
                  _selectedIndex = index;
                });

                // Handle FAB visibility
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
                    label: entry.label ?? '',
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
          color: Colors.white,
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
                color: Colors.grey.shade300,
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
                _buildQuickAction(
                  'Add Call',
                  Icons.phone_outlined,
                  Theme.of(context).colorScheme.primary,
                  () => Navigator.pop(context),
                ),
                _buildQuickAction(
                  'Add Task',
                  Icons.task_alt_outlined,
                  Theme.of(context).colorScheme.secondary,
                  () => Navigator.pop(context),
                ),
                _buildQuickAction(
                  'Add Note',
                  Icons.note_add_outlined,
                  Theme.of(context).colorScheme.tertiary,
                  () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
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

  final List<SummaryItem> _recentSummaries = [
    SummaryItem(
      title: 'Business Meeting with John',
      summary:
          'Discussed Q4 objectives and budget allocation. Need to prepare quarterly report by Friday.',
      subtitle: '2 hours ago',
      type: SummaryType.call,
      priority: PriorityLevel.high,
    ),
    SummaryItem(
      title: 'Payment Reminder - GPay',
      summary:
          'Your electricity bill of ₹2,450 is due tomorrow. Pay now to avoid late charges.',
      subtitle: '30 minutes ago',
      type: SummaryType.notification,
      priority: PriorityLevel.medium,
    ),
    SummaryItem(
      title: 'Family Call with Mom',
      summary:
          'Reminded about cousin\'s wedding next month. Need to book flight tickets soon.',
      subtitle: '1 day ago',
      type: SummaryType.call,
      priority: PriorityLevel.low,
    ),
    SummaryItem(
      title: 'Bank Alert - SBI',
      summary:
          'Your account balance is below minimum. Please add funds to maintain account.',
      subtitle: '2 days ago',
      type: SummaryType.notification,
      priority: PriorityLevel.high,
    ),
  ];

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
  }

  @override
  void dispose() {
    _dashboardController.dispose();
    _cardController.dispose();
    super.dispose();
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
                      Consumer(
                        builder: (context, ref, child) {
                          final userProfile =
                              ref.watch(currentUserProfileProvider);
                          return userProfile.when(
                            data: (user) {
                              final firstName = user?.firstName ?? 'User';
                              return Text(
                                'Good ${_getGreeting()}, $firstName',
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
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                            ),
                            error: (_, __) => Text(
                              'Good ${_getGreeting()}',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                            ),
                          );
                        },
                      ),
                      Text(
                        'Here\'s your daily summary',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 14,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
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
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: _dashboardController,
                    curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
                  ),
                ),
                child: IconButton(
                  onPressed: _showSearch,
                  icon: const Icon(Icons.search),
                ),
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
                                    '12',
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
                                    '28',
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
                                child: _buildStatItem('Tasks', '5', 'tasks',
                                    Theme.of(context).colorScheme.primary, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

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
    await Future.delayed(const Duration(seconds: 1));
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

  void _showSearch() {
    showSearch(context: context, delegate: SummarySearchDelegate());
  }

  void _showNotifications() {
    Navigator.pushNamed(context, '/notifications');
  }

  void _viewAllSummaries() {
    Navigator.pushNamed(context, '/all-summaries');
  }

  void _openSummaryDetail(SummaryItem item) {
    if (item.type == SummaryType.call) {
      Navigator.pushNamed(context, '/call-detail', arguments: item);
    } else {
      Navigator.pushNamed(context, '/notification-detail', arguments: item);
    }
  }
}

// Placeholder tabs
class CallsTab extends StatelessWidget {
  const CallsTab({Key? key}) : super(key: key);

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
              onPressed: () {},
              icon: const Icon(Icons.search),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.more_vert),
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
                    onPressed: () {},
                    icon: const Icon(Icons.phone, size: 20),
                    label: const Text('Recent'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.missed_video_call_outlined),
                    label: const Text('Missed'),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildCallItem(context, index),
            childCount: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildCallItem(BuildContext context, int index) {
    final callTypes = ['incoming', 'outgoing', 'missed'];
    final callType = callTypes[index % 3];
    final contacts = ['John Doe', 'Sarah Wilson', 'Mike Johnson', 'Emma Davis'];
    final contact = contacts[index % 4];
    final times = ['2 min ago', '1 hour ago', '3 hours ago', 'Yesterday'];
    final time = times[index % 4];

    IconData callIcon;
    Color callColor;

    switch (callType) {
      case 'incoming':
        callIcon = Icons.call_received;
        callColor = Colors.green;
        break;
      case 'outgoing':
        callIcon = Icons.call_made;
        callColor = Colors.blue;
        break;
      case 'missed':
        callIcon = Icons.call_received;
        callColor = Colors.red;
        break;
      default:
        callIcon = Icons.call;
        callColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            contact[0],
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          contact,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Row(
          children: [
            Icon(callIcon, size: 16, color: callColor),
            const SizedBox(width: 4),
            Text(time),
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
              onPressed: () {},
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
}

class NotificationsTab extends StatelessWidget {
  const NotificationsTab({Key? key}) : super(key: key);

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
              onPressed: () {},
              icon: const Icon(Icons.more_vert),
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
                    onPressed: () {},
                    icon: const Icon(Icons.notifications, size: 20),
                    label: const Text('All'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.priority_high),
                    label: const Text('Priority'),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildNotificationItem(context, index),
            childCount: 15,
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationItem(BuildContext context, int index) {
    final apps = ['WhatsApp', 'Gmail', 'Bank Alert', 'Calendar', 'Weather'];
    final app = apps[index % 5];
    final titles = [
      'New message from Sarah',
      'Meeting reminder in 30 min',
      'Transaction alert: ₹500 debited',
      'Flight booking confirmed',
      'Rain expected today'
    ];
    final title = titles[index % 5];
    final times = ['2 min ago', '15 min ago', '1 hour ago', '3 hours ago'];
    final time = times[index % 4];

    final priorities = [
      PriorityLevel.high,
      PriorityLevel.medium,
      PriorityLevel.low
    ];
    final priority = priorities[index % 3];

    Color priorityColor;
    switch (priority) {
      case PriorityLevel.high:
        priorityColor = Colors.red;
        break;
      case PriorityLevel.medium:
        priorityColor = Colors.orange;
        break;
      case PriorityLevel.low:
        priorityColor = Colors.green;
        break;
      default:
        priorityColor = Colors.grey;
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
          child: Icon(
            Icons.notifications,
            size: 20,
            color: priorityColor,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Text(
              app,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Text('• $time'),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
        },
      ),
    );
  }
}

class TasksTab extends StatelessWidget {
  const TasksTab({Key? key}) : super(key: key);

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
          title: const Text('Tasks'),
          actions: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.add),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.more_vert),
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
                          'Today\'s Progress',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
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
                              context, 'Completed', '8', Colors.green),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildProgressItem(
                              context, 'Pending', '3', Colors.orange),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildProgressItem(
                              context, 'Overdue', '1', Colors.red),
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
                    onPressed: () {},
                    icon: const Icon(Icons.today),
                    label: const Text('Today'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.schedule),
                    label: const Text('Upcoming'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildTaskItem(context, index),
            childCount: 12,
          ),
        ),
      ],
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
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(BuildContext context, int index) {
    final tasks = [
      'Complete project proposal',
      'Review design mockups',
      'Schedule team meeting',
      'Update documentation',
      'Test new features',
      'Call client for feedback',
      'Prepare presentation',
      'Send weekly report',
    ];
    final task = tasks[index % 8];
    final completed = index % 3 == 0;
    final priorities = [
      PriorityLevel.high,
      PriorityLevel.medium,
      PriorityLevel.low
    ];
    final priority = priorities[index % 3];

    Color priorityColor;
    switch (priority) {
      case PriorityLevel.high:
        priorityColor = Colors.red;
        break;
      case PriorityLevel.medium:
        priorityColor = Colors.orange;
        break;
      case PriorityLevel.low:
        priorityColor = Colors.green;
        break;
      default:
        priorityColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Checkbox(
          value: completed,
          onChanged: (value) {},
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        title: Text(
          task,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: completed ? TextDecoration.lineThrough : null,
            color: completed
                ? Theme.of(context).colorScheme.onSurfaceVariant
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: priorityColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                priority.name.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: priorityColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Due today',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          onPressed: () {},
          icon: const Icon(Icons.more_vert),
          iconSize: 20,
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
