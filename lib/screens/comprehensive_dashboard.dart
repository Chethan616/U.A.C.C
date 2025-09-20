import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/live_transcript_overlay.dart';

class ComprehensiveDashboard extends ConsumerStatefulWidget {
  const ComprehensiveDashboard({Key? key}) : super(key: key);

  @override
  ConsumerState<ComprehensiveDashboard> createState() => _ComprehensiveDashboardState();
}

class _ComprehensiveDashboardState extends ConsumerState<ComprehensiveDashboard>
    with TickerProviderStateMixin {
  
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _isRecording = false;
  String _currentTranscript = '';

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));
    
    _slideController.forward();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    // Show permission request screen if needed
    final hasPermissions = await _checkAllPermissions();
    if (!hasPermissions) {
      if (mounted) {
        Navigator.pushNamed(context, '/permission-request');
      }
    }
  }

  Future<bool> _checkAllPermissions() async {
    // Mock permission check - in real app would check actual permissions
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF0A0A0A),
                  const Color(0xFF1A1A1A).withOpacity(0.8),
                  const Color(0xFF0A0A0A),
                ],
                stops: const [0.0, 0.3, 1.0],
              ),
            ),
          ),
          
          // Main content
          SafeArea(
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: _buildDashboardContent(),
                  ),
                ],
              ),
            ),
          ),
          
          // Live transcript overlay
          if (_isRecording || _currentTranscript.isNotEmpty)
            LiveTranscriptOverlay(
              currentTranscript: _currentTranscript,
              isRecording: _isRecording,
              onTap: _handleOverlayTap,
              onStop: _stopRecording,
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const Expanded(
                child: Text(
                  'AI Control Center',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white),
                onPressed: _showSettings,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatusIndicators(),
        ],
      ),
    );
  }

  Widget _buildStatusIndicators() {
    return Row(
      children: [
        _buildStatusChip('AI Ready', Colors.green, Icons.smart_toy),
        const SizedBox(width: 12),
        _buildStatusChip('Listening', Colors.blue, Icons.hearing),
        const SizedBox(width: 12),
        _buildStatusChip('Connected', const Color(0xFF6C63FF), Icons.cloud_done),
      ],
    );
  }

  Widget _buildStatusChip(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuickActions(),
          const SizedBox(height: 24),
          _buildRecentActivity(),
          const SizedBox(height: 24),
          _buildAutomationStats(),
          const SizedBox(height: 24),
          _buildSmartInsights(),
          const SizedBox(height: 100), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Call Logs',
                Icons.call,
                'View & analyze calls',
                const Color(0xFF4CAF50),
                () => Navigator.pushNamed(context, '/call-logs'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                'Notifications',
                Icons.notifications_active,
                'Smart summaries',
                const Color(0xFF2196F3),
                () => Navigator.pushNamed(context, '/notifications'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Calendar',
                Icons.calendar_today,
                'Meetings & tasks',
                const Color(0xFFFF9800),
                () => Navigator.pushNamed(context, '/full-calendar'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                'Start Recording',
                _isRecording ? Icons.stop : Icons.mic,
                _isRecording ? 'Stop recording' : 'Voice recording',
                _isRecording ? Colors.red : const Color(0xFF6C63FF),
                _toggleRecording,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, String subtitle, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: _isRecording && icon == Icons.stop ? _pulseController : _slideController,
        builder: (context, child) {
          return Transform.scale(
            scale: _isRecording && icon == Icons.stop ? _pulseAnimation.value : 1.0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withOpacity(0.2),
                    color.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: color.withOpacity(0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 32, color: color),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {},
              child: const Text(
                'View All',
                style: TextStyle(color: Color(0xFF6C63FF)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildActivityItem(
          'Call from John Doe',
          '5 minutes ago',
          Icons.call_received,
          Colors.green,
          'AI Summary: Business call about project timeline',
        ),
        _buildActivityItem(
          'WhatsApp message',
          '12 minutes ago',
          Icons.message,
          Colors.blue,
          'Auto-reply sent: "I\'ll get back to you shortly"',
        ),
        _buildActivityItem(
          'Meeting scheduled',
          '1 hour ago',
          Icons.calendar_today,
          Colors.orange,
          'Added to calendar: Team standup at 3 PM',
        ),
      ],
    );
  }

  Widget _buildActivityItem(String title, String time, IconData icon, Color color, String summary) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  summary,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutomationStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Automation Stats',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildStatCard('Calls Analyzed', '47', Icons.call, Colors.green)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('Messages', '156', Icons.message, Colors.blue)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('Time Saved', '2.5h', Icons.timer, const Color(0xFF6C63FF))),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartInsights() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Smart Insights',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF6C63FF).withOpacity(0.2),
                const Color(0xFF6C63FF).withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF6C63FF).withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.auto_awesome, color: Color(0xFF6C63FF)),
                  SizedBox(width: 12),
                  Text(
                    'AI Recommendations',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildInsightItem('📞', 'You have 3 missed calls that may need follow-up'),
              _buildInsightItem('📅', 'Schedule a meeting with John about the project update'),
              _buildInsightItem('💡', 'Your response time to messages improved by 40% this week'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInsightItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleRecording() async {
    HapticFeedback.mediumImpact();
    
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    try {
      setState(() {
        _isRecording = true;
        _currentTranscript = '';
      });
      
      _pulseController.repeat(reverse: true);
      
      // Show overlay
      TranscriptOverlayManager.show(
        context,
        transcript: _currentTranscript,
        isRecording: _isRecording,
        onTap: _handleOverlayTap,
        onStop: _stopRecording,
      );
      
      // Simulate transcript updates
      _simulateTranscript();
      
    } catch (e) {
      _showError('Failed to start recording: $e');
      setState(() {
        _isRecording = false;
      });
    }
  }

  Future<void> _stopRecording() async {
    setState(() {
      _isRecording = false;
    });
    
    _pulseController.stop();
    _pulseController.reset();
    
    HapticFeedback.heavyImpact();
    
    // Keep overlay visible for a moment to show final transcript
    await Future.delayed(const Duration(seconds: 2));
    TranscriptOverlayManager.hide();
    
    if (_currentTranscript.isNotEmpty) {
      _showTranscriptSaved();
    }
  }

  void _simulateTranscript() {
    if (!_isRecording) return;
    
    final transcriptParts = [
      'Hello, how are you doing today?',
      'I wanted to discuss the project timeline with you.',
      'We need to schedule a meeting for next week.',
      'Can you check your calendar and let me know?',
      'The deadline is approaching quickly.',
      'We should coordinate with the team as well.',
    ];
    
    int currentPart = 0;
    
    void addNextPart() {
      if (!_isRecording || currentPart >= transcriptParts.length) return;
      
      setState(() {
        if (_currentTranscript.isNotEmpty) {
          _currentTranscript += ' ${transcriptParts[currentPart]}';
        } else {
          _currentTranscript = transcriptParts[currentPart];
        }
      });
      
      TranscriptOverlayManager.update(
        transcript: _currentTranscript,
        isRecording: _isRecording,
      );
      
      currentPart++;
      
      if (currentPart < transcriptParts.length) {
        Future.delayed(const Duration(seconds: 3), addNextPart);
      }
    }
    
    // Start after 2 seconds
    Future.delayed(const Duration(seconds: 2), addNextPart);
  }

  void _handleOverlayTap() {
    HapticFeedback.lightImpact();
    // Overlay handles its own expand/collapse
  }

  void _showTranscriptSaved() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('Call transcript saved and analyzed'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () {
            Navigator.pushNamed(context, '/call-logs');
          },
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildSettingsSheet(),
    );
  }

  Widget _buildSettingsSheet() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.only(top: 12),
          decoration: BoxDecoration(
            color: Colors.white30,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Dashboard Settings',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.key, color: Colors.white),
          title: const Text('API Keys', style: TextStyle(color: Colors.white)),
          subtitle: const Text('Manage API configurations', style: TextStyle(color: Colors.white70)),
          onTap: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/api-keys');
          },
        ),
        ListTile(
          leading: const Icon(Icons.cloud, color: Colors.white),
          title: const Text('Google Workspace', style: TextStyle(color: Colors.white)),
          subtitle: const Text('Test integrations', style: TextStyle(color: Colors.white70)),
          onTap: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/workspace-test');
          },
        ),
        ListTile(
          leading: const Icon(Icons.security, color: Colors.white),
          title: const Text('Permissions', style: TextStyle(color: Colors.white)),
          subtitle: const Text('Review app permissions', style: TextStyle(color: Colors.white70)),
          onTap: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/permission-request');
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    TranscriptOverlayManager.hide();
    super.dispose();
  }
}