import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';

class PermissionRequestScreen extends StatefulWidget {
  final VoidCallback onPermissionsGranted;

  const PermissionRequestScreen({
    Key? key,
    required this.onPermissionsGranted,
  }) : super(key: key);

  @override
  State<PermissionRequestScreen> createState() =>
      _PermissionRequestScreenState();
}

class _PermissionRequestScreenState extends State<PermissionRequestScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  Map<Permission, PermissionStatus> _permissionStatuses = {};
  bool _isRequesting = false;

  final List<PermissionInfo> _requiredPermissions = [
    PermissionInfo(
      permission: Permission.microphone,
      title: 'Microphone Access',
      description: 'Record calls for AI analysis and transcription',
      icon: Icons.mic,
    ),
    PermissionInfo(
      permission: Permission.storage,
      title: 'Storage Access',
      description: 'Save call recordings and analysis data',
      icon: Icons.storage,
    ),
    PermissionInfo(
      permission: Permission.phone,
      title: 'Phone Access',
      description: 'Detect call states and read call logs',
      icon: Icons.phone,
    ),
    PermissionInfo(
      permission: Permission.contacts,
      title: 'Contacts Access',
      description: 'Show caller information and profile pictures',
      icon: Icons.contacts,
    ),
    PermissionInfo(
      permission: Permission.notification,
      title: 'Notification Access',
      description: 'Smart notification automation and replies',
      icon: Icons.notifications,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
    _checkCurrentPermissions();
  }

  Future<void> _checkCurrentPermissions() async {
    Map<Permission, PermissionStatus> statuses = {};
    for (var permissionInfo in _requiredPermissions) {
      statuses[permissionInfo.permission] =
          await permissionInfo.permission.status;
    }

    setState(() {
      _permissionStatuses = statuses;
    });
  }

  Future<void> _requestAllPermissions() async {
    setState(() {
      _isRequesting = true;
    });

    try {
      // Request permissions one by one for better UX
      for (var permissionInfo in _requiredPermissions) {
        if (!(_permissionStatuses[permissionInfo.permission]?.isGranted ??
            false)) {
          final status = await _requestSinglePermission(permissionInfo);
          _permissionStatuses[permissionInfo.permission] = status;
          setState(() {});

          // Small delay between requests
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      // Check if all critical permissions are granted
      if (_allCriticalPermissionsGranted()) {
        widget.onPermissionsGranted();
      }
    } catch (e) {
      _showErrorDialog('Error requesting permissions: $e');
    } finally {
      setState(() {
        _isRequesting = false;
      });
    }
  }

  Future<PermissionStatus> _requestSinglePermission(
      PermissionInfo permissionInfo) async {
    // Show explanation dialog first
    final shouldRequest = await _showPermissionExplanation(permissionInfo);
    if (!shouldRequest) {
      return PermissionStatus.denied;
    }

    // Request the permission
    final status = await permissionInfo.permission.request();

    // Handle permanent denial
    if (status.isPermanentlyDenied) {
      await _showPermanentDenialDialog(permissionInfo);
    }

    return status;
  }

  Future<bool> _showPermissionExplanation(PermissionInfo permissionInfo) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(permissionInfo.icon,
                    color: Theme.of(context).primaryColor),
                const SizedBox(width: 12),
                Expanded(child: Text(permissionInfo.title)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(permissionInfo.description),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.security, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your data is processed securely and never shared.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Skip'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Allow'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _showPermanentDenialDialog(PermissionInfo permissionInfo) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${permissionInfo.title} Required'),
        content: const Text(
          'This permission is required for the app to function properly. '
          'Please enable it in the app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  bool _allCriticalPermissionsGranted() {
    final criticalPermissions = [
      Permission.microphone,
      Permission.storage,
      Permission.phone
    ];
    return criticalPermissions.every(
      (permission) => _permissionStatuses[permission]?.isGranted ?? false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.1),
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Spacer(),

                  // App Icon and Title
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color:
                              Theme.of(context).primaryColor.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.psychology,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'UACC Setup',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Grant permissions for AI-powered automation',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 48),

                  // Permission List
                  Expanded(
                    flex: 2,
                    child: ListView.builder(
                      itemCount: _requiredPermissions.length,
                      itemBuilder: (context, index) {
                        final permissionInfo = _requiredPermissions[index];
                        final status =
                            _permissionStatuses[permissionInfo.permission];

                        return AnimatedContainer(
                          duration: Duration(milliseconds: 300 + (index * 100)),
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color:
                                      _getStatusColor(status).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  permissionInfo.icon,
                                  color: _getStatusColor(status),
                                ),
                              ),
                              title: Text(permissionInfo.title),
                              subtitle: Text(
                                permissionInfo.description,
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: _getStatusIcon(status),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isRequesting ? null : _requestAllPermissions,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isRequesting
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                        AlwaysStoppedAnimation(Colors.white),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text('Requesting Permissions...'),
                              ],
                            )
                          : const Text(
                              'Grant Permissions',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  if (_allCriticalPermissionsGranted())
                    TextButton(
                      onPressed: widget.onPermissionsGranted,
                      child: const Text('Continue to App'),
                    ),

                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(PermissionStatus? status) {
    switch (status) {
      case PermissionStatus.granted:
        return Colors.green;
      case PermissionStatus.denied:
      case PermissionStatus.permanentlyDenied:
        return Colors.red;
      case PermissionStatus.restricted:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _getStatusIcon(PermissionStatus? status) {
    switch (status) {
      case PermissionStatus.granted:
        return const Icon(Icons.check_circle, color: Colors.green);
      case PermissionStatus.denied:
      case PermissionStatus.permanentlyDenied:
        return const Icon(Icons.cancel, color: Colors.red);
      case PermissionStatus.restricted:
        return const Icon(Icons.warning, color: Colors.orange);
      default:
        return const Icon(Icons.help_outline, color: Colors.grey);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

class PermissionInfo {
  final Permission permission;
  final String title;
  final String description;
  final IconData icon;

  const PermissionInfo({
    required this.permission,
    required this.title,
    required this.description,
    required this.icon,
  });
}
