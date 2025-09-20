import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/call_overlay_service.dart';

class DynamicIslandPermissionScreen extends StatefulWidget {
  const DynamicIslandPermissionScreen({Key? key}) : super(key: key);

  @override
  State<DynamicIslandPermissionScreen> createState() =>
      _DynamicIslandPermissionScreenState();
}

class _DynamicIslandPermissionScreenState
    extends State<DynamicIslandPermissionScreen> {
  bool _isOverlayPermissionGranted = false;
  bool _isMicrophonePermissionGranted = false;
  bool _isPhonePermissionGranted = false;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    setState(() => _isChecking = true);

    try {
      // Check overlay permission
      final overlayGranted = await CallOverlayService.checkOverlayPermission();

      // Check microphone permission
      final microphoneStatus = await Permission.microphone.status;

      // Check phone permission
      final phoneStatus = await Permission.phone.status;

      setState(() {
        _isOverlayPermissionGranted = overlayGranted;
        _isMicrophonePermissionGranted = microphoneStatus.isGranted;
        _isPhonePermissionGranted = phoneStatus.isGranted;
        _isChecking = false;
      });
    } catch (e) {
      setState(() => _isChecking = false);
      _showErrorSnackBar('Failed to check permissions: $e');
    }
  }

  Future<void> _requestOverlayPermission() async {
    try {
      final success = await CallOverlayService.requestOverlayPermission();
      if (success) {
        // Wait a moment for the permission to be processed
        await Future.delayed(const Duration(seconds: 1));
        await _checkPermissions();
      } else {
        _showErrorSnackBar('Failed to open overlay permission settings');
      }
    } catch (e) {
      _showErrorSnackBar('Error requesting overlay permission: $e');
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

  Future<void> _startDynamicIslandService() async {
    if (!_areAllPermissionsGranted()) {
      _showErrorSnackBar('Please grant all required permissions first');
      return;
    }

    try {
      final success = await CallOverlayService.startService();
      if (success) {
        _showSuccessSnackBar('Dynamic Island service started successfully!');
        Navigator.of(context).pop(true);
      } else {
        _showErrorSnackBar('Failed to start Dynamic Island service');
      }
    } catch (e) {
      _showErrorSnackBar('Error starting service: $e');
    }
  }

  bool _areAllPermissionsGranted() {
    return _isOverlayPermissionGranted &&
        _isMicrophonePermissionGranted &&
        _isPhonePermissionGranted;
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
        title: const Text('Dynamic Island Setup'),
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
                  _buildPermissionsList(),
                  const SizedBox(height: 32),
                  _buildStartButton(),
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
            Icons.settings_phone,
            size: 40,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'System-wide Dynamic Island',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Get live call transcriptions in a floating overlay that appears over your phone calls and other apps.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
        ),
      ],
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
          title: 'Display over other apps',
          description:
              'Allow the Dynamic Island to appear over phone calls and other apps',
          icon: Icons.picture_in_picture_alt,
          isGranted: _isOverlayPermissionGranted,
          onRequest: _requestOverlayPermission,
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

  Widget _buildStartButton() {
    final allGranted = _areAllPermissionsGranted();

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: allGranted ? _startDynamicIslandService : null,
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
              allGranted ? Icons.rocket_launch : Icons.lock,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              allGranted
                  ? 'Start Dynamic Island Service'
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
