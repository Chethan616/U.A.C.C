import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/api_config_service.dart';
import '../services/permission_service.dart';

class ApiKeyManagementScreen extends StatefulWidget {
  const ApiKeyManagementScreen({Key? key}) : super(key: key);

  @override
  State<ApiKeyManagementScreen> createState() => _ApiKeyManagementScreenState();
}

class _ApiKeyManagementScreenState extends State<ApiKeyManagementScreen> {
  final _geminiController = TextEditingController();
  final _googleClientIdController = TextEditingController();
  final _googleClientSecretController = TextEditingController();
  final _googleServiceAccountController = TextEditingController();

  bool _isLoading = true;
  bool _isTestingGemini = false;
  Map<String, bool> _keyStatus = {};
  Map<String, bool> _permissionStatus = {};

  @override
  void initState() {
    super.initState();
    _loadCurrentKeys();
    _loadPermissionStatus();
  }

  Future<void> _loadCurrentKeys() async {
    setState(() => _isLoading = true);

    try {
      final geminiKey = await ApiConfigService.getGeminiApiKey();
      final googleClientId = await ApiConfigService.getGoogleClientId();
      final googleClientSecret = await ApiConfigService.getGoogleClientSecret();
      final googleServiceAccount =
          await ApiConfigService.getGoogleServiceAccount();

      _geminiController.text = geminiKey ?? '';
      _googleClientIdController.text = googleClientId ?? '';
      _googleClientSecretController.text = googleClientSecret ?? '';
      _googleServiceAccountController.text = googleServiceAccount ?? '';

      _keyStatus = await ApiConfigService.getApiKeyStatus();
    } catch (e) {
      _showError('Error loading API keys: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadPermissionStatus() async {
    try {
      _permissionStatus = await PermissionService.getPermissionSummary();
      setState(() {});
    } catch (e) {
      print('Error loading permission status: $e');
    }
  }

  Future<void> _saveGeminiKey() async {
    try {
      await ApiConfigService.setGeminiApiKey(_geminiController.text);
      await _loadCurrentKeys();
      _showSuccess('Gemini API key saved successfully!');
    } catch (e) {
      _showError('Error saving Gemini API key: $e');
    }
  }

  Future<void> _testGeminiKey() async {
    if (_geminiController.text.trim().isEmpty) {
      _showError('Please enter a Gemini API key first');
      return;
    }

    setState(() => _isTestingGemini = true);

    try {
      final isValid =
          await ApiConfigService.testGeminiApiKey(_geminiController.text);
      if (isValid) {
        _showSuccess('Gemini API key is valid!');
      } else {
        _showError('Invalid Gemini API key format');
      }
    } catch (e) {
      _showError('Error testing API key: $e');
    } finally {
      setState(() => _isTestingGemini = false);
    }
  }

  Future<void> _saveGoogleCredentials() async {
    try {
      if (_googleClientIdController.text.isNotEmpty) {
        await ApiConfigService.setGoogleClientId(
            _googleClientIdController.text);
      }
      if (_googleClientSecretController.text.isNotEmpty) {
        await ApiConfigService.setGoogleClientSecret(
            _googleClientSecretController.text);
      }
      if (_googleServiceAccountController.text.isNotEmpty) {
        await ApiConfigService.setGoogleServiceAccount(
            _googleServiceAccountController.text);
      }

      await _loadCurrentKeys();
      _showSuccess('Google credentials saved successfully!');
    } catch (e) {
      _showError('Error saving Google credentials: $e');
    }
  }

  Future<void> _requestAllPermissions() async {
    final statuses = await PermissionService.requestAllPermissions();
    await _loadPermissionStatus();

    final deniedPermissions = statuses.entries
        .where((entry) => entry.value != PermissionStatus.granted)
        .map((entry) => entry.key.toString())
        .toList();

    if (deniedPermissions.isEmpty) {
      _showSuccess('All permissions granted!');
    } else {
      _showError(
          'Some permissions were denied: ${deniedPermissions.join(', ')}');
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API & Permissions Setup'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusCard(),
                  const SizedBox(height: 24),
                  _buildGeminiSection(),
                  const SizedBox(height: 24),
                  _buildGoogleSection(),
                  const SizedBox(height: 24),
                  _buildPermissionsSection(),
                  const SizedBox(height: 24),
                  _buildInstructionsSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard() {
    final allKeysConfigured = _keyStatus.values.every((status) => status);
    final allPermissionsGranted =
        _permissionStatus.values.every((status) => status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Setup Status',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  allKeysConfigured ? Icons.check_circle : Icons.warning,
                  color: allKeysConfigured ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                    'API Keys: ${allKeysConfigured ? 'Configured' : 'Incomplete'}'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  allPermissionsGranted ? Icons.check_circle : Icons.warning,
                  color: allPermissionsGranted ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                    'Permissions: ${allPermissionsGranted ? 'Granted' : 'Incomplete'}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeminiSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _keyStatus['gemini'] == true
                      ? Icons.check_circle
                      : Icons.circle_outlined,
                  color:
                      _keyStatus['gemini'] == true ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  'Gemini API Key',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Your Gemini API key for AI-powered call analysis and smart notifications.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _geminiController,
              decoration: const InputDecoration(
                labelText: 'Gemini API Key',
                hintText: 'AIza...',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _saveGeminiKey,
                  child: const Text('Save'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isTestingGemini ? null : _testGeminiKey,
                  child: _isTestingGemini
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Test'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Google Workspace Integration',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Configure Google Calendar and Tasks integration for automated scheduling.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _googleClientIdController,
              decoration: const InputDecoration(
                labelText: 'Google OAuth Client ID',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _googleClientSecretController,
              decoration: const InputDecoration(
                labelText: 'Google OAuth Client Secret',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _googleServiceAccountController,
              decoration: const InputDecoration(
                labelText: 'Service Account JSON (Optional)',
                hintText: 'Paste service account JSON here',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _saveGoogleCredentials,
              child: const Text('Save Google Credentials'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Permissions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Grant permissions needed for automation features.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            ..._permissionStatus.entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        entry.value
                            ? Icons.check_circle
                            : Icons.circle_outlined,
                        color: entry.value ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_getPermissionDisplayName(entry.key)),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _requestAllPermissions,
              child: const Text('Request All Permissions'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Setup Instructions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              '1. Gemini API: Your API key is already configured.\n'
              '2. Google Workspace: Create a Google Cloud project, enable Calendar/Tasks APIs.\n'
              '3. Permissions: Grant all required permissions for full functionality.\n'
              '4. Test the automation features in the main dashboard.',
              style: TextStyle(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  String _getPermissionDisplayName(String key) {
    switch (key) {
      case 'microphone':
        return 'Microphone (Call Recording)';
      case 'storage':
        return 'Storage (Save Recordings)';
      case 'calendar':
        return 'Calendar (Meeting Scheduling)';
      case 'notification':
        return 'Notifications (Smart Automation)';
      default:
        return key;
    }
  }

  @override
  void dispose() {
    _geminiController.dispose();
    _googleClientIdController.dispose();
    _googleClientSecretController.dispose();
    _googleServiceAccountController.dispose();
    super.dispose();
  }
}
