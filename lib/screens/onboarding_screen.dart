// lib/screens/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_app_bar.dart';
import '../services/app_state_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
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
          "Grant access to microphone, notifications, and phone to enable smart call and notification processing.",
      icon: Icons.settings,
      color: AppColors.accent,
      isPermissionsPage: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.base,
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
                  color: AppColors.muted,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            page.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.muted,
                  height: 1.5,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(32),
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
                  color: AppColors.muted,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            page.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.muted,
                  height: 1.5,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _buildPermissionsList(),
        ],
      ),
    );
  }

  Widget _buildPermissionsList() {
    final permissions = [
      PermissionInfo(
        title: 'Microphone',
        description: 'Record and transcribe calls',
        icon: Icons.mic,
        permission: Permission.microphone,
      ),
      PermissionInfo(
        title: 'Phone',
        description: 'Access call information',
        icon: Icons.phone,
        permission: Permission.phone,
      ),
      PermissionInfo(
        title: 'Notifications',
        description: 'Read and analyze notifications',
        icon: Icons.notifications,
        permission: Permission.notification,
      ),
      PermissionInfo(
        title: 'Storage',
        description: 'Save call recordings and summaries',
        icon: Icons.storage,
        permission: Permission.storage,
      ),
    ];

    return Column(
      children: [
        ...permissions
            .map((permissionInfo) => _buildPermissionCard(permissionInfo)),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _requestAllPermissions,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.text,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Grant Permissions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _skipPermissions,
          child: Text(
            'Skip for now',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionCard(PermissionInfo permissionInfo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              permissionInfo.icon,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  permissionInfo.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  permissionInfo.description,
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          FutureBuilder<PermissionStatus>(
            future: permissionInfo.permission.status,
            builder: (context, snapshot) {
              final status = snapshot.data ?? PermissionStatus.denied;
              return Icon(
                status == PermissionStatus.granted
                    ? Icons.check_circle
                    : Icons.circle_outlined,
                color: status == PermissionStatus.granted
                    ? AppColors.success
                    : AppColors.muted,
                size: 24,
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _requestAllPermissions() async {
    final permissions = [
      Permission.microphone,
      Permission.phone,
      Permission.notification,
      Permission.storage,
    ];

    for (final permission in permissions) {
      await permission.request();
    }

    // Refresh the UI to show updated permission status
    setState(() {});

    // Small delay to show the updated status, then continue
    await Future.delayed(const Duration(milliseconds: 500));
    _nextPage();
  }

  void _skipPermissions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Skip Permissions?'),
        content: const Text(
          'Some features may not work properly without these permissions. You can grant them later in settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _nextPage();
            },
            child: const Text('Skip'),
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
    // Mark onboarding as completed and first launch as done
    await AppStateService.instance.setOnboardingCompleted();
    await AppStateService.instance.setFirstLaunchCompleted();

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

// Permissions Screen
class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({Key? key}) : super(key: key);

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  final Map<String, bool> _permissions = {
    'notifications': false,
    'microphone': false,
    'phone': false,
    'storage': false,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.base,
      appBar: const CustomAppBar(title: 'Permissions Required'),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Grant Permissions',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'To provide the best experience, we need access to the following permissions:',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.muted,
                  ),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: ListView(
                children: [
                  _buildPermissionItem(
                    title: 'Notifications',
                    description:
                        'Access notifications to provide smart summaries',
                    icon: Icons.notifications,
                    key: 'notifications',
                    isRequired: true,
                  ),
                  _buildPermissionItem(
                    title: 'Microphone',
                    description: 'Record calls for transcription and analysis',
                    icon: Icons.mic,
                    key: 'microphone',
                    isRequired: true,
                  ),
                  _buildPermissionItem(
                    title: 'Phone Access',
                    description: 'Detect incoming and outgoing calls',
                    icon: Icons.phone,
                    key: 'phone',
                    isRequired: true,
                  ),
                  _buildPermissionItem(
                    title: 'Storage',
                    description: 'Store audio files and processed data locally',
                    icon: Icons.storage,
                    key: 'storage',
                    isRequired: false,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _allRequiredPermissionsGranted()
                    ? _continueToLogin
                    : _requestPermissions,
                child: Text(_allRequiredPermissionsGranted()
                    ? 'Continue'
                    : 'Grant Permissions'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _skipForNow,
                child: const Text('Skip for now'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionItem({
    required String title,
    required String description,
    required IconData icon,
    required String key,
    required bool isRequired,
  }) {
    final isGranted = _permissions[key] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isGranted
                    ? AppColors.success.withOpacity(0.15)
                    : AppColors.muted.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isGranted ? AppColors.success : AppColors.muted,
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
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (isRequired) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Required',
                            style: TextStyle(
                              color: AppColors.danger,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Icon(
              isGranted ? Icons.check_circle : Icons.circle_outlined,
              color: isGranted ? AppColors.success : AppColors.muted,
            ),
          ],
        ),
      ),
    );
  }

  bool _allRequiredPermissionsGranted() {
    return _permissions['notifications']! &&
        _permissions['microphone']! &&
        _permissions['phone']!;
  }

  void _requestPermissions() async {
    // Simulate permission request
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _permissions['notifications'] = true;
      _permissions['microphone'] = true;
      _permissions['phone'] = true;
      _permissions['storage'] = true;
    });

    _showPermissionResult();
  }

  void _showPermissionResult() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permissions Granted'),
        content: const Text(
            'All required permissions have been granted successfully!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _continueToLogin();
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _continueToLogin() async {
    // Mark onboarding as completed and first launch as done
    await AppStateService.instance.setOnboardingCompleted();
    await AppStateService.instance.setFirstLaunchCompleted();

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void _skipForNow() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Skip Permissions?'),
        content: const Text(
            'Some features may not work properly without these permissions. You can grant them later in settings.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _continueToLogin();
            },
            child: const Text('Skip'),
          ),
        ],
      ),
    );
  }
}

class PermissionInfo {
  final String title;
  final String description;
  final IconData icon;
  final Permission permission;

  PermissionInfo({
    required this.title,
    required this.description,
    required this.icon,
    required this.permission,
  });
}
