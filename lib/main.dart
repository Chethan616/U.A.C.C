import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'models/enums.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/call_detail_screen.dart';
import 'screens/notification_detail_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/register_screen.dart';
import 'widgets/app_initializer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: AppColors.base,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.surface,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const UACCApp());
}

class UACCApp extends StatelessWidget {
  const UACCApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UACC - Universal AI Call Companion',
      theme: appTheme,
      debugShowCheckedModeBanner: false,
      home: const AppInitializer(),
      routes: {
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/notifications': (context) => const NotificationsScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/call-detail': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is CallData) {
            return CallDetailScreen(callData: args);
          }
          // Return dummy data for demo
          return CallDetailScreen(
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
        },
        '/notification-detail': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is NotificationData) {
            return NotificationDetailScreen(notificationData: args);
          }
          // Return dummy data for demo
          return NotificationDetailScreen(
            notificationData: NotificationData(
              id: 'demo_1',
              appName: 'GPay',
              appIcon: '',
              title: 'Payment Reminder',
              body: 'Your electricity bill of ₹2,450 is due tomorrow.',
              bigText: 'Pay now to avoid late charges. Due date: Tomorrow',
              category: 'Financial',
              timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
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
        },
      },
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
          child: child!,
        );
      },
    );
  }
}
