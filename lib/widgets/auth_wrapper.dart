import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/onboarding_service.dart';
import '../services/app_state_service.dart';

import '../screens/login_screen.dart';
import '../screens/home_screen.dart';
import '../screens/profile_completion_screen.dart';
import '../screens/modern_onboarding_screen.dart';

class AuthWrapper extends ConsumerStatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  String? _lastUserId;

  @override
  void initState() {
    super.initState();
    _checkForAccountSwitch();
  }

  Future<void> _checkForAccountSwitch() async {
    final currentUser = ref.read(authServiceProvider).currentUser;
    final storedUserId = await AppStateService.instance.getLastUserId();

    if (currentUser != null &&
        storedUserId != null &&
        currentUser.uid != storedUserId) {
      // Account has switched, clear cached data
      await AppStateService.instance.clearAuthenticationState();
      // Invalidate all providers to refresh with new user data
      ref.invalidate(currentUserProvider);
      ref.invalidate(currentUserProfileProvider);
      ref.invalidate(hasCompletedOnboardingProvider);
    }

    _lastUserId = currentUser?.uid;
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    // Check for account switching on each build
    ref.listen(currentUserProvider, (previous, next) {
      next.whenData((user) async {
        if (_lastUserId != null && user?.uid != _lastUserId && user != null) {
          // User has changed, clear state and refresh
          await AppStateService.instance.clearAuthenticationState();
          await AppStateService.instance.setUserLoggedIn(true, user.uid);
          ref.invalidate(currentUserProfileProvider);
          ref.invalidate(hasCompletedOnboardingProvider);

          // Firebase export system will only initialize when user manually triggers backup
        } else if (user != null && _lastUserId == null) {
          // First time login - Firebase export system will only initialize when user manually triggers backup
        }
        _lastUserId = user?.uid;
      });
    });

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
                  ref.invalidate(currentUserProfileProvider);
                  ref.invalidate(hasCompletedOnboardingProvider);
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
          final hasCompletedOnboardingAsync =
              ref.watch(hasCompletedOnboardingProvider);

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
                // Profile complete, check onboarding status
                return hasCompletedOnboardingAsync.when(
                  loading: () => const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (error, stackTrace) => const HomeScreen(),
                  data: (hasCompletedOnboarding) {
                    if (!hasCompletedOnboarding) {
                      // Show onboarding for existing users (shorter version)
                      return const ModernOnboardingScreen(isForNewUser: false);
                    } else {
                      // Onboarding complete, show home screen
                      return const HomeScreen();
                    }
                  },
                );
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
