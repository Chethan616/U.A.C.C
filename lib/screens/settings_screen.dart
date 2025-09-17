// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_app_bar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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

  final List<String> _languages = [
    'English',
    'Hindi',
    'Spanish',
    'French',
    'German'
  ];
  final List<String> _voiceQualities = ['High', 'Medium', 'Low'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.base,
      appBar: const CustomAppBar(
        title: 'Settings',
        showBackButton: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Section
          _buildProfileSection(),

          const SizedBox(height: 24),

          // Privacy & Security
          _buildSectionHeader('Privacy & Security'),
          _buildPrivacySettings(),

          const SizedBox(height: 24),

          // Call Settings
          _buildSectionHeader('Call Settings'),
          _buildCallSettings(),

          const SizedBox(height: 24),

          // Notification Settings
          _buildSectionHeader('Notifications'),
          _buildNotificationSettings(),

          const SizedBox(height: 24),

          // AI & Processing
          _buildSectionHeader('AI & Processing'),
          _buildAISettings(),

          const SizedBox(height: 24),

          // App Settings
          _buildSectionHeader('App Settings'),
          _buildAppSettings(),

          const SizedBox(height: 24),

          // Data & Storage
          _buildSectionHeader('Data & Storage'),
          _buildDataSettings(),

          const SizedBox(height: 24),

          // Support
          _buildSectionHeader('Support'),
          _buildSupportSettings(),

          const SizedBox(height: 24),

          // Sign Out
          _buildSignOutSection(),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.primary.withOpacity(0.15),
              child: const Icon(
                Icons.person,
                size: 36,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chethan Krishna',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'chethan@example.com',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.muted,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Pro Plan',
                          style: TextStyle(
                            color: AppColors.success,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: _editProfile,
              icon: const Icon(Icons.edit, color: AppColors.primary),
            ),
          ],
        ),
      ),
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
