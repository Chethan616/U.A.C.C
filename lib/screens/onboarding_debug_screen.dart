// lib/screens/onboarding_debug_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/onboarding_service.dart';
import 'modern_onboarding_screen.dart';

class OnboardingDebugScreen extends ConsumerWidget {
  const OnboardingDebugScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingState = ref.watch(onboardingServiceProvider);
    final hasCompletedAsync = ref.watch(hasCompletedOnboardingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Onboarding Debug'),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Onboarding Status',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusRow('Current Step',
                        '${onboardingState.currentStepIndex + 1} / ${onboardingState.totalSteps}'),
                    const SizedBox(height: 8),
                    _buildStatusRow(
                        'Current Step ID', onboardingState.currentStep.id),
                    const SizedBox(height: 8),
                    _buildStatusRow(
                        'Is Loading', onboardingState.isLoading.toString()),
                    const SizedBox(height: 8),
                    _buildStatusRow('Error', onboardingState.error ?? 'None'),
                    const SizedBox(height: 8),
                    hasCompletedAsync.when(
                      data: (completed) =>
                          _buildStatusRow('Completed', completed.toString()),
                      loading: () => _buildStatusRow('Completed', 'Loading...'),
                      error: (error, stack) =>
                          _buildStatusRow('Completed', 'Error: $error'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Permissions Status',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusRow('Total Permissions',
                        onboardingState.getTotalPermissionsCount().toString()),
                    const SizedBox(height: 8),
                    _buildStatusRow(
                        'Granted Permissions',
                        onboardingState
                            .getGrantedPermissionsCount()
                            .toString()),
                    const SizedBox(height: 16),
                    ...onboardingState.permissionStatuses.entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: _buildStatusRow(
                          entry.key.toString().split('.').last,
                          entry.value.toString().split('.').last,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            // Action buttons
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const ModernOnboardingScreen(isForNewUser: true),
                        ),
                      );
                    },
                    child: const Text('Test New User Onboarding'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const ModernOnboardingScreen(isForNewUser: false),
                        ),
                      );
                    },
                    child: const Text('Test Existing User Onboarding'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () async {
                      final service =
                          ref.read(onboardingServiceProvider.notifier);
                      await service.resetOnboarding();
                    },
                    child: const Text('Reset Onboarding'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontFamily: 'monospace'),
          ),
        ),
      ],
    );
  }
}
