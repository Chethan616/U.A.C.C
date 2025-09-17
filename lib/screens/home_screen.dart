// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/enums.dart';
import '../widgets/summary_card.dart';
import '../widgets/calendar_widget.dart';
import '../widgets/upcoming_events_carousel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  int _previousIndex = 0;
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
      body: PageView(
        controller: _pageViewController,
        onPageChanged: (index) {
          // Prevent page change from PageView gesture, only allow from bottom nav
        },
        physics: const NeverScrollableScrollPhysics(),
        children: _screens
            .map(
              (screen) => AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) => screen,
              ),
            )
            .toList(),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            if (index != _selectedIndex) {
              _previousIndex = _selectedIndex;
              setState(() {
                _selectedIndex = index;
              });

              // Smooth page transition
              _pageController.reset();
              _pageController.forward();

              _pageViewController.animateToPage(
                index,
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOutCubic,
              );
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFFFEF1E1), // Match new background
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.muted,
          elevation: 0,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: _navItems
              .map((item) => BottomNavigationBarItem(
                    icon: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: EdgeInsets.all(
                          _selectedIndex == _navItems.indexOf(item) ? 8 : 4),
                      decoration: BoxDecoration(
                        color: _selectedIndex == _navItems.indexOf(item)
                            ? AppColors.primary.withOpacity(0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Transform.scale(
                        scale: _selectedIndex == _navItems.indexOf(item)
                            ? 1.1
                            : 1.0,
                        child: item.icon,
                      ),
                    ),
                    activeIcon: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Transform.scale(
                        scale: 1.1,
                        child: item.activeIcon,
                      ),
                    ),
                    label: item.label,
                  ))
              .toList(),
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
              title: Column(
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
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
            ),
            actions: [
              IconButton(
                onPressed: _showSearch,
                icon: const Icon(Icons.search),
              ),
              IconButton(
                onPressed: _showNotifications,
                icon: Stack(
                  children: [
                    const Icon(Icons.notifications_outlined),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.danger,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Stats Container
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: AppColors.outline,
                        width: 1.0,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildStatItem('Calls Today', '12',
                                Icons.phone, AppColors.primary),
                          ),
                          Container(
                            width: 1,
                            height: 60,
                            color: AppColors.border,
                          ),
                          Expanded(
                            child: _buildStatItem('Notifications', '28',
                                Icons.notifications, AppColors.accent),
                          ),
                          Container(
                            width: 1,
                            height: 60,
                            color: AppColors.border,
                          ),
                          Expanded(
                            child: _buildStatItem(
                                'Tasks', '5', Icons.task_alt, AppColors.danger),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Calendar Widget
                const CalendarWidget(),

                const SizedBox(height: 16),

                // Upcoming Events Carousel
                const UpcomingEventsCarousel(),

                const SizedBox(height: 8),

                // Recent Summaries Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Summaries',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      TextButton(
                        onPressed: _viewAllSummaries,
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),

          // Recent Summaries List
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = _recentSummaries[index];
                return SummaryCard(
                  title: item.title,
                  summary: item.summary,
                  subtitle: item.subtitle,
                  leadingIcon: item.type == SummaryType.call
                      ? Icons.phone
                      : Icons.notifications,
                  accentColor: _getPriorityColor(item.priority),
                  onTap: () => _openSummaryDetail(item),
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

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.text,
                fontSize: 20,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.muted,
                fontWeight: FontWeight.w500,
              ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
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
    return const Center(
      child: Text('Calls Tab - Coming Soon'),
    );
  }
}

class NotificationsTab extends StatelessWidget {
  const NotificationsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Notifications Tab - Coming Soon'),
    );
  }
}

class TasksTab extends StatelessWidget {
  const TasksTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Tasks Tab - Coming Soon'),
    );
  }
}

class ProfileTab extends StatelessWidget {
  const ProfileTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Profile Tab - Coming Soon'),
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
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: Icon(
              result.contains('Call') ? Icons.phone : Icons.notifications,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          title: Text(result),
          subtitle: Text(
            'Result ${index + 1} of ${results.length}',
            style: TextStyle(
              color: Colors.grey.shade600,
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
