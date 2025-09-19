// lib/services/permissions_service.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum PermissionType {
  notifications,
  phone,
  microphone,
  contacts,
  calendar,
  storage,
  camera,
}

extension PermissionTypeExtension on PermissionType {
  String get displayName {
    switch (this) {
      case PermissionType.notifications:
        return 'Notifications';
      case PermissionType.phone:
        return 'Phone & Calls';
      case PermissionType.microphone:
        return 'Microphone';
      case PermissionType.contacts:
        return 'Contacts';
      case PermissionType.calendar:
        return 'Calendar';
      case PermissionType.storage:
        return 'Storage';
      case PermissionType.camera:
        return 'Camera';
    }
  }

  String get description {
    switch (this) {
      case PermissionType.notifications:
        return 'Send notifications for calls, reminders, and important updates';
      case PermissionType.phone:
        return 'Access phone calls and manage call-related features';
      case PermissionType.microphone:
        return 'Record audio during calls for transcription and AI analysis';
      case PermissionType.contacts:
        return 'Access contacts to identify callers and manage call history';
      case PermissionType.calendar:
        return 'Create calendar events and schedule reminders from calls';
      case PermissionType.storage:
        return 'Store call recordings, transcripts, and app data locally';
      case PermissionType.camera:
        return 'Take photos for profile pictures and document sharing';
    }
  }

  IconData get icon {
    switch (this) {
      case PermissionType.notifications:
        return Icons.notifications_outlined;
      case PermissionType.phone:
        return Icons.call_outlined;
      case PermissionType.microphone:
        return Icons.mic_outlined;
      case PermissionType.contacts:
        return Icons.contacts_outlined;
      case PermissionType.calendar:
        return Icons.calendar_today_outlined;
      case PermissionType.storage:
        return Icons.storage_outlined;
      case PermissionType.camera:
        return Icons.camera_alt_outlined;
    }
  }

  Permission get permission {
    switch (this) {
      case PermissionType.notifications:
        return Permission.notification;
      case PermissionType.phone:
        return Permission.phone;
      case PermissionType.microphone:
        return Permission.microphone;
      case PermissionType.contacts:
        return Permission.contacts;
      case PermissionType.calendar:
        return Permission.calendarFullAccess;
      case PermissionType.storage:
        return Permission.storage;
      case PermissionType.camera:
        return Permission.camera;
    }
  }

  Color get color {
    switch (this) {
      case PermissionType.notifications:
        return const Color(0xFF2196F3);
      case PermissionType.phone:
        return const Color(0xFF4CAF50);
      case PermissionType.microphone:
        return const Color(0xFFFF9800);
      case PermissionType.contacts:
        return const Color(0xFF9C27B0);
      case PermissionType.calendar:
        return const Color(0xFFF44336);
      case PermissionType.storage:
        return const Color(0xFF607D8B);
      case PermissionType.camera:
        return const Color(0xFF795548);
    }
  }

  bool get isRequired {
    switch (this) {
      case PermissionType.notifications:
      case PermissionType.phone:
      case PermissionType.microphone:
        return true;
      case PermissionType.contacts:
      case PermissionType.calendar:
      case PermissionType.storage:
      case PermissionType.camera:
        return false;
    }
  }
}

class PermissionState {
  final Map<PermissionType, PermissionStatus> permissions;
  final bool isLoading;
  final String? error;
  final bool onboardingCompleted;

  PermissionState({
    this.permissions = const {},
    this.isLoading = false,
    this.error,
    this.onboardingCompleted = false,
  });

  PermissionState copyWith({
    Map<PermissionType, PermissionStatus>? permissions,
    bool? isLoading,
    String? error,
    bool? onboardingCompleted,
  }) {
    return PermissionState(
      permissions: permissions ?? this.permissions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }

  bool get hasAllRequiredPermissions {
    final requiredPermissions =
        PermissionType.values.where((p) => p.isRequired);
    return requiredPermissions.every(
        (permission) => permissions[permission] == PermissionStatus.granted);
  }

  int get grantedCount {
    return permissions.values
        .where((status) => status == PermissionStatus.granted)
        .length;
  }

  int get totalCount => PermissionType.values.length;

  double get progress => totalCount > 0 ? grantedCount / totalCount : 0.0;
}

class PermissionsService extends StateNotifier<PermissionState> {
  PermissionsService() : super(PermissionState()) {
    _loadOnboardingStatus();
    checkAllPermissions();
  }

  static const String _onboardingKey = 'permissions_onboarding_completed';

  Future<void> _loadOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getBool(_onboardingKey) ?? false;
    state = state.copyWith(onboardingCompleted: completed);
  }

  Future<void> _saveOnboardingStatus(bool completed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, completed);
    state = state.copyWith(onboardingCompleted: completed);
  }

  Future<void> checkAllPermissions() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final Map<PermissionType, PermissionStatus> permissionStatuses = {};

      for (final permissionType in PermissionType.values) {
        final status = await permissionType.permission.status;
        permissionStatuses[permissionType] = status;
      }

      state = state.copyWith(
        permissions: permissionStatuses,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to check permissions: ${e.toString()}',
      );
    }
  }

  Future<PermissionStatus> requestPermission(
      PermissionType permissionType) async {
    try {
      final status = await permissionType.permission.request();

      final updatedPermissions =
          Map<PermissionType, PermissionStatus>.from(state.permissions);
      updatedPermissions[permissionType] = status;

      state = state.copyWith(permissions: updatedPermissions);

      return status;
    } catch (e) {
      state = state.copyWith(
          error: 'Failed to request ${permissionType.displayName} permission');
      return PermissionStatus.denied;
    }
  }

  Future<Map<PermissionType, PermissionStatus>> requestMultiplePermissions(
    List<PermissionType> permissionTypes,
  ) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final permissions = permissionTypes.map((e) => e.permission).toList();
      final statuses = await permissions.request();

      final Map<PermissionType, PermissionStatus> results = {};
      for (int i = 0; i < permissionTypes.length; i++) {
        results[permissionTypes[i]] =
            statuses[permissions[i]] ?? PermissionStatus.denied;
      }

      final updatedPermissions =
          Map<PermissionType, PermissionStatus>.from(state.permissions);
      updatedPermissions.addAll(results);

      state = state.copyWith(
        permissions: updatedPermissions,
        isLoading: false,
      );

      return results;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to request permissions: ${e.toString()}',
      );
      return {};
    }
  }

  Future<void> requestAllRequiredPermissions() async {
    final requiredPermissions =
        PermissionType.values.where((p) => p.isRequired).toList();
    await requestMultiplePermissions(requiredPermissions);
  }

  Future<void> requestAllPermissions() async {
    await requestMultiplePermissions(PermissionType.values);
  }

  Future<void> openSettings() async {
    await openAppSettings();
  }

  Future<void> completeOnboarding() async {
    await _saveOnboardingStatus(true);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  PermissionStatus getPermissionStatus(PermissionType permissionType) {
    return state.permissions[permissionType] ?? PermissionStatus.denied;
  }

  bool isPermissionGranted(PermissionType permissionType) {
    return getPermissionStatus(permissionType) == PermissionStatus.granted;
  }

  bool areRequiredPermissionsGranted() {
    return state.hasAllRequiredPermissions;
  }
}

// Riverpod providers
final permissionsServiceProvider =
    StateNotifierProvider<PermissionsService, PermissionState>((ref) {
  return PermissionsService();
});

final hasRequiredPermissionsProvider = Provider<bool>((ref) {
  final permissionState = ref.watch(permissionsServiceProvider);
  return permissionState.hasAllRequiredPermissions;
});

final onboardingCompletedProvider = Provider<bool>((ref) {
  final permissionState = ref.watch(permissionsServiceProvider);
  return permissionState.onboardingCompleted;
});
