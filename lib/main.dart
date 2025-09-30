import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animations/animations.dart';
import 'firebase_options.dart';
import 'theme/theme_provider.dart';
import 'models/enums.dart';
import 'screens/onboarding_screen.dart';
import 'screens/modern_onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/call_detail_screen.dart';
import 'screens/notification_detail_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/call_logs_screen.dart';
import 'screens/comprehensive_dashboard.dart';
import 'screens/all_summaries_screen.dart';
import 'screens/permission_request_screen.dart';
import 'screens/register_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/full_calendar_screen.dart';
import 'utils/animated_routes.dart';
import 'services/api_config_service.dart';
import 'services/ai_analysis_service.dart' show TranscriptMessage;
import 'services/background_notification_processor.dart';
// Removed live activity screen import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize API keys
  await ApiConfigService.initializeApiKeys();

  // Initialize Background Notification Processor
  await BackgroundNotificationProcessor.instance.initialize();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // System UI overlay will be updated after the first frame using app theme
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFFD9B88A));
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: scheme.surface,
        statusBarIconBrightness: scheme.brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
        systemNavigationBarColor: scheme.surface,
        systemNavigationBarIconBrightness: scheme.brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
      ),
    );
  });

  runApp(
    ProviderScope(
      child: const CairoApp(),
    ),
  );
}

class CairoApp extends ConsumerWidget {
  const CairoApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeProvider);
    final systemBrightness = MediaQuery.platformBrightnessOf(context);
    final theme = AppThemes.getTheme(currentTheme, systemBrightness);

    return MaterialApp(
      title: 'Cairo - Universal AI Call Companion',
      theme: theme,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/onboarding':
            return AnimatedRoutes.createRoute(
              const OnboardingScreen(),
              type: TransitionType.fadeThrough,
            );
          case '/modern-onboarding':
            final args = settings.arguments as Map<String, dynamic>? ?? {};
            final isForNewUser = args['isForNewUser'] as bool? ?? true;
            return AnimatedRoutes.createRoute(
              ModernOnboardingScreen(isForNewUser: isForNewUser),
              type: TransitionType.fadeThrough,
            );
          case '/login':
            return AnimatedRoutes.createRoute(
              const LoginScreen(),
              type: TransitionType.sharedAxis,
              axis: SharedAxisTransitionType.horizontal,
            );
          case '/register':
            return AnimatedRoutes.createRoute(
              const RegisterScreen(),
              type: TransitionType.sharedAxis,
              axis: SharedAxisTransitionType.horizontal,
            );
          case '/home':
            return AnimatedRoutes.createRoute(
              const HomeScreen(),
              type: TransitionType.fadeThrough,
            );
          case '/notifications':
            return AnimatedRoutes.createRoute(
              const NotificationsScreen(),
              type: TransitionType.sharedAxis,
              axis: SharedAxisTransitionType.vertical,
            );
          case '/all-summaries':
            final args = settings.arguments;
            List<SummaryItem> summaries = <SummaryItem>[];

            if (args is List<SummaryItem>) {
              summaries = List<SummaryItem>.from(args);
            } else if (args is List) {
              summaries = args.whereType<SummaryItem>().toList();
            } else if (args is Map) {
              final potentialList = args['summaries'];
              if (potentialList is List<SummaryItem>) {
                summaries = List<SummaryItem>.from(potentialList);
              } else if (potentialList is List) {
                summaries = potentialList.whereType<SummaryItem>().toList();
              }
            }

            return AnimatedRoutes.createRoute(
              AllSummariesScreen(summaries: summaries),
              type: TransitionType.sharedAxis,
              axis: SharedAxisTransitionType.vertical,
            );
          case '/call-logs':
            return AnimatedRoutes.createRoute(
              const CallLogsScreen(),
              type: TransitionType.sharedAxis,
              axis: SharedAxisTransitionType.horizontal,
            );
          case '/comprehensive-dashboard':
            return AnimatedRoutes.createRoute(
              const ComprehensiveDashboard(),
              type: TransitionType.fadeThrough,
            );
          case '/permission-request':
            return AnimatedRoutes.createRoute(
              PermissionRequestScreen(
                onPermissionsGranted: () {
                  Navigator.of(context).pop();
                },
              ),
              type: TransitionType.sharedAxis,
              axis: SharedAxisTransitionType.vertical,
            );
          case '/full-calendar':
            return AnimatedRoutes.scaleFromCenter(const FullCalendarScreen());
          // Removed live activity setup screen route
          case '/call-detail':
            final args = settings.arguments;
            Widget screen;
            if (args is CallData) {
              screen = CallDetailScreen(callData: args);
            } else {
              // Return dummy data for demo
              screen = CallDetailScreen(
                callData: CallData(
                  contactName: 'Demo Contact',
                  phoneNumber: '+91 98765 43210',
                  timestamp: DateTime.now().subtract(const Duration(hours: 2)),
                  duration: const Duration(minutes: 12, seconds: 34),
                  isIncoming: true,
                  hasRecording: true,
                  summary:
                      'This is a demo call summary showing how the AI processes and summarizes call content.',
                  keyPoints: [
                    'Discussed project timeline',
                    'Budget approval needed',
                    'Meeting scheduled for Friday'
                  ],
                  sentiment: 'Positive',
                  urgency: 'Medium',
                  category: 'Business',
                  priority: PriorityLevel.medium,
                  transcript: [
                    TranscriptMessage(
                      speaker: 'You',
                      text: 'Hello, how are you doing?',
                      timestamp: '0:00',
                      isUser: true,
                    ),
                    TranscriptMessage(
                      speaker: 'Contact',
                      text: 'Hi there! I\'m doing well, thanks for asking.',
                      timestamp: '0:05',
                      isUser: false,
                    ),
                  ],
                  actionItems: [
                    ActionItem(
                      id: '1',
                      title: 'Follow up on project status',
                      dueDate: 'Tomorrow',
                      isCompleted: false,
                    ),
                  ],
                ),
              );
            }
            return AnimatedRoutes.createRoute(
              screen,
              type: TransitionType.sharedAxis,
              axis: SharedAxisTransitionType.horizontal,
            );
          case '/notification-detail':
            final args = settings.arguments;
            Widget screen;
            if (args is NotificationData) {
              screen = NotificationDetailScreen(notificationData: args);
            } else if (args is SummaryItem) {
              // Convert SummaryItem to NotificationData
              final summaryItem = args;

              // Extract app name from title (format: "AppName - Title")
              final titleParts = summaryItem.title.split(' - ');
              final appName = titleParts.isNotEmpty ? titleParts[0] : 'Unknown';
              final actualTitle =
                  titleParts.length > 1 ? titleParts[1] : summaryItem.title;

              screen = NotificationDetailScreen(
                notificationData: NotificationData(
                  id: 'summary_${DateTime.now().millisecondsSinceEpoch}',
                  appName: appName,
                  appIcon: '',
                  title: actualTitle,
                  body: summaryItem.summary,
                  bigText: '',
                  subText: '',
                  category: _getCategoryFromAppName(appName),
                  timestamp:
                      DateTime.now().subtract(const Duration(minutes: 10)),
                  isRead: false,
                  priority: summaryItem.priority,
                  aiSummary: _generateAISummary(
                      appName, actualTitle, summaryItem.summary),
                  sentiment: 'Neutral',
                  urgency: _mapPriorityToUrgency(summaryItem.priority),
                  requiresAction:
                      _determineActionRequired(appName, summaryItem.summary),
                  containsPersonalInfo: _hasPersonalInfo(appName),
                  suggestedActions:
                      _generateSuggestedActions(appName, actualTitle),
                  relatedNotifications: [],
                ),
              );
            } else {
              // Default fallback for unknown data types
              screen = NotificationDetailScreen(
                notificationData: NotificationData(
                  id: 'fallback_1',
                  appName: 'Notification',
                  appIcon: '',
                  title: 'Notification Details',
                  body: 'This is a general notification.',
                  bigText: '',
                  subText: '',
                  category: 'General',
                  timestamp: DateTime.now(),
                  isRead: false,
                  priority: PriorityLevel.medium,
                  aiSummary: 'General notification received.',
                  sentiment: 'Neutral',
                  urgency: 'Medium',
                  requiresAction: false,
                  containsPersonalInfo: false,
                  suggestedActions: [],
                  relatedNotifications: [],
                ),
              );
            }
            return AnimatedRoutes.createRoute(
              screen,
              type: TransitionType.sharedAxis,
              axis: SharedAxisTransitionType.horizontal,
            );
          default:
            return MaterialPageRoute(
              builder: (context) => const SplashScreen(),
            );
        }
      },
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.0),
          ),
          child: child!,
        );
      },
    );
  }

  // Helper methods for SummaryItem to NotificationData conversion
  String _getCategoryFromAppName(String appName) {
    final appLower = appName.toLowerCase();

    // Social Media Apps
    if ([
      'whatsapp',
      'instagram',
      'facebook',
      'snapchat',
      'telegram',
      'signal',
      'discord',
      'twitter',
      'linkedin',
      'tiktok',
      'reddit'
    ].any((app) => appLower.contains(app))) {
      return 'Social';
    }

    // Payment Apps
    if ([
      'gpay',
      'google pay',
      'phonepe',
      'phone pe',
      'paytm',
      'bhim',
      'upi',
      'sbi',
      'hdfc',
      'icici',
      'axis',
      'kotak',
      'bank',
      'banking',
      'payment'
    ].any((app) => appLower.contains(app))) {
      return 'Financial';
    }

    // Email Apps
    if (['gmail', 'outlook', 'yahoo', 'email', 'mail']
        .any((app) => appLower.contains(app))) {
      return 'Productivity';
    }

    // Entertainment Apps
    if (['youtube', 'netflix', 'spotify', 'music', 'video', 'gaming']
        .any((app) => appLower.contains(app))) {
      return 'Entertainment';
    }

    // Shopping Apps
    if ([
      'amazon',
      'flipkart',
      'shopping',
      'myntra',
      'swiggy',
      'zomato',
      'uber',
      'ola'
    ].any((app) => appLower.contains(app))) {
      return 'Shopping';
    }

    return 'General';
  }

  String _generateAISummary(String appName, String title, String summary) {
    final appLower = appName.toLowerCase();

    if (['whatsapp', 'telegram', 'signal']
        .any((app) => appLower.contains(app))) {
      return '💬 Message received from $appName\n📱 Check for important communications\n🔔 Consider replying if urgent';
    } else if (['instagram', 'facebook', 'snapchat']
        .any((app) => appLower.contains(app))) {
      return '📱 Social media notification from $appName\n👥 Check for interactions or updates\n⏰ Review when convenient';
    } else if (['gpay', 'phonepe', 'paytm', 'bank']
        .any((app) => appLower.contains(app))) {
      return '💰 Financial notification from $appName\n💳 Review transaction details\n⚠️ Verify if legitimate';
    } else if (['gmail', 'outlook', 'email']
        .any((app) => appLower.contains(app))) {
      return '📧 Email received\n📋 Check for important correspondence\n🔍 Review subject and sender';
    }

    return '🔔 Notification from $appName\n📄 $summary\n💡 Review when convenient';
  }

  String _mapPriorityToUrgency(PriorityLevel priority) {
    switch (priority) {
      case PriorityLevel.urgent:
        return 'Critical';
      case PriorityLevel.high:
        return 'High';
      case PriorityLevel.medium:
        return 'Medium';
      case PriorityLevel.low:
        return 'Low';
    }
  }

  bool _determineActionRequired(String appName, String summary) {
    final appLower = appName.toLowerCase();
    final summaryLower = summary.toLowerCase();

    // Payment apps usually require action
    if ([
      'gpay',
      'phonepe',
      'paytm',
      'bank',
      'payment',
      'bill',
      'due'
    ].any((word) => appLower.contains(word) || summaryLower.contains(word))) {
      return true;
    }

    // Important keywords that suggest action is needed
    if ([
      'urgent',
      'action required',
      'due',
      'expires',
      'reminder',
      'verify',
      'confirm'
    ].any((word) => summaryLower.contains(word))) {
      return true;
    }

    return false;
  }

  bool _hasPersonalInfo(String appName) {
    final appLower = appName.toLowerCase();

    // Apps that typically contain personal information
    if ([
      'bank',
      'gpay',
      'phonepe',
      'paytm',
      'gmail',
      'email',
      'whatsapp',
      'telegram',
      'signal'
    ].any((app) => appLower.contains(app))) {
      return true;
    }

    return false;
  }

  List<SuggestedAction> _generateSuggestedActions(
      String appName, String title) {
    final appLower = appName.toLowerCase();
    List<SuggestedAction> actions = [];

    // Social Media Actions
    if (['whatsapp', 'telegram', 'signal']
        .any((app) => appLower.contains(app))) {
      actions.add(SuggestedAction(
          id: '1',
          title: 'Reply to Message',
          icon: Icons.reply,
          description: 'Open $appName to reply'));
      actions.add(SuggestedAction(
          id: '2',
          title: 'Mark as Read',
          icon: Icons.mark_chat_read,
          description: 'Mark message as read'));
    } else if (['instagram', 'facebook', 'snapchat']
        .any((app) => appLower.contains(app))) {
      actions.add(SuggestedAction(
          id: '1',
          title: 'View in App',
          icon: Icons.open_in_new,
          description: 'Open $appName'));
      actions.add(SuggestedAction(
          id: '2',
          title: 'Like/React',
          icon: Icons.favorite,
          description: 'React to content'));
    } else if (['gpay', 'phonepe', 'paytm']
        .any((app) => appLower.contains(app))) {
      actions.add(SuggestedAction(
          id: '1',
          title: 'Open Payment App',
          icon: Icons.payment,
          description: 'Open $appName'));
      actions.add(SuggestedAction(
          id: '2',
          title: 'View Transaction',
          icon: Icons.receipt,
          description: 'Check transaction details'));
    } else if (['gmail', 'outlook', 'email']
        .any((app) => appLower.contains(app))) {
      actions.add(SuggestedAction(
          id: '1',
          title: 'Read Email',
          icon: Icons.email,
          description: 'Open email'));
      actions.add(SuggestedAction(
          id: '2',
          title: 'Reply',
          icon: Icons.reply,
          description: 'Reply to email'));
    }

    // Default actions
    if (actions.isEmpty) {
      actions.add(SuggestedAction(
          id: '1',
          title: 'Open App',
          icon: Icons.open_in_new,
          description: 'Open $appName'));
    }

    return actions;
  }
}
