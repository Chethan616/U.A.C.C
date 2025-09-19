import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../screens/onboarding_screen.dart';
import '../screens/login_screen.dart';
import '../screens/home_screen.dart';
import '../providers/app_state_provider.dart';
import '../widgets/loading_widget.dart';

class AppInitializer extends ConsumerWidget {
  const AppInitializer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appInitialization = ref.watch(appInitializationProvider);

    switch (appInitialization.state) {
      case AppInitializationState.initializing:
        return const Scaffold(
          body: Center(
            child: LoadingWidget(
              message: 'Initializing UACC...',
              size: 32.0,
            ),
          ),
        );

      case AppInitializationState.requiresOnboarding:
        return const OnboardingScreen();

      case AppInitializationState.requiresAuth:
        return const LoginScreen();

      case AppInitializationState.authenticated:
        return const HomeScreen();

      case AppInitializationState.error:
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  'Initialization Error',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  appInitialization.error ?? 'Unknown error occurred',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () {
                    ref.read(appInitializationProvider.notifier).retry();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
    }
  }
}
