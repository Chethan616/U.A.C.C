import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../screens/login_screen.dart';
import '../screens/home_screen.dart';
import '../screens/profile_completion_screen.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stackTrace) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Authentication Error',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  ref.invalidate(currentUserProvider);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (user) {
        if (user != null) {
          // Check if user profile is complete
          final userProfileAsync = ref.watch(currentUserProfileProvider);
          return userProfileAsync.when(
            loading: () => const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, stackTrace) => const HomeScreen(),
            data: (userProfile) {
              if (userProfile == null || !userProfile.profileCompleted) {
                // Profile not complete, show completion screen
                return const ProfileCompletionScreen();
              } else {
                // Profile complete, show home screen
                return const HomeScreen();
              }
            },
          );
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
