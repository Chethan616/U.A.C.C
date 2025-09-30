// lib/services/onboarding_service.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import '../models/onboarding_models.dart';

class OnboardingService extends StateNotifier<OnboardingState> {
  static const MethodChannel _channel = MethodChannel('uacc/permissions');
  final Map<SpecialPermissionType, bool> _specialPermissionStatuses = {};

  OnboardingService()
      : super(OnboardingState(steps: OnboardingData.defaultSteps)) {
    _initializePermissionStatuses();
  }

  Future<void> _initializePermissionStatuses() async {
    final Map<Permission, PermissionStatus> statuses = {};

    // Check current permission statuses
    for (final step in state.steps) {
      if (step.permissions != null) {
        for (final permission in step.permissions!) {
          if (permission.requiresSystemSettings) {
            // Handle special permissions
            final isGranted = await _checkSpecialPermission(
                permission.specialPermissionType!);
            _specialPermissionStatuses[permission.specialPermissionType!] =
                isGranted;
            statuses[permission.permission] =
                isGranted ? PermissionStatus.granted : PermissionStatus.denied;
          } else {
            // Handle regular permissions
            statuses[permission.permission] =
                await permission.permission.status;
          }
        }
      }
    }

    state = state.copyWith(permissionStatuses: statuses);
  }

  Future<void> initializeForNewUser() async {
    final steps = OnboardingData.getStepsForNewUser();
    state = state.copyWith(
      steps: steps,
      currentStepIndex: 0,
      isCompleted: false,
    );
    await _initializePermissionStatuses();
  }

  Future<void> initializeForExistingUser() async {
    final steps = OnboardingData.getStepsForExistingUser();
    state = state.copyWith(
      steps: steps,
      currentStepIndex: 0,
      isCompleted: false,
    );
    await _initializePermissionStatuses();
  }

  void nextStep() {
    if (!state.isLastStep) {
      final newIndex = state.currentStepIndex + 1;
      final newCompleted = Map<String, bool>.from(state.completedSteps);
      newCompleted[state.currentStep.id] = true;

      state = state.copyWith(
        currentStepIndex: newIndex,
        completedSteps: newCompleted,
      );
    }
  }

  void previousStep() {
    if (!state.isFirstStep) {
      state = state.copyWith(
        currentStepIndex: state.currentStepIndex - 1,
      );
    }
  }

  void goToStep(int index) {
    if (index >= 0 && index < state.totalSteps) {
      state = state.copyWith(currentStepIndex: index);
    }
  }

  Future<bool> _checkSpecialPermission(SpecialPermissionType type) async {
    try {
      switch (type) {
        case SpecialPermissionType.notificationListener:
          return await _channel
                  .invokeMethod('checkNotificationListenerAccess') ??
              false;
        case SpecialPermissionType.accessibilityService:
          return await _channel
                  .invokeMethod('checkAccessibilityServiceEnabled') ??
              false;
        case SpecialPermissionType.deviceAdmin:
          return await _channel.invokeMethod('checkDeviceAdminEnabled') ??
              false;
      }
    } catch (e) {
      print('Error checking special permission $type: $e');
      return false;
    }
  }

  Future<bool> _requestSpecialPermission(SpecialPermissionType type) async {
    try {
      switch (type) {
        case SpecialPermissionType.notificationListener:
          await _channel.invokeMethod('openNotificationListenerSettings');
          break;
        case SpecialPermissionType.accessibilityService:
          await _channel.invokeMethod('openAccessibilitySettings');
          break;
        case SpecialPermissionType.deviceAdmin:
          await _channel.invokeMethod('openDeviceAdminSettings');
          break;
      }
      // Wait a bit and then check again
      await Future.delayed(const Duration(seconds: 1));
      return await _checkSpecialPermission(type);
    } catch (e) {
      print('Error requesting special permission $type: $e');
      return false;
    }
  }

  Future<bool> requestOnboardingPermission(
      OnboardingPermission onboardingPermission) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      PermissionStatus status;
      if (onboardingPermission.requiresSystemSettings) {
        // Handle special permissions
        final granted = await _requestSpecialPermission(
            onboardingPermission.specialPermissionType!);
        status = granted ? PermissionStatus.granted : PermissionStatus.denied;
        _specialPermissionStatuses[
            onboardingPermission.specialPermissionType!] = granted;
      } else {
        // Handle regular permissions
        status = await onboardingPermission.permission.request();
      }

      final newStatuses =
          Map<Permission, PermissionStatus>.from(state.permissionStatuses);
      newStatuses[onboardingPermission.permission] = status;

      state = state.copyWith(
        permissionStatuses: newStatuses,
        isLoading: false,
      );

      return status == PermissionStatus.granted;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to request permission: ${e.toString()}',
      );
      return false;
    }
  }

  Future<bool> requestPermission(Permission permission) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Find the permission in our steps to check if it's special
      OnboardingPermission? targetPermission;
      for (final step in state.steps) {
        if (step.permissions != null) {
          targetPermission = step.permissions!.firstWhere(
            (p) => p.permission == permission,
            orElse: () => step.permissions!.first,
          );
          if (targetPermission.permission == permission) break;
        }
      }

      PermissionStatus status;
      if (targetPermission?.requiresSystemSettings == true) {
        // Handle special permissions
        final granted = await _requestSpecialPermission(
            targetPermission!.specialPermissionType!);
        status = granted ? PermissionStatus.granted : PermissionStatus.denied;
        _specialPermissionStatuses[targetPermission.specialPermissionType!] =
            granted;
      } else {
        // Handle regular permissions
        status = await permission.request();
      }

      final newStatuses =
          Map<Permission, PermissionStatus>.from(state.permissionStatuses);
      newStatuses[permission] = status;

      state = state.copyWith(
        permissionStatuses: newStatuses,
        isLoading: false,
      );

      return status == PermissionStatus.granted;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to request permission: ${e.toString()}',
      );
      return false;
    }
  }

  Future<void> requestAllRequiredPermissions() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final requiredPermissions = <Permission>[];

      for (final step in state.steps) {
        if (step.permissions != null) {
          for (final permission in step.permissions!) {
            if (permission.isRequired) {
              requiredPermissions.add(permission.permission);
            }
          }
        }
      }

      final Map<Permission, PermissionStatus> newStatuses =
          Map<Permission, PermissionStatus>.from(state.permissionStatuses);

      for (final permission in requiredPermissions) {
        // Find the permission details
        OnboardingPermission? targetPermission;
        for (final step in state.steps) {
          if (step.permissions != null) {
            try {
              targetPermission = step.permissions!.firstWhere(
                (p) => p.permission == permission,
              );
              break;
            } catch (e) {
              // Permission not found in this step
            }
          }
        }

        PermissionStatus status;
        if (targetPermission?.requiresSystemSettings == true) {
          final granted = await _requestSpecialPermission(
              targetPermission!.specialPermissionType!);
          status = granted ? PermissionStatus.granted : PermissionStatus.denied;
          _specialPermissionStatuses[targetPermission.specialPermissionType!] =
              granted;
        } else {
          status = await permission.request();
        }
        newStatuses[permission] = status;
      }

      state = state.copyWith(
        permissionStatuses: newStatuses,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to request required permissions: ${e.toString()}',
      );
    }
  }

  Future<void> requestAllPermissions() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final allPermissions = <Permission>[];

      for (final step in state.steps) {
        if (step.permissions != null) {
          for (final permission in step.permissions!) {
            if (!allPermissions.contains(permission.permission)) {
              allPermissions.add(permission.permission);
            }
          }
        }
      }

      final Map<Permission, PermissionStatus> newStatuses =
          Map<Permission, PermissionStatus>.from(state.permissionStatuses);

      for (final permission in allPermissions) {
        // Find the permission details
        OnboardingPermission? targetPermission;
        for (final step in state.steps) {
          if (step.permissions != null) {
            try {
              targetPermission = step.permissions!.firstWhere(
                (p) => p.permission == permission,
              );
              break;
            } catch (e) {
              // Permission not found in this step
            }
          }
        }

        PermissionStatus status;
        if (targetPermission?.requiresSystemSettings == true) {
          final granted = await _requestSpecialPermission(
              targetPermission!.specialPermissionType!);
          status = granted ? PermissionStatus.granted : PermissionStatus.denied;
          _specialPermissionStatuses[targetPermission.specialPermissionType!] =
              granted;
        } else {
          status = await permission.request();
        }
        newStatuses[permission] = status;
      }

      state = state.copyWith(
        permissionStatuses: newStatuses,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to request permissions: ${e.toString()}',
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  Future<void> completeOnboarding() async {
    // Mark onboarding as completed
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);

    final newCompleted = Map<String, bool>.from(state.completedSteps);
    newCompleted[state.currentStep.id] = true;

    state = state.copyWith(
      isCompleted: true,
      completedSteps: newCompleted,
    );
  }

  Future<bool> hasCompletedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_completed') ?? false;
  }

  Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', false);

    state = OnboardingState(steps: OnboardingData.defaultSteps);
    await _initializePermissionStatuses();
  }

  // Helper methods
  bool areRequiredPermissionsGranted() {
    for (final step in state.steps) {
      if (step.permissions != null) {
        for (final permission in step.permissions!) {
          if (permission.isRequired) {
            final status = state.permissionStatuses[permission.permission];
            if (status != PermissionStatus.granted) {
              return false;
            }
          }
        }
      }
    }
    return true;
  }

  int getGrantedPermissionsCount() {
    int count = 0;
    for (final status in state.permissionStatuses.values) {
      if (status == PermissionStatus.granted) count++;
    }
    return count;
  }

  int getTotalPermissionsCount() {
    final allPermissions = <Permission>{};
    for (final step in state.steps) {
      if (step.permissions != null) {
        for (final permission in step.permissions!) {
          allPermissions.add(permission.permission);
        }
      }
    }
    return allPermissions.length;
  }
}

// Provider
final onboardingServiceProvider =
    StateNotifierProvider<OnboardingService, OnboardingState>(
  (ref) => OnboardingService(),
);

// Additional helper providers
final hasCompletedOnboardingProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(onboardingServiceProvider.notifier);
  return await service.hasCompletedOnboarding();
});

final requiredPermissionsGrantedProvider = Provider<bool>((ref) {
  ref.watch(onboardingServiceProvider); // Watch for state changes
  final service = ref.watch(onboardingServiceProvider.notifier);
  return service.areRequiredPermissionsGranted();
});
