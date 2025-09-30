// lib/widgets/onboarding_controller.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/onboarding_service.dart';

class OnboardingController extends ConsumerWidget {
  final Widget child;

  const OnboardingController({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize onboarding service when app starts
    ref.listen(onboardingServiceProvider, (previous, next) {
      // Handle onboarding state changes if needed
      if (next.error != null &&
          (previous == null || previous.error != next.error)) {
        // Show error snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(next.error!)),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    return child;
  }
}
