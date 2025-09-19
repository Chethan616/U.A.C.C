// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../theme/app_theme.dart';
import '../models/enums.dart';
import '../widgets/summary_card.dart';
import '../widgets/calendar_widget.dart';
import '../widgets/upcoming_events_carousel.dart';
import '../utils/performant_animations.dart';
import '../widgets/expressive_icons.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late AnimationController _fabController;
  late AnimationController _pageController;
  late PageController _pageViewController;

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
    _pageController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _pageViewController = PageController(initialPage: 0);
    _animationController.forward();
    _fabController.forward();
    // Ensure the initial page transition animation runs so the first tab
    // is visible on first open. Without this the FadeTransition/SlideTransition
    // driven by _pageController remains at 0.0 opacity until a nav action.
    _pageController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fabController.dispose();
    _pageController.dispose();
    _pageViewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF1E1), // Updated to requested color
      body: PageView.builder(
        controller: _pageViewController,
        itemCount: _screens.length,
        onPageChanged: (index) {
          // Prevent page change from PageView gesture, only allow from bottom nav
        },
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          return FadeTransition(
            opacity: Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: _pageController,
              curve: Curves.easeInOutCubic,
            )),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: Offset(index < _selectedIndex ? -0.3 : 0.3, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _pageController,
                curve: Curves.easeInOutCubic,
              )),
              child: _screens[index],
            ),
          );
        },
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

                // Reset and restart page animation for smooth transitions
                _pageController.reset();
                _pageController.forward();

                _pageViewController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOutCubic,
                );

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
                  AppColors.primary,
                  () => Navigator.pop(context),
                ),
                _buildQuickAction(
                  'Add Task',
                  Icons.task_alt_outlined,
                  AppColors.accent,
                  () => Navigator.pop(context),
                ),
                _buildQuickAction(
                  'Add Note',
                  Icons.note_add_outlined,
                  AppColors.success,
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
                color: AppColors.text,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardTab extends StatefulWidget {
  const DashboardTab({Key? key}) : super(key: key);

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab>
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
      color: AppColors.primary,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: const Color(0xFFFEF1E1),
            foregroundColor: AppColors.text,
            elevation: 0,
            floating: true,
            snap: true,
            expandedHeight: 120,
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
                      Text(
                        'Good ${_getGreeting()}, Chethan',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                        ),
                      ),
                      Text(
                        'Here\'s your daily summary',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
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
                            decoration: const BoxDecoration(
                              color: AppColors.danger,
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
                        shadowColor: AppColors.shadow.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: AppColors.outline.withOpacity(0.2),
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
                                    Theme.of(context).colorScheme.secondary,
                                    1),
                              ),
                              Container(
                                width: 1,
                                height: 60,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                              Expanded(
                                child: _buildStatItem('Tasks', '5', 'tasks',
                                    Theme.of(context).colorScheme.tertiary, 2),
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
                          return ExpressiveIcons.phone(
                              size: 24.0, color: color, filled: true);
                        case 'notifications':
                          return ExpressiveIcons.notifications(
                              size: 24.0, color: color, filled: true);
                        case 'tasks':
                          return ExpressiveIcons.tasks(
                              size: 24.0, color: color, filled: true);
                        default:
                          return ExpressiveIcons.dashboard(
                              size: 24.0, color: color, filled: true);
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
        return Colors.red.shade700;
      case PriorityLevel.high:
        return AppColors.danger;
      case PriorityLevel.medium:
        return AppColors.accent;
      case PriorityLevel.low:
        return AppColors.success;
    }
  }

  Future<void> _refreshData() async {
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Dashboard refreshed'),
          backgroundColor: AppColors.success,
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
                    icon: ExpressiveIcons.phone(
                      size: 20,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                      filled: true,
                    ),
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
              icon: ExpressiveIcons.phone(
                size: 18,
                color: Theme.of(context).colorScheme.primary,
                filled: true,
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
                    icon: ExpressiveIcons.notifications(
                      size: 20,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                      filled: true,
                    ),
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
          child: ExpressiveIcons.notifications(
            size: 20,
            color: priorityColor,
            filled: true,
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
                        ExpressiveIcons.tasks(
                          size: 24,
                          color: Theme.of(context).colorScheme.primary,
                          filled: true,
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

class ProfileTab extends StatelessWidget {
  const ProfileTab({Key? key}) : super(key: key);

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
          title: const Text('Profile'),
          actions: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.edit),
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
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor:
                              Theme.of(context).colorScheme.primaryContainer,
                          child: ExpressiveIcons.person(
                            size: 60,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                            filled: true,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Theme.of(context).colorScheme.surface,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.camera_alt,
                              size: 16,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'John Doe',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    Text(
                      'Software Engineer',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Online',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
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
            child: Card(
              child: Column(
                children: [
                  _buildProfileItem(
                    context,
                    Icons.email_outlined,
                    'Email',
                    'john.doe@company.com',
                    () {},
                  ),
                  _buildProfileItem(
                    context,
                    Icons.phone_outlined,
                    'Phone',
                    '+1 (555) 123-4567',
                    () {},
                  ),
                  _buildProfileItem(
                    context,
                    Icons.location_on_outlined,
                    'Location',
                    'San Francisco, CA',
                    () {},
                  ),
                  _buildProfileItem(
                    context,
                    Icons.work_outline,
                    'Department',
                    'Engineering',
                    () {},
                  ),
                ],
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: Column(
                children: [
                  _buildSettingsItem(
                    context,
                    Icons.notifications_outlined,
                    'Notifications',
                    () {},
                  ),
                  _buildSettingsItem(
                    context,
                    Icons.privacy_tip_outlined,
                    'Privacy',
                    () {},
                  ),
                  _buildSettingsItem(
                    context,
                    Icons.security_outlined,
                    'Security',
                    () {},
                  ),
                  _buildSettingsItem(
                    context,
                    Icons.palette_outlined,
                    'Theme',
                    () {},
                  ),
                  _buildSettingsItem(
                    context,
                    Icons.language_outlined,
                    'Language',
                    () {},
                  ),
                ],
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: Column(
                children: [
                  _buildSettingsItem(
                    context,
                    Icons.help_outline,
                    'Help & Support',
                    () {},
                  ),
                  _buildSettingsItem(
                    context,
                    Icons.info_outline,
                    'About',
                    () {},
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.logout,
                      color: Colors.red,
                    ),
                    title: Text(
                      'Sign Out',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () {},
                    trailing: Icon(
                      Icons.chevron_right,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }

  Widget _buildProfileItem(
    BuildContext context,
    IconData icon,
    String title,
    String value,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(
        icon,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(value),
      trailing: Icon(
        Icons.chevron_right,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      onTap: onTap,
    );
  }

  Widget _buildSettingsItem(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(
        icon,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      onTap: onTap,
    );
  }
}

// Data Models
enum SummaryType { call, notification }

class SummaryItem {
  final String title;
  final String summary;
  final String subtitle;
  final SummaryType type;
  final PriorityLevel priority;

  SummaryItem({
    required this.title,
    required this.summary,
    required this.subtitle,
    required this.type,
    required this.priority,
  });
}

// Search Delegate
class SummarySearchDelegate extends SearchDelegate<String> {
  @override
  String get searchFieldLabel => 'Search calls and notifications...';

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.text,
        elevation: 1,
        shadowColor: AppColors.shadow.withOpacity(0.1),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(
          color: AppColors.muted,
          fontSize: 16,
        ),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        onPressed: () => query = '',
        icon: Icon(Icons.clear, color: AppColors.text),
        tooltip: 'Clear search',
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () => close(context, ''),
      icon: Icon(Icons.arrow_back, color: AppColors.text),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.isEmpty) {
      return const Center(
        child: Text(
          'Enter a search term to find calls and notifications',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      );
    }

    // Mock search results - in a real app, this would be actual search data
    final results = [
      'Business Meeting with John',
      'Payment Reminder - GPay',
      'Call from Mom',
      'WhatsApp message from Team',
    ]
        .where((item) => item.toLowerCase().contains(query.toLowerCase()))
        .toList();

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No results found for "$query"',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching with different keywords',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final result = results[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Icon(
              result.contains('Call') ? Icons.phone : Icons.notifications,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              size: 20,
            ),
          ),
          title: Text(result),
          subtitle: Text(
            'Result ${index + 1} of ${results.length}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
          onTap: () {
            close(context, result);
            // Handle result selection
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = [
      SearchSuggestion(
        title: 'Recent calls',
        subtitle: 'View all call summaries',
        icon: Icons.phone,
        query: 'calls',
      ),
      SearchSuggestion(
        title: 'Notifications',
        subtitle: 'Find notification summaries',
        icon: Icons.notifications,
        query: 'notifications',
      ),
      SearchSuggestion(
        title: 'High priority',
        subtitle: 'Important items only',
        icon: Icons.priority_high,
        query: 'high priority',
      ),
      SearchSuggestion(
        title: 'Business',
        subtitle: 'Work-related content',
        icon: Icons.business,
        query: 'business',
      ),
      SearchSuggestion(
        title: 'Today',
        subtitle: 'Items from today',
        icon: Icons.today,
        query: 'today',
      ),
    ];

    return Container(
      color: AppColors.surface,
      child: ListView.builder(
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          final suggestion = suggestions[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Icon(
                suggestion.icon,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            title: Text(
              suggestion.title,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              suggestion.subtitle,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
            trailing: Icon(
              Icons.north_west,
              color: Colors.grey.shade400,
              size: 16,
            ),
            onTap: () {
              query = suggestion.query;
              showResults(context);
            },
          );
        },
      ),
    );
  }
}

class SearchSuggestion {
  final String title;
  final String subtitle;
  final IconData icon;
  final String query;

  SearchSuggestion({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.query,
  });
}
