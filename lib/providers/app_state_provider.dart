import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/app_state_service.dart';

// App initialization state
enum AppInitializationState {
  initializing,
  requiresOnboarding,
  requiresAuth,
  authenticated,
  error,
}

class AppInitializationData {
  final AppInitializationState state;
  final String? error;
  final bool isFirstLaunch;
  final bool onboardingCompleted;
  final User? user;

  const AppInitializationData({
    required this.state,
    this.error,
    this.isFirstLaunch = false,
    this.onboardingCompleted = false,
    this.user,
  });

  AppInitializationData copyWith({
    AppInitializationState? state,
    String? error,
    bool? isFirstLaunch,
    bool? onboardingCompleted,
    User? user,
  }) {
    return AppInitializationData(
      state: state ?? this.state,
      error: error ?? this.error,
      isFirstLaunch: isFirstLaunch ?? this.isFirstLaunch,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      user: user ?? this.user,
    );
  }
}

// Auth Service Provider
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// App State Service Provider
final appStateServiceProvider =
    Provider<AppStateService>((ref) => AppStateService.instance);

// Auth State Stream Provider
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

// App Initialization Provider
final appInitializationProvider =
    StateNotifierProvider<AppInitializationNotifier, AppInitializationData>(
        (ref) {
  return AppInitializationNotifier(ref);
});

class AppInitializationNotifier extends StateNotifier<AppInitializationData> {
  final Ref ref;

  AppInitializationNotifier(this.ref)
      : super(const AppInitializationData(
            state: AppInitializationState.initializing)) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      state = const AppInitializationData(
          state: AppInitializationState.initializing);

      // Initialize app state service first
      final appStateService = ref.read(appStateServiceProvider);
      await appStateService.initialize();

      // Check if this is first launch or onboarding needed
      final isFirstLaunch = await appStateService.isFirstLaunch();
      final onboardingCompleted = await appStateService.isOnboardingCompleted();

      if (isFirstLaunch || !onboardingCompleted) {
        state = AppInitializationData(
          state: AppInitializationState.requiresOnboarding,
          isFirstLaunch: isFirstLaunch,
          onboardingCompleted: onboardingCompleted,
        );
        return;
      }

      // Listen to auth state changes
      ref.listen(authStateProvider, (previous, next) {
        next.when(
          data: (user) {
            if (user != null) {
              state = state.copyWith(
                state: AppInitializationState.authenticated,
                user: user,
              );
            } else {
              state = state.copyWith(
                state: AppInitializationState.requiresAuth,
                user: null,
              );
            }
          },
          loading: () {
            // Keep current state while loading
          },
          error: (error, stack) {
            state = state.copyWith(
              state: AppInitializationState.error,
              error: error.toString(),
            );
          },
        );
      });

      // Get initial auth state
      final authState = ref.read(authStateProvider);
      authState.when(
        data: (user) {
          if (user != null) {
            state = AppInitializationData(
              state: AppInitializationState.authenticated,
              isFirstLaunch: isFirstLaunch,
              onboardingCompleted: onboardingCompleted,
              user: user,
            );
          } else {
            state = AppInitializationData(
              state: AppInitializationState.requiresAuth,
              isFirstLaunch: isFirstLaunch,
              onboardingCompleted: onboardingCompleted,
            );
          }
        },
        loading: () {
          // Wait for auth state
        },
        error: (error, stack) {
          state = AppInitializationData(
            state: AppInitializationState.error,
            error: error.toString(),
            isFirstLaunch: isFirstLaunch,
            onboardingCompleted: onboardingCompleted,
          );
        },
      );
    } catch (e) {
      state = AppInitializationData(
        state: AppInitializationState.error,
        error: e.toString(),
      );
    }
  }

  void completeOnboarding() async {
    try {
      final appStateService = ref.read(appStateServiceProvider);
      await appStateService.setOnboardingCompleted();
      await appStateService.setFirstLaunchCompleted();

      // Re-initialize to check auth state
      _initialize();
    } catch (e) {
      state = state.copyWith(
        state: AppInitializationState.error,
        error: e.toString(),
      );
    }
  }

  void retry() {
    _initialize();
  }
}

// Current user provider
final currentUserProvider = Provider<User?>((ref) {
  final appInit = ref.watch(appInitializationProvider);
  return appInit.user;
});

// Helper providers for specific states
final isAuthenticatedProvider = Provider<bool>((ref) {
  final appInit = ref.watch(appInitializationProvider);
  return appInit.state == AppInitializationState.authenticated;
});

final requiresOnboardingProvider = Provider<bool>((ref) {
  final appInit = ref.watch(appInitializationProvider);
  return appInit.state == AppInitializationState.requiresOnboarding;
});

final requiresAuthProvider = Provider<bool>((ref) {
  final appInit = ref.watch(appInitializationProvider);
  return appInit.state == AppInitializationState.requiresAuth;
});

final isInitializingProvider = Provider<bool>((ref) {
  final appInit = ref.watch(appInitializationProvider);
  return appInit.state == AppInitializationState.initializing;
});
