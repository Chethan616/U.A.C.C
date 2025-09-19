// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_app_bar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {
  bool _notificationsEnabled = true;
  bool _callRecordingEnabled = true;
  bool _autoSummarize = true;
  bool _offlineMode = false;
  bool _darkModeEnabled = false;
  bool _biometricEnabled = false;
  String _selectedLanguage = 'English';
  String _voiceQuality = 'High';
  double _summarizationLevel = 2.0;
  bool _shareAnalytics = false;

  late AnimationController _mainAnimationController;
  late AnimationController _profileAnimationController;

  final List<String> _languages = [
    'English',
    'Hindi',
    'Spanish',
    'French',
    'German'
  ];
  final List<String> _voiceQualities = ['High', 'Medium', 'Low'];

  @override
  void initState() {
    super.initState();
    _mainAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _profileAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _mainAnimationController.forward();
    _profileAnimationController.forward();
  }

  @override
  void dispose() {
    _mainAnimationController.dispose();
    _profileAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const CustomAppBar(
        title: 'Settings',
        showBackButton: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Section with animation
          SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(-1.0, 0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: _profileAnimationController,
                curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
              ),
            ),
            child: FadeTransition(
              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(
                  parent: _profileAnimationController,
                  curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
                ),
              ),
              child: _buildProfileSection(),
            ),
          ),

          const SizedBox(height: 24),

          // Animated sections with staggered timing
          ..._buildAnimatedSections(),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  List<Widget> _buildAnimatedSections() {
    final sections = [
      {'title': 'Privacy & Security', 'builder': () => _buildPrivacySettings()},
      {'title': 'Call Settings', 'builder': () => _buildCallSettings()},
      {'title': 'Notifications', 'builder': () => _buildNotificationSettings()},
      {'title': 'AI & Processing', 'builder': () => _buildAISettings()},
      {'title': 'App Settings', 'builder': () => _buildAppSettings()},
      {'title': 'Data & Storage', 'builder': () => _buildDataSettings()},
      {'title': 'Support', 'builder': () => _buildSupportSettings()},
    ];

    List<Widget> widgets = [];

    // Add animated sections
    for (int index = 0; index < sections.length; index++) {
      final section = sections[index];

      widgets.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: _mainAnimationController,
                  curve: Interval(
                    0.1 + (index * 0.08),
                    0.5 + (index * 0.08),
                    curve: Curves.easeOutCubic,
                  ),
                ),
              ),
              child: FadeTransition(
                opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(
                    parent: _mainAnimationController,
                    curve: Interval(
                      0.1 + (index * 0.08),
                      0.5 + (index * 0.08),
                      curve: Curves.easeOutCubic,
                    ),
                  ),
                ),
                child: _buildSectionHeader(section['title'] as String),
              ),
            ),
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.5),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: _mainAnimationController,
                  curve: Interval(
                    0.15 + (index * 0.08),
                    0.55 + (index * 0.08),
                    curve: Curves.easeOutCubic,
                  ),
                ),
              ),
              child: FadeTransition(
                opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(
                    parent: _mainAnimationController,
                    curve: Interval(
                      0.15 + (index * 0.08),
                      0.55 + (index * 0.08),
                      curve: Curves.easeOutCubic,
                    ),
                  ),
                ),
                child: (section['builder'] as Function)(),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      );
    }

    // Add sign out section with special animation
    widgets.add(
      ScaleTransition(
        scale: Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _mainAnimationController,
            curve: const Interval(0.8, 1.0, curve: Curves.elasticOut),
          ),
        ),
        child: FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: _mainAnimationController,
              curve: const Interval(0.8, 1.0, curve: Curves.easeOut),
            ),
          ),
          child: _buildSignOutSection(),
        ),
      ),
    );

    return widgets;
  }

  Widget _buildProfileSection() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Card(
            elevation: 8,
            shadowColor: AppColors.shadow.withOpacity(0.2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.05),
                    AppColors.accent.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.elasticOut,
                      builder: (context, animValue, child) {
                        return Transform.rotate(
                          angle: animValue * 2 * 3.14159,
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.accent,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.person,
                              size: 36,
                              color: Colors.white,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chethan Krishna',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.text,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'chethan@example.com',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppColors.muted,
                                ),
                          ),
                          const SizedBox(height: 12),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.success,
                                  AppColors.success.withOpacity(0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.success.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Text(
                              'Pro Plan',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.elasticOut,
                      builder: (context, animValue, child) {
                        return Transform.scale(
                          scale: animValue,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              onPressed: _editProfile,
                              icon: const Icon(
                                Icons.edit,
                                color: AppColors.primary,
                              ),
                              iconSize: 24,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
      ),
    );
  }

  Widget _buildPrivacySettings() {
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Biometric Authentication'),
            subtitle: const Text('Use fingerprint or face ID to unlock app'),
            value: _biometricEnabled,
            onChanged: (value) => setState(() => _biometricEnabled = value),
            activeColor: AppColors.primary,
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text('Data Encryption'),
            subtitle: const Text('All data is encrypted end-to-end'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Active',
                style: TextStyle(
                  color: AppColors.success,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _showPrivacyPolicy,
          ),
          ListTile(
            title: const Text('Data Usage'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _showDataUsage,
          ),
        ],
      ),
    );
  }

  Widget _buildCallSettings() {
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Call Recording'),
            subtitle: const Text('Automatically record calls for analysis'),
            value: _callRecordingEnabled,
            onChanged: (value) => setState(() => _callRecordingEnabled = value),
            activeColor: AppColors.primary,
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text('Voice Quality'),
            subtitle: Text('Current: $_voiceQuality'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _selectVoiceQuality,
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: const Text('Auto Summarization'),
            subtitle: const Text('Automatically generate call summaries'),
            value: _autoSummarize,
            onChanged: (value) => setState(() => _autoSummarize = value),
            activeColor: AppColors.primary,
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text('Call History Retention'),
            subtitle: const Text('Keep call data for 90 days'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _showRetentionSettings,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Smart Notifications'),
            subtitle: const Text('Get AI-powered notification summaries'),
            value: _notificationsEnabled,
            onChanged: (value) => setState(() => _notificationsEnabled = value),
            activeColor: AppColors.primary,
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text('Notification Categories'),
            subtitle: const Text('Manage which apps to analyze'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _manageNotificationCategories,
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text('Quiet Hours'),
            subtitle: const Text('Set times when notifications are silent'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _setQuietHours,
          ),
        ],
      ),
    );
  }

  Widget _buildAISettings() {
    return Card(
      child: Column(
        children: [
          ListTile(
            title: const Text('AI Model'),
            subtitle: const Text('GPT-4 Turbo (Recommended)'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _selectAIModel,
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Summarization Level',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Slider(
                  value: _summarizationLevel,
                  min: 1.0,
                  max: 3.0,
                  divisions: 2,
                  label: _getSummarizationLabel(_summarizationLevel),
                  activeColor: AppColors.primary,
                  onChanged: (value) =>
                      setState(() => _summarizationLevel = value),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Brief',
                        style: Theme.of(context).textTheme.labelSmall),
                    Text('Detailed',
                        style: Theme.of(context).textTheme.labelSmall),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: const Text('Offline Processing'),
            subtitle: const Text('Process data locally when possible'),
            value: _offlineMode,
            onChanged: (value) => setState(() => _offlineMode = value),
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildAppSettings() {
    return Card(
      child: Column(
        children: [
          ListTile(
            title: const Text('Language'),
            subtitle: Text('Current: $_selectedLanguage'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _selectLanguage,
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Use dark theme'),
            value: _darkModeEnabled,
            onChanged: (value) => setState(() => _darkModeEnabled = value),
            activeColor: AppColors.primary,
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text('App Version'),
            subtitle: const Text('1.0.0 (Build 100)'),
            trailing: TextButton(
              onPressed: _checkForUpdates,
              child: const Text('Check Updates'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataSettings() {
    return Card(
      child: Column(
        children: [
          ListTile(
            title: const Text('Storage Used'),
            subtitle: const Text('2.3 GB of 10 GB used'),
            trailing: TextButton(
              onPressed: _manageStorage,
              child: const Text('Manage'),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text('Export Data'),
            subtitle: const Text('Download your data'),
            trailing: const Icon(Icons.download),
            onTap: _exportData,
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: const Text('Share Analytics'),
            subtitle: const Text('Help improve the app with usage data'),
            value: _shareAnalytics,
            onChanged: (value) => setState(() => _shareAnalytics = value),
            activeColor: AppColors.primary,
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text('Clear Cache'),
            subtitle: const Text('Free up storage space'),
            trailing: const Icon(Icons.cleaning_services),
            onTap: _clearCache,
          ),
        ],
      ),
    );
  }

  Widget _buildSupportSettings() {
    return Card(
      child: Column(
        children: [
          ListTile(
            title: const Text('Help Center'),
            trailing: const Icon(Icons.help_outline),
            onTap: _showHelpCenter,
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text('Contact Support'),
            trailing: const Icon(Icons.support_agent),
            onTap: _contactSupport,
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text('Report a Bug'),
            trailing: const Icon(Icons.bug_report),
            onTap: _reportBug,
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text('Rate App'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                  5,
                  (index) => Icon(
                        Icons.star,
                        size: 16,
                        color: AppColors.accent,
                      )),
            ),
            onTap: _rateApp,
          ),
        ],
      ),
    );
  }

  Widget _buildSignOutSection() {
    return Card(
      child: ListTile(
        title: const Text(
          'Sign Out',
          style: TextStyle(
            color: AppColors.danger,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: const Icon(
          Icons.logout,
          color: AppColors.danger,
        ),
        onTap: _signOut,
      ),
    );
  }

  String _getSummarizationLabel(double value) {
    switch (value.round()) {
      case 1:
        return 'Brief';
      case 2:
        return 'Balanced';
      case 3:
        return 'Detailed';
      default:
        return 'Balanced';
    }
  }

  void _editProfile() {
    // Implementation for editing profile
    Navigator.pushNamed(context, '/edit-profile');
  }

  void _showPrivacyPolicy() {
    // Implementation for showing privacy policy
  }

  void _showDataUsage() {
    // Implementation for showing data usage
  }

  void _selectVoiceQuality() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Voice Quality'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _voiceQualities.map((quality) {
            return RadioListTile<String>(
              title: Text(quality),
              value: quality,
              groupValue: _voiceQuality,
              onChanged: (value) {
                setState(() => _voiceQuality = value!);
                Navigator.pop(context);
              },
              activeColor: AppColors.primary,
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showRetentionSettings() {
    // Implementation for retention settings
  }

  void _manageNotificationCategories() {
    // Implementation for managing notification categories
  }

  void _setQuietHours() {
    // Implementation for setting quiet hours
  }

  void _selectAIModel() {
    // Implementation for selecting AI model
  }

  void _selectLanguage() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _languages.map((language) {
            return RadioListTile<String>(
              title: Text(language),
              value: language,
              groupValue: _selectedLanguage,
              onChanged: (value) {
                setState(() => _selectedLanguage = value!);
                Navigator.pop(context);
              },
              activeColor: AppColors.primary,
            );
          }).toList(),
        ),
      ),
    );
  }

  void _checkForUpdates() {
    // Implementation for checking updates
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('App Update'),
        content: const Text('You have the latest version of UACC.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _manageStorage() {
    // Implementation for managing storage
  }

  void _exportData() {
    // Implementation for exporting data
  }

  void _clearCache() {
    // Implementation for clearing cache
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
            'This will free up storage space but may slow down the app temporarily.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Cache cleared successfully'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showHelpCenter() {
    // Implementation for showing help center
  }

  void _contactSupport() {
    // Implementation for contacting support
  }

  void _reportBug() {
    // Implementation for reporting bugs
  }

  void _rateApp() {
    // Implementation for rating app
  }

  void _signOut() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
