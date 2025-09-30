import 'package:flutter/material.dart';
import '../services/enhanced_call_transcript_service.dart';

/// Test widget for Call Transcript Dynamic Island
class CallTranscriptTestScreen extends StatefulWidget {
  const CallTranscriptTestScreen({Key? key}) : super(key: key);

  @override
  State<CallTranscriptTestScreen> createState() =>
      _CallTranscriptTestScreenState();
}

class _CallTranscriptTestScreenState extends State<CallTranscriptTestScreen> {
  bool _isTranscriptActive = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Call Transcript Test'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            const Text(
              '🎤 Dynamic Island Call Transcript Test',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Test the real-time transcript display in Android Dynamic Island',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Status
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isTranscriptActive
                    ? Colors.green.shade900
                    : Colors.grey.shade900,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isTranscriptActive ? Colors.green : Colors.grey,
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isTranscriptActive ? Icons.mic : Icons.mic_off,
                    color: _isTranscriptActive ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isTranscriptActive
                        ? 'Transcript Active'
                        : 'Transcript Inactive',
                    style: TextStyle(
                      color: _isTranscriptActive ? Colors.green : Colors.grey,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Control buttons
            _buildControlButton(
              title:
                  _isTranscriptActive ? 'Stop Transcript' : 'Start Transcript',
              icon: _isTranscriptActive ? Icons.stop : Icons.play_arrow,
              color: _isTranscriptActive ? Colors.red : Colors.green,
              onPressed: _toggleTranscript,
            ),

            if (_isTranscriptActive) ...[
              const SizedBox(height: 16),
              _buildControlButton(
                title: 'Test Incoming Message (Blue)',
                icon: Icons.call_received,
                color: Colors.blue,
                onPressed: () => _addTestMessage(SpeakerType.incoming),
              ),
              const SizedBox(height: 8),
              _buildControlButton(
                title: 'Test Outgoing Message (White)',
                icon: Icons.call_made,
                color: Colors.white,
                onPressed: () => _addTestMessage(SpeakerType.outgoing),
              ),
              const SizedBox(height: 8),
              _buildControlButton(
                title: 'Test System Message',
                icon: Icons.info,
                color: Colors.orange,
                onPressed: () => _addTestMessage(SpeakerType.system),
              ),
              const SizedBox(height: 16),
              _buildControlButton(
                title: 'Clear Transcript',
                icon: Icons.clear,
                color: Colors.grey,
                onPressed: _clearTranscript,
              ),
            ],

            const Spacer(),

            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '💡 How to test:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '1. Tap "Start Transcript" to activate Dynamic Island\n'
                    '2. Check the Dynamic Island appears at the top\n'
                    '3. Tap the test message buttons to see color coding:\n'
                    '   • Blue text for incoming caller\n'
                    '   • White text for you (outgoing)\n'
                    '   • Orange text for system messages\n'
                    '4. Tap Dynamic Island to expand and see full transcript\n'
                    '5. Long press to minimize back to pill state',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
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

  Widget _buildControlButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.black),
      label: Text(
        title,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<void> _toggleTranscript() async {
    try {
      if (_isTranscriptActive) {
        await EnhancedCallTranscriptService.stopCallTranscript();
        setState(() {
          _isTranscriptActive = false;
        });
        _showSnackBar('📴 Call transcript stopped', Colors.red);
      } else {
        final success =
            await EnhancedCallTranscriptService.startCallTranscript();
        if (success) {
          setState(() {
            _isTranscriptActive = true;
          });
          _showSnackBar('🎤 Call transcript started - Check Dynamic Island!',
              Colors.green);
        } else {
          _showSnackBar('❌ Failed to start transcript', Colors.red);
        }
      }
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    }
  }

  Future<void> _addTestMessage(SpeakerType speakerType) async {
    final messages = {
      SpeakerType.incoming: [
        "Hello, how are you today?",
        "I wanted to discuss the project timeline.",
        "Can we schedule a meeting for next week?",
        "That sounds great, thank you!",
      ],
      SpeakerType.outgoing: [
        "Hi there! I'm doing well, thanks for asking.",
        "Sure, I'd be happy to discuss that.",
        "Yes, next week works perfectly for me.",
        "You're welcome! Looking forward to it.",
      ],
      SpeakerType.system: [
        "Call quality is excellent",
        "Recording started",
        "Network connection stable",
        "Call duration: 2 minutes",
      ],
    };

    final messageList = messages[speakerType]!;
    final randomMessage = messageList[
        (messageList.length * DateTime.now().millisecond / 1000).floor() %
            messageList.length];

    try {
      await EnhancedCallTranscriptService.addTranscriptMessage(
        text: randomMessage,
        speakerType: speakerType,
      );

      final speakerName = speakerType == SpeakerType.incoming
          ? 'Caller'
          : speakerType == SpeakerType.outgoing
              ? 'You'
              : 'System';

      _showSnackBar('💬 Added: [$speakerName] $randomMessage', Colors.blue);
    } catch (e) {
      _showSnackBar('Error adding message: $e', Colors.red);
    }
  }

  Future<void> _clearTranscript() async {
    try {
      EnhancedCallTranscriptService.clearHistory();
      _showSnackBar('🗑️ Transcript cleared', Colors.grey);
    } catch (e) {
      _showSnackBar('Error clearing transcript: $e', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
