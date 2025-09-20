import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/enums.dart';
import 'notification_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _fabAnimationController;
  String _selectedFilter = 'All';

  final List<String> _filters = [
    'All',
    'Unread',
    'Important',
    'Financial',
    'Social'
  ];

  // Demo notification data
  final List<NotificationItem> _notifications = [
    NotificationItem(
      notificationData: NotificationData(
        id: '1',
        appName: 'GPay',
        appIcon: '💳',
        title: 'Payment Reminder',
        body: 'Your electricity bill of ₹2,450 is due tomorrow.',
        bigText: 'Pay now to avoid late charges. Due date: Tomorrow',
        category: 'Financial',
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        isRead: false,
        priority: PriorityLevel.high,
        aiSummary: 'Electricity bill payment reminder - high priority',
        sentiment: 'Neutral',
        urgency: 'High',
        requiresAction: true,
        containsPersonalInfo: true,
        suggestedActions: [],
        relatedNotifications: [],
      ),
      isReadLocal: false,
    ),
    NotificationItem(
      notificationData: NotificationData(
        id: '2',
        appName: 'WhatsApp',
        appIcon: '💬',
        title: 'John Doe',
        body: 'Hey! Are we still on for the meeting tomorrow?',
        bigText:
            'John Doe: Hey! Are we still on for the meeting tomorrow? Please let me know by tonight.',
        category: 'Social',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        isRead: true,
        priority: PriorityLevel.medium,
        aiSummary: 'Meeting confirmation request from John',
        sentiment: 'Neutral',
        urgency: 'Medium',
        requiresAction: true,
        containsPersonalInfo: false,
        suggestedActions: [],
        relatedNotifications: [],
      ),
      isReadLocal: true,
    ),
    NotificationItem(
      notificationData: NotificationData(
        id: '3',
        appName: 'Zomato',
        appIcon: '🍔',
        title: 'Order Delivered',
        body: 'Your order from Pizza Corner has been delivered successfully!',
        bigText:
            'Thank you for choosing Zomato. Rate your order and delivery experience.',
        category: 'General',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        isRead: true,
        priority: PriorityLevel.low,
        aiSummary: 'Food delivery confirmation - order completed',
        sentiment: 'Positive',
        urgency: 'Low',
        requiresAction: false,
        containsPersonalInfo: false,
        suggestedActions: [],
        relatedNotifications: [],
      ),
      isReadLocal: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _animationController.forward();
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredNotifications = _getFilteredNotifications();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAnimatedAppBar(),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: _buildNotificationsList(filteredNotifications),
          ),
        ],
      ),
      floatingActionButton: _buildAnimatedFAB(),
    );
  }

  PreferredSizeWidget _buildAnimatedAppBar() {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: Hero(
          tag: 'back_button',
          child: Icon(
            Icons.arrow_back_ios_new,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _animationController,
              curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
            )),
            child: FadeTransition(
              opacity: _animationController,
              child: Text(
                'Notifications',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          );
        },
      ),
      actions: [
        AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return ScaleTransition(
              scale: Tween<double>(
                begin: 0.0,
                end: 1.0,
              ).animate(CurvedAnimation(
                parent: _animationController,
                curve: const Interval(0.4, 1.0, curve: Curves.elasticOut),
              )),
              child: IconButton(
                icon: Icon(
                  Icons.tune,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                onPressed: () {
                  // Show filter options
                },
              ),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildFilterChips() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
          )),
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = filter == _selectedFilter;

                return AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: Tween<double>(
                        begin: 0.0,
                        end: 1.0,
                      )
                          .animate(CurvedAnimation(
                            parent: _animationController,
                            curve: Interval(
                              (0.3 + (index * 0.05)).clamp(0.0, 0.8),
                              (0.7 + (index * 0.05)).clamp(0.0, 1.0),
                              curve: Curves.elasticOut,
                            ),
                          ))
                          .value,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: FilterChip(
                          label: Text(filter),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedFilter = filter;
                            });
                          },
                          backgroundColor:
                              Theme.of(context).colorScheme.surface,
                          selectedColor:
                              Theme.of(context).colorScheme.primaryContainer,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.outline,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationsList(List<NotificationItem> notifications) {
    if (notifications.isEmpty) {
      return _buildEmptyState();
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
          )),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(1, 0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: _animationController,
                      curve: Interval(
                        0.5 + (index * 0.1),
                        0.9 + (index * 0.1),
                        curve: Curves.easeOutBack,
                      ),
                    )),
                    child: _buildNotificationCard(notifications[index]),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildNotificationCard(NotificationItem notificationItem) {
    final notification = notificationItem.notificationData;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Hero(
        tag: 'notification_${notification.id}',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.pushNamed(
                context,
                '/notification-detail',
                arguments: notification,
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: notificationItem.isReadLocal
                      ? Theme.of(context).colorScheme.outline
                      : Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.8),
                  width: notificationItem.isReadLocal ? 1.5 : 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).shadowColor,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            notification.appIcon,
                            style: const TextStyle(fontSize: 20),
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
                                  notification.appName,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const Spacer(),
                                Text(
                                  _getTimeAgo(notification.timestamp),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                if (!notificationItem.isReadLocal) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              notification.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    notification.body,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (notification.priority == PriorityLevel.high) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'High Priority',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onErrorContainer,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                  if (notification.requiresAction) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.priority_high,
                          size: 16,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Action Required',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.secondary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: Theme.of(context)
                .colorScheme
                .onSurfaceVariant
                .withValues(alpha: 0.5),
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
            'Check back later for updates',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withValues(alpha: 0.7),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedFAB() {
    return AnimatedBuilder(
      animation: _fabAnimationController,
      builder: (context, child) {
        return ScaleTransition(
          scale: Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(CurvedAnimation(
            parent: _fabAnimationController,
            curve: Curves.elasticOut,
          )),
          child: FloatingActionButton(
            backgroundColor: Theme.of(context).colorScheme.primary,
            onPressed: () {
              // Mark all as read
              setState(() {
                for (var notificationItem in _notifications) {
                  notificationItem.isReadLocal = true;
                }
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('All notifications marked as read'),
                  backgroundColor: Theme.of(context).colorScheme.tertiary,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
            child: Icon(
              Icons.done_all,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        );
      },
    );
  }

  List<NotificationItem> _getFilteredNotifications() {
    switch (_selectedFilter) {
      case 'Unread':
        return _notifications.where((n) => !n.isReadLocal).toList();
      case 'Important':
        return _notifications
            .where((n) => n.notificationData.priority == PriorityLevel.high)
            .toList();
      case 'Financial':
        return _notifications
            .where((n) => n.notificationData.category == 'Financial')
            .toList();
      case 'Social':
        return _notifications
            .where((n) => n.notificationData.category == 'Social')
            .toList();
      default:
        return _notifications;
    }
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

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
}

class NotificationItem {
  final NotificationData notificationData;
  bool isReadLocal;

  NotificationItem({
    required this.notificationData,
    required this.isReadLocal,
  });
}
