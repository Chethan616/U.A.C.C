// lib/models/onboarding_models.dart
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

enum OnboardingStepType {
  welcome,
  features,
  permissions,
  completion,
}

enum SpecialPermissionType {
  notificationListener,
  accessibilityService,
  deviceAdmin,
}

class OnboardingStep {
  final String id;
  final OnboardingStepType type;
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color? primaryColor;
  final List<OnboardingFeature>? features;
  final List<OnboardingPermission>? permissions;
  final String? imagePath;
  final String? animationAsset;
  final bool isSkippable;

  const OnboardingStep({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    this.primaryColor,
    this.features,
    this.permissions,
    this.imagePath,
    this.animationAsset,
    this.isSkippable = false,
  });
}

class OnboardingFeature {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool isHighlighted;

  const OnboardingFeature({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.isHighlighted = false,
  });
}

class OnboardingPermission {
  final Permission permission;
  final String title;
  final String description;
  final String reason;
  final IconData icon;
  final Color color;
  final bool isRequired;
  final PermissionStatus? currentStatus;
  final SpecialPermissionType? specialPermissionType;
  final bool requiresSystemSettings;

  const OnboardingPermission({
    required this.permission,
    required this.title,
    required this.description,
    required this.reason,
    required this.icon,
    required this.color,
    this.isRequired = false,
    this.currentStatus,
    this.specialPermissionType,
    this.requiresSystemSettings = false,
  });

  // Factory constructor for special permissions
  const OnboardingPermission.special({
    required this.title,
    required this.description,
    required this.reason,
    required this.icon,
    required this.color,
    required this.specialPermissionType,
    this.isRequired = false,
    this.currentStatus,
  })  : permission = Permission.unknown,
        requiresSystemSettings = true;
}

class OnboardingState {
  final int currentStepIndex;
  final List<OnboardingStep> steps;
  final Map<String, bool> completedSteps;
  final Map<Permission, PermissionStatus> permissionStatuses;
  final bool isLoading;
  final String? error;
  final bool isCompleted;

  const OnboardingState({
    this.currentStepIndex = 0,
    required this.steps,
    this.completedSteps = const {},
    this.permissionStatuses = const {},
    this.isLoading = false,
    this.error,
    this.isCompleted = false,
  });

  OnboardingState copyWith({
    int? currentStepIndex,
    List<OnboardingStep>? steps,
    Map<String, bool>? completedSteps,
    Map<Permission, PermissionStatus>? permissionStatuses,
    bool? isLoading,
    String? error,
    bool? isCompleted,
  }) {
    return OnboardingState(
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      steps: steps ?? this.steps,
      completedSteps: completedSteps ?? this.completedSteps,
      permissionStatuses: permissionStatuses ?? this.permissionStatuses,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  OnboardingStep get currentStep => steps[currentStepIndex];
  bool get isFirstStep => currentStepIndex == 0;
  bool get isLastStep => currentStepIndex == steps.length - 1;
  int get totalSteps => steps.length;
  double get progress => (currentStepIndex + 1) / totalSteps;

  int getGrantedPermissionsCount() {
    int count = 0;
    for (final status in permissionStatuses.values) {
      if (status == PermissionStatus.granted) count++;
    }
    return count;
  }

  int getTotalPermissionsCount() {
    final allPermissions = <Permission>{};
    for (final step in steps) {
      if (step.permissions != null) {
        for (final permission in step.permissions!) {
          allPermissions.add(permission.permission);
        }
      }
    }
    return allPermissions.length;
  }
}

// Predefined onboarding data
class OnboardingData {
  static const List<OnboardingStep> defaultSteps = [
    OnboardingStep(
      id: 'welcome',
      type: OnboardingStepType.welcome,
      title: 'Welcome to Cairo',
      subtitle: 'Universal AI Call Companion',
      description:
          'Transform your communication experience with AI-powered insights, smart summaries, and intelligent automation.',
      icon: Icons.waving_hand,
      primaryColor: Color(0xFFD9B88A),
    ),
    OnboardingStep(
      id: 'features',
      type: OnboardingStepType.features,
      title: 'Powerful Features',
      subtitle: 'Everything you need in one place',
      description:
          'Discover how Cairo can enhance your daily communication and productivity.',
      icon: Icons.auto_awesome,
      primaryColor: Color(0xFF6366F1),
      features: [
        OnboardingFeature(
          title: 'Smart Call Analysis',
          description:
              'Automatically transcribe and analyze calls for key insights',
          icon: Icons.mic_external_on,
          color: Color(0xFF10B981),
          isHighlighted: true,
        ),
        OnboardingFeature(
          title: 'Notification Intelligence',
          description: 'AI-powered summaries of your important notifications',
          icon: Icons.notifications_active,
          color: Color(0xFFF59E0B),
        ),
        OnboardingFeature(
          title: 'Calendar Integration',
          description: 'Seamless Google Calendar sync and smart scheduling',
          icon: Icons.calendar_today,
          color: Color(0xFF3B82F6),
        ),
        OnboardingFeature(
          title: 'Privacy First',
          description: 'End-to-end encryption keeps your data secure',
          icon: Icons.security,
          color: Color(0xFF8B5CF6),
        ),
      ],
    ),
    OnboardingStep(
      id: 'permissions',
      type: OnboardingStepType.permissions,
      title: 'Enable Permissions',
      subtitle: 'For the best experience',
      description:
          'Grant access to essential permissions to unlock Cairo\'s full potential and smart features.',
      icon: Icons.admin_panel_settings,
      primaryColor: Color(0xFFEF4444),
      permissions: [
        OnboardingPermission(
          permission: Permission.microphone,
          title: 'Microphone Access',
          description: 'Record and transcribe calls for AI analysis',
          reason: 'Required for call recording and transcription features',
          icon: Icons.mic,
          color: Color(0xFF10B981),
          isRequired: true,
        ),
        OnboardingPermission(
          permission: Permission.notification,
          title: 'Notification Access',
          description: 'Read and summarize your notifications intelligently',
          reason: 'Enables AI-powered notification summaries',
          icon: Icons.notifications,
          color: Color(0xFFF59E0B),
          isRequired: true,
        ),
        OnboardingPermission(
          permission: Permission.phone,
          title: 'Phone Access',
          description: 'Detect incoming and outgoing calls',
          reason: 'Monitors call states for automatic recording',
          icon: Icons.phone,
          color: Color(0xFF3B82F6),
          isRequired: true,
        ),
        OnboardingPermission(
          permission: Permission.contacts,
          title: 'Contacts Access',
          description: 'Identify callers and enhance call summaries',
          reason: 'Improves call analysis with contact information',
          icon: Icons.contacts,
          color: Color(0xFF8B5CF6),
          isRequired: false,
        ),
        OnboardingPermission(
          permission: Permission.storage,
          title: 'Storage Access',
          description: 'Save call recordings and transcripts locally',
          reason: 'Store recordings and analysis data securely',
          icon: Icons.folder,
          color: Color(0xFF6B7280),
          isRequired: false,
        ),
        OnboardingPermission(
          permission: Permission.systemAlertWindow,
          title: 'Display Over Other Apps',
          description: 'Show floating widgets and call overlays',
          reason: 'Display live transcripts and quick actions during calls',
          icon: Icons.picture_in_picture,
          color: Color(0xFFEF4444),
          isRequired: true,
        ),
        OnboardingPermission(
          permission: Permission.notification,
          title: 'Notification Access',
          description: 'Send notifications and alerts for important events',
          reason: 'Display smart notifications and call alerts',
          icon: Icons.notifications_active,
          color: Color(0xFFDC2626),
          isRequired: true,
        ),
        OnboardingPermission.special(
          title: 'Battery Optimization',
          description: 'Allow app to run in background without restrictions',
          reason: 'Ensure call monitoring and notifications work reliably',
          icon: Icons.battery_saver,
          color: Color(0xFF059669),
          specialPermissionType: SpecialPermissionType.deviceAdmin,
          isRequired: true,
        ),
        OnboardingPermission.special(
          title: 'Notification Listener Service',
          description: 'Read and analyze notifications for smart insights',
          reason:
              'Enables AI-powered notification summaries and smart responses',
          icon: Icons.notifications_active,
          color: Color(0xFFDC2626),
          specialPermissionType: SpecialPermissionType.notificationListener,
          isRequired: true,
        ),
        OnboardingPermission.special(
          title: 'Accessibility Service',
          description: 'Enhanced automation and smart interactions',
          reason:
              'Enables advanced automation features and smart app interactions',
          icon: Icons.accessibility_new,
          color: Color(0xFF7C3AED),
          specialPermissionType: SpecialPermissionType.accessibilityService,
          isRequired: false,
        ),
      ],
    ),
    OnboardingStep(
      id: 'completion',
      type: OnboardingStepType.completion,
      title: 'You\'re All Set!',
      subtitle: 'Ready to experience smarter communication',
      description:
          'Cairo is now configured and ready to enhance your communication experience with AI-powered insights.',
      icon: Icons.celebration,
      primaryColor: Color(0xFF10B981),
    ),
  ];

  static List<OnboardingStep> getStepsForNewUser() {
    return List.from(defaultSteps);
  }

  static List<OnboardingStep> getStepsForExistingUser() {
    // For existing users, focus on new features and permissions
    return [
      defaultSteps[0], // Welcome
      defaultSteps[2], // Permissions
      defaultSteps[3], // Completion
    ];
  }
}
