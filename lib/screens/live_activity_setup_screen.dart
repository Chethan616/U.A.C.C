import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/live_activity_service.dart';

class LiveActivitySetupScreen extends StatefulWidget {
  const LiveActivitySetupScreen({Key? key}) : super(key: key);

  @override
  State<LiveActivitySetupScreen> createState() =>
      _LiveActivitySetupScreenState();
}

class _LiveActivitySetupScreenState extends State<LiveActivitySetupScreen> {
  bool _isMicrophonePermissionGranted = false;
  bool _isPhonePermissionGranted = false;
  bool _isNotificationPermissionGranted = false;
  bool _isChecking = false;
  bool _isServiceRunning = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _checkServiceStatus();
  }

  Future<void> _checkPermissions() async {
    setState(() => _isChecking = true);

    try {
      // Check microphone permission
      final microphoneStatus = await Permission.microphone.status;

      // Check phone permission
      final phoneStatus = await Permission.phone.status;

      // Check notification permission
      final notificationStatus = await Permission.notification.status;

      setState(() {
        _isMicrophonePermissionGranted = microphoneStatus.isGranted;
        _isPhonePermissionGranted = phoneStatus.isGranted;
        _isNotificationPermissionGranted = notificationStatus.isGranted;
        _isChecking = false;
      });
    } catch (e) {
      setState(() => _isChecking = false);
      _showErrorSnackBar('Failed to check permissions: $e');
    }
  }

  Future<void> _checkServiceStatus() async {
    try {
      final isRunning = await LiveActivityService.isLiveActivityRunning();
      setState(() {
        _isServiceRunning = isRunning;
      });
    } catch (e) {
      print('Error checking service status: $e');
    }
  }

  Future<void> _requestMicrophonePermission() async {
    try {
      final status = await Permission.microphone.request();
      setState(() {
        _isMicrophonePermissionGranted = status.isGranted;
      });

      if (status.isPermanentlyDenied) {
        _showPermissionDeniedDialog('Microphone', 'Record audio during calls');
      }
    } catch (e) {
      _showErrorSnackBar('Error requesting microphone permission: $e');
    }
  }

  Future<void> _requestPhonePermission() async {
    try {
      final status = await Permission.phone.request();
      setState(() {
        _isPhonePermissionGranted = status.isGranted;
      });

      if (status.isPermanentlyDenied) {
        _showPermissionDeniedDialog(
            'Phone', 'Detect incoming and outgoing calls');
      }
    } catch (e) {
      _showErrorSnackBar('Error requesting phone permission: $e');
    }
  }

  Future<void> _requestNotificationPermission() async {
    try {
      final status = await Permission.notification.request();
      setState(() {
        _isNotificationPermissionGranted = status.isGranted;
      });

      if (status.isPermanentlyDenied) {
        _showPermissionDeniedDialog(
            'Notification', 'Show ongoing call transcription');
      }
    } catch (e) {
      _showErrorSnackBar('Error requesting notification permission: $e');
    }
  }

  Future<void> _startLiveActivity() async {
    if (!_areAllPermissionsGranted()) {
      _showErrorSnackBar('Please grant all required permissions first');
      return;
    }

    try {
      final success = await LiveActivityService.startLiveActivity();
      if (success) {
        _showSuccessSnackBar(
            'Live Activity started! You\'ll see ongoing notifications during calls like Zomato delivery tracking.');
        setState(() => _isServiceRunning = true);
        Navigator.of(context).pop(true);
      } else {
        _showErrorSnackBar('Failed to start Live Activity service');
      }
    } catch (e) {
      _showErrorSnackBar('Error starting service: $e');
    }
  }

  Future<void> _stopLiveActivity() async {
    try {
      final success = await LiveActivityService.stopLiveActivity();
      if (success) {
        _showSuccessSnackBar('Live Activity stopped');
        setState(() => _isServiceRunning = false);
      } else {
        _showErrorSnackBar('Failed to stop Live Activity service');
      }
    } catch (e) {
      _showErrorSnackBar('Error stopping service: $e');
    }
  }

  bool _areAllPermissionsGranted() {
    return _isMicrophonePermissionGranted &&
        _isPhonePermissionGranted &&
        _isNotificationPermissionGranted;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showPermissionDeniedDialog(String permissionName, String purpose) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$permissionName Permission Required'),
        content: Text(
          'This permission is required to $purpose. Please enable it in the app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Live Activity Setup'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
      body: _isChecking
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderSection(),
                  const SizedBox(height: 32),
                  _buildExampleSection(),
                  const SizedBox(height: 32),
                  _buildPermissionsList(),
                  const SizedBox(height: 32),
                  _buildActionButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            Icons.notifications_active,
            size: 40,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Native Live Activity',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Get live call transcriptions using Android\'s native ongoing notifications - just like Zomato delivery tracking or screen recording!',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
        ),
      ],
    );
  }

  Widget _buildExampleSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'How it works',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildExampleItem(
              '📱 During calls, you\'ll see an ongoing notification at the top'),
          _buildExampleItem(
              '🗣️ Live transcript appears like "Zomato: Order arriving in 5 mins"'),
          _buildExampleItem('📋 Tap to view full transcript in the app'),
          _buildExampleItem('🎯 Works system-wide - appears over all apps'),
        ],
      ),
    );
  }

  Widget _buildExampleItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 4,
            margin: const EdgeInsets.only(top: 8, right: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.8),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Required Permissions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 16),
        _buildPermissionCard(
          title: 'Notification access',
          description:
              'Show ongoing activity notifications like Zomato or screen recording',
          icon: Icons.notifications,
          isGranted: _isNotificationPermissionGranted,
          onRequest: _requestNotificationPermission,
        ),
        const SizedBox(height: 16),
        _buildPermissionCard(
          title: 'Microphone access',
          description: 'Record and transcribe audio during phone calls',
          icon: Icons.mic,
          isGranted: _isMicrophonePermissionGranted,
          onRequest: _requestMicrophonePermission,
        ),
        const SizedBox(height: 16),
        _buildPermissionCard(
          title: 'Phone access',
          description: 'Detect when calls start and end automatically',
          icon: Icons.phone,
          isGranted: _isPhonePermissionGranted,
          onRequest: _requestPhonePermission,
        ),
      ],
    );
  }

  Widget _buildPermissionCard({
    required String title,
    required String description,
    required IconData icon,
    required bool isGranted,
    required VoidCallback onRequest,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isGranted
              ? Colors.green.withOpacity(0.3)
              : Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isGranted
                  ? Colors.green.withOpacity(0.1)
                  : Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isGranted ? Icons.check_circle : icon,
              color: isGranted
                  ? Colors.green
                  : Theme.of(context).colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7),
                      ),
                ),
              ],
            ),
          ),
          if (!isGranted) ...[
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: onRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              child: const Text('Grant'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    final allGranted = _areAllPermissionsGranted();

    return SizedBox(
      width: double.infinity,
      child: _isServiceRunning
          ? ElevatedButton(
              onPressed: _stopLiveActivity,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.stop, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Stop Live Activity',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          : ElevatedButton(
              onPressed: allGranted ? _startLiveActivity : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: allGranted
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceVariant,
                foregroundColor: allGranted
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    allGranted ? Icons.play_arrow : Icons.lock,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    allGranted
                        ? 'Start Live Activity'
                        : 'Grant Permissions to Continue',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
