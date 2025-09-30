import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/live_alerts_service.dart';

class LiveAlertsOverlay extends ConsumerWidget {
  const LiveAlertsOverlay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(liveAlertsProvider);

    if (alerts.isEmpty) return const SizedBox.shrink();

    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: Column(
        children: alerts
            .take(3)
            .map((alert) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: LiveAlertCard(
                    alert: alert,
                    onDismiss: () => ref
                        .read(liveAlertsProvider.notifier)
                        .removeAlert(alert.id),
                    onTap: (action) {
                      if (action.isDismiss) {
                        ref
                            .read(liveAlertsProvider.notifier)
                            .removeAlert(alert.id);
                      }
                      action.onTap?.call();
                    },
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class LiveAlertCard extends StatefulWidget {
  final LiveAlert alert;
  final VoidCallback onDismiss;
  final Function(AlertAction) onTap;

  const LiveAlertCard({
    Key? key,
    required this.alert,
    required this.onDismiss,
    required this.onTap,
  }) : super(key: key);

  @override
  State<LiveAlertCard> createState() => _LiveAlertCardState();
}

class _LiveAlertCardState extends State<LiveAlertCard>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_fadeController);

    // Start entrance animation
    _slideController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    if (_isDismissing) return;

    setState(() {
      _isDismissing = true;
    });

    await _fadeController.reverse();
    await _slideController.reverse();

    widget.onDismiss();
  }

  Color _getAlertColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (widget.alert.type) {
      case AlertType.call:
        return colorScheme.primary;
      case AlertType.message:
        return colorScheme.secondary;
      case AlertType.email:
        return colorScheme.tertiary;
      case AlertType.social:
        return colorScheme.inversePrimary;
      case AlertType.delivery:
        return colorScheme.primaryContainer;
      case AlertType.reminder:
        return colorScheme.secondaryContainer;
      case AlertType.emergency:
        return colorScheme.error;
      case AlertType.system:
        return colorScheme.surface;
    }
  }

  IconData _getAlertIcon() {
    switch (widget.alert.type) {
      case AlertType.call:
        return Icons.phone;
      case AlertType.message:
        return Icons.message;
      case AlertType.email:
        return Icons.email;
      case AlertType.social:
        return Icons.people;
      case AlertType.delivery:
        return Icons.delivery_dining;
      case AlertType.reminder:
        return Icons.alarm;
      case AlertType.emergency:
        return Icons.warning;
      case AlertType.system:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final alertColor = _getAlertColor(context);

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Dismissible(
          key: ValueKey(widget.alert.id),
          direction: DismissDirection.horizontal,
          onDismissed: (_) => widget.onDismiss(),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: alertColor.withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: alertColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _getAlertIcon(),
                              color: alertColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.alert.title,
                                  style: TextStyle(
                                    color: colorScheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (widget.alert.message.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      widget.alert.message,
                                      style: TextStyle(
                                        color: colorScheme.onSurface
                                            .withOpacity(0.7),
                                        fontSize: 13,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: _dismiss,
                            icon: Icon(
                              Icons.close,
                              color: colorScheme.onSurface.withOpacity(0.6),
                              size: 18,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                      if (widget.alert.actions != null &&
                          widget.alert.actions!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: widget.alert.actions!
                                .take(2)
                                .map((action) => Padding(
                                      padding: const EdgeInsets.only(left: 8),
                                      child: _ActionButton(
                                        action: action,
                                        onTap: () => widget.onTap(action),
                                        color: alertColor,
                                      ),
                                    ))
                                .toList(),
                          ),
                        ),
                      // Priority indicator
                      if (widget.alert.priority == AlertPriority.critical ||
                          widget.alert.priority == AlertPriority.high)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Container(
                            height: 3,
                            decoration: BoxDecoration(
                              color: widget.alert.priority ==
                                      AlertPriority.critical
                                  ? colorScheme.error
                                  : alertColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final AlertAction action;
  final VoidCallback onTap;
  final Color color;

  const _ActionButton({
    Key? key,
    required this.action,
    required this.onTap,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: action.isDismiss
                ? colorScheme.surfaceVariant
                : color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: action.isDismiss
                  ? colorScheme.outline.withOpacity(0.3)
                  : color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (action.icon != null) ...[
                Icon(
                  action.icon,
                  size: 14,
                  color:
                      action.isDismiss ? colorScheme.onSurfaceVariant : color,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                action.label,
                style: TextStyle(
                  color:
                      action.isDismiss ? colorScheme.onSurfaceVariant : color,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Floating Action Button for testing alerts
class LiveAlertsTestFAB extends ConsumerWidget {
  const LiveAlertsTestFAB({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton.extended(
      onPressed: () => _showTestMenu(context, ref),
      icon: const Icon(Icons.notifications_active),
      label: const Text('Test Alerts'),
      backgroundColor: Theme.of(context).colorScheme.secondary,
    );
  }

  void _showTestMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Test Live Alerts',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(liveAlertsProvider.notifier).addDemoDeliveryAlert();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.delivery_dining),
              label: const Text('Delivery Alert'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(liveAlertsProvider.notifier).addDemoCallAlert();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.call),
              label: const Text('Call Alert'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(liveAlertsProvider.notifier).addDemoSocialAlert();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.message),
              label: const Text('Message Alert'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(liveAlertsProvider.notifier).clearAllAlerts();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.clear_all),
              label: const Text('Clear All'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
