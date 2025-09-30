import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/live_transcript_service.dart';

class LiveTranscriptTestScreen extends ConsumerStatefulWidget {
  const LiveTranscriptTestScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LiveTranscriptTestScreen> createState() =>
      _LiveTranscriptTestScreenState();
}

class _LiveTranscriptTestScreenState
    extends ConsumerState<LiveTranscriptTestScreen> {
  bool _isRecording = false;
  final List<String> _mockTranscriptLines = [
    "Hello, how can I help you today?",
    "I'm calling about my order status.",
    "Let me check that for you right away.",
    "Your order is currently being prepared.",
    "It should be ready for pickup in about 15 minutes.",
    "Great! Thank you for the update.",
    "Is there anything else I can help you with?",
    "No, that's all for now. Thanks!",
  ];
  int _currentMockIndex = 0;

  @override
  void initState() {
    super.initState();
    _checkTranscriptStatus();
  }

  Future<void> _checkTranscriptStatus() async {
    final isActive = await LiveTranscriptService.isTranscriptActive();
    setState(() {
      _isRecording = isActive;
    });
  }

  Future<void> _startTranscript() async {
    final success = await LiveTranscriptManager.startRecording();
    if (success) {
      setState(() {
        _isRecording = true;
        _currentMockIndex = 0;
      });

      // Start mock transcript simulation
      _simulateMockTranscript();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('🎤 Live transcript started - Check notification panel!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to start live transcript'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _stopTranscript() async {
    final success = await LiveTranscriptManager.stopRecording();
    if (success) {
      setState(() {
        _isRecording = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⏹ Live transcript stopped'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _simulateMockTranscript() {
    if (!_isRecording || _currentMockIndex >= _mockTranscriptLines.length) {
      return;
    }

    Future.delayed(const Duration(seconds: 3), () {
      if (_isRecording && _currentMockIndex < _mockTranscriptLines.length) {
        final line = _mockTranscriptLines[_currentMockIndex];
        LiveTranscriptManager.addTranscriptLine(line);
        _currentMockIndex++;

        // Continue simulation
        _simulateMockTranscript();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        title: const Text('Live Transcript Test'),
        actions: [
          if (_isRecording)
            Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.fiber_manual_record,
                      color: Colors.white, size: 12),
                  SizedBox(width: 4),
                  Text('LIVE',
                      style: TextStyle(color: Colors.white, fontSize: 12)),
                ],
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(),
            const SizedBox(height: 16),
            _buildInstructionsCard(),
            const SizedBox(height: 16),
            _buildTranscriptHistory(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isRecording ? _stopTranscript : _startTranscript,
        backgroundColor: _isRecording ? Colors.red : Colors.green,
        icon: Icon(_isRecording ? Icons.stop : Icons.play_arrow),
        label:
            Text(_isRecording ? 'Stop Live Activity' : 'Start Live Activity'),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              _isRecording ? Icons.record_voice_over : Icons.voice_over_off,
              size: 48,
              color: _isRecording ? Colors.red : Colors.grey,
            ),
            const SizedBox(height: 12),
            Text(
              _isRecording
                  ? 'Live Transcript Active'
                  : 'Live Transcript Inactive',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _isRecording ? Colors.green : Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _isRecording
                  ? 'Check your notification panel for the live capsule (like Zomato delivery tracking)'
                  : 'Tap the button below to start the live transcript activity',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'How it works (Like Zomato Live Activities)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InstructionStep(
                  number: '1',
                  text: 'Start the live transcript by tapping the button',
                ),
                InstructionStep(
                  number: '2',
                  text:
                      'A persistent notification appears (like Zomato delivery)',
                ),
                InstructionStep(
                  number: '3',
                  text: 'On OxygenOS, it may show as a capsule/Live Activity',
                ),
                InstructionStep(
                  number: '4',
                  text: 'Mock transcript updates will appear in real-time',
                ),
                InstructionStep(
                  number: '5',
                  text: 'Works even if you close the app completely!',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTranscriptHistory() {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.history, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Transcript History',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: LiveTranscriptManager.transcriptHistory.length,
                itemBuilder: (context, index) {
                  final entry = LiveTranscriptManager.transcriptHistory[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${entry.timestamp.hour.toString().padLeft(2, '0')}:${entry.timestamp.minute.toString().padLeft(2, '0')}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            entry.text,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InstructionStep extends StatelessWidget {
  final String number;
  final String text;

  const InstructionStep({
    Key? key,
    required this.number,
    required this.text,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
