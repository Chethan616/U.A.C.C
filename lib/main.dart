import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animations/animations.dart';
import 'firebase_options.dart';
import 'theme/theme_provider.dart';
import 'models/enums.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/call_detail_screen.dart';
import 'screens/notification_detail_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/call_logs_screen.dart';
import 'screens/comprehensive_dashboard.dart';
import 'screens/permission_request_screen.dart';
import 'screens/register_screen.dart';
import 'widgets/app_initializer.dart';
import 'screens/full_calendar_screen.dart';
import 'utils/animated_routes.dart';
import 'services/api_config_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize API keys
  await ApiConfigService.initializeApiKeys();

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
      child: const UACCApp(),
    ),
  );
}

class UACCApp extends ConsumerWidget {
  const UACCApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeProvider);
    final systemBrightness = MediaQuery.platformBrightnessOf(context);
    final theme = AppThemes.getTheme(currentTheme, systemBrightness);

    return MaterialApp(
      title: 'UACC - Universal AI Call Companion',
      theme: theme,
      debugShowCheckedModeBanner: false,
      home: const AppInitializer(),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/onboarding':
            return AnimatedRoutes.createRoute(
              const OnboardingScreen(),
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
            } else {
              // Return dummy data for demo
              screen = NotificationDetailScreen(
                notificationData: NotificationData(
                  id: 'demo_1',
                  appName: 'GPay',
                  appIcon: '',
                  title: 'Payment Reminder',
                  body: 'Your electricity bill of ₹2,450 is due tomorrow.',
                  bigText: 'Pay now to avoid late charges. Due date: Tomorrow',
                  category: 'Financial',
                  timestamp:
                      DateTime.now().subtract(const Duration(minutes: 30)),
                  isRead: false,
                  priority: PriorityLevel.medium,
                  aiSummary:
                      'This is a payment reminder for an electricity bill that\'s due soon.',
                  sentiment: 'Neutral',
                  urgency: 'Medium',
                  requiresAction: true,
                  containsPersonalInfo: true,
                  suggestedActions: [
                    SuggestedAction(
                      id: '1',
                      title: 'Pay Bill Now',
                      icon: Icons.payment,
                      description: 'Open GPay to pay the electricity bill',
                    ),
                  ],
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
              builder: (context) => const AppInitializer(),
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
}
