// lib/screens/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/app_theme.dart';
import '../services/permissions_service.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: "Welcome to UACC",
      subtitle: "Universal AI Call Companion",
      description:
          "Transform your calls and notifications into actionable insights with AI-powered summaries.",
      icon: Icons.phone_android,
      color: AppColors.primary,
    ),
    OnboardingPage(
      title: "Smart Call Analysis",
      subtitle: "Never miss important details",
      description:
          "Automatically transcribe and summarize your calls to extract key information and action items.",
      icon: Icons.mic,
      color: AppColors.accent,
    ),
    OnboardingPage(
      title: "Notification Intelligence",
      subtitle: "Stay on top of everything",
      description:
          "Get smart summaries of your notifications and automatically categorize them by priority.",
      icon: Icons.notifications_active,
      color: AppColors.success,
    ),
    OnboardingPage(
      title: "Privacy First",
      subtitle: "Your data stays secure",
      description:
          "All processing happens securely with end-to-end encryption. You control your data.",
      icon: Icons.security,
      color: AppColors.primary,
    ),
    OnboardingPage(
      title: "Enable Permissions",
      subtitle: "For the best experience",
      description:
          "Grant access to essential permissions to enable smart call and notification processing.",
      icon: Icons.settings,
      color: AppColors.accent,
      isPermissionsPage: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: List.generate(_pages.length, (index) {
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(
                          right: index == _pages.length - 1 ? 0 : 8),
                      decoration: BoxDecoration(
                        color: index <= _currentPage
                            ? AppColors.primary
                            : AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),
            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _pages.length,
                itemBuilder: (context, index) => _buildPage(_pages[index]),
              ),
            ),
            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousPage,
                        child: const Text('Previous'),
                      ),
                    ),
                  if (_currentPage > 0) const SizedBox(width: 16),
                  Expanded(
                    flex: _currentPage == 0 ? 1 : 1,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      child: Text(_currentPage == _pages.length - 1
                          ? 'Continue to App'
                          : 'Next'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    if (page.isPermissionsPage) {
      return _buildPermissionsPage(page);
    }

    return Padding(
      padding: const EdgeInsets.all(32),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: page.color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                page.icon,
                size: 60,
                color: page.color,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              page.title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              page.subtitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Text(
              page.description,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionsPage(OnboardingPage page) {
    return Consumer(
      builder: (context, ref, child) {
        final permissionState = ref.watch(permissionsServiceProvider);
        final permissionsService =
            ref.read(permissionsServiceProvider.notifier);

        return Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              // Header
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: page.color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  page.icon,
                  size: 60,
                  color: page.color,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                page.title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                page.subtitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.muted,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Progress Indicator
              if (permissionState.totalCount > 0) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Permissions Progress',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          Text(
                            '${permissionState.grantedCount}/${permissionState.totalCount}',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: permissionState.progress,
                        backgroundColor: AppColors.border,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          permissionState.progress == 1.0
                              ? AppColors.success
                              : AppColors.primary,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Permissions List
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Required Permissions Section
                      _buildPermissionSection(
                        'Required Permissions',
                        'These permissions are essential for core app functionality',
                        PermissionType.values
                            .where((p) => p.isRequired)
                            .toList(),
                        permissionState,
                        permissionsService,
                        isRequired: true,
                      ),
                      const SizedBox(height: 24),

                      // Optional Permissions Section
                      _buildPermissionSection(
                        'Optional Permissions',
                        'These permissions enhance your experience but are not required',
                        PermissionType.values
                            .where((p) => !p.isRequired)
                            .toList(),
                        permissionState,
                        permissionsService,
                        isRequired: false,
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),

              // Action Buttons
              Column(
                children: [
                  if (permissionState.isLoading)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    )
                  else ...[
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () async {
                          await permissionsService
                              .requestAllRequiredPermissions();
                        },
                        icon: const Icon(Icons.security),
                        label: const Text('Grant Required Permissions'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await permissionsService.requestAllPermissions();
                        },
                        icon: const Icon(Icons.done_all),
                        label: const Text('Grant All Permissions'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                  if (permissionState.error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppColors.danger.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline,
                              color: AppColors.danger, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              permissionState.error!,
                              style: TextStyle(
                                color: AppColors.danger,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: permissionsService.clearError,
                            child: Text(
                              'Dismiss',
                              style: TextStyle(color: AppColors.danger),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPermissionSection(
    String title,
    String description,
    List<PermissionType> permissions,
    PermissionState permissionState,
    PermissionsService permissionsService, {
    required bool isRequired,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              isRequired ? Icons.security : Icons.tune,
              color: isRequired ? AppColors.primary : AppColors.accent,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isRequired ? AppColors.primary : AppColors.accent,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.muted,
              ),
        ),
        const SizedBox(height: 16),
        ...permissions.map((permissionType) => _buildPermissionCard(
              permissionType,
              permissionState,
              permissionsService,
            )),
      ],
    );
  }

  Widget _buildPermissionCard(
    PermissionType permissionType,
    PermissionState permissionState,
    PermissionsService permissionsService,
  ) {
    final status =
        permissionState.permissions[permissionType] ?? PermissionStatus.denied;
    final isGranted = status == PermissionStatus.granted;
    final isPermanentlyDenied = status == PermissionStatus.permanentlyDenied;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isGranted
              ? AppColors.success.withOpacity(0.3)
              : permissionType.isRequired && !isGranted
                  ? AppColors.danger.withOpacity(0.3)
                  : Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: permissionType.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              permissionType.icon,
              color: permissionType.color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      permissionType.displayName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    if (permissionType.isRequired) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Required',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.danger,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  permissionType.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                        height: 1.3,
                      ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      isGranted
                          ? Icons.check_circle
                          : isPermanentlyDenied
                              ? Icons.block
                              : Icons.radio_button_unchecked,
                      color: isGranted
                          ? AppColors.success
                          : isPermanentlyDenied
                              ? AppColors.danger
                              : AppColors.muted,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isGranted
                          ? 'Granted'
                          : isPermanentlyDenied
                              ? 'Permanently Denied'
                              : 'Not Granted',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isGranted
                            ? AppColors.success
                            : isPermanentlyDenied
                                ? AppColors.danger
                                : AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (isPermanentlyDenied)
            TextButton(
              onPressed: () async {
                await openAppSettings();
              },
              child: Text(
                'Settings',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.primary,
                ),
              ),
            )
          else if (!isGranted)
            FilledButton(
              onPressed: permissionState.isLoading
                  ? null
                  : () async {
                      await permissionsService
                          .requestPermission(permissionType);
                    },
              style: FilledButton.styleFrom(
                backgroundColor: permissionType.color,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                minimumSize: const Size(0, 32),
              ),
              child: Text(
                'Grant',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            )
          else
            Icon(
              Icons.check_circle,
              color: AppColors.success,
              size: 24,
            ),
        ],
      ),
    );
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Last page (permissions page) - continue to login
      _finishOnboarding();
    }
  }

  void _finishOnboarding() async {
    // Complete permissions onboarding
    final permissionsService = ref.read(permissionsServiceProvider.notifier);
    await permissionsService.completeOnboarding();

    // Navigate to login screen
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class OnboardingPage {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;
  final bool isPermissionsPage;

  OnboardingPage({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
    this.isPermissionsPage = false,
  });
}
