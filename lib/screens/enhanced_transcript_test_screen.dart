import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/enhanced_call_transcript_service.dart';
import '../widgets/enhanced_live_transcript_overlay.dart';

/// Test screen for enhanced call transcript with color-coded messages
class EnhancedTranscriptTestScreen extends StatefulWidget {
  const EnhancedTranscriptTestScreen({Key? key}) : super(key: key);

  @override
  State<EnhancedTranscriptTestScreen> createState() =>
      _EnhancedTranscriptTestScreenState();
}

class _EnhancedTranscriptTestScreenState
    extends State<EnhancedTranscriptTestScreen> {
  bool _isTranscriptActive = false;

  final List<TranscriptMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _listenToTranscript();
  }

  void _checkPermissions() async {
    // Check overlay permission
    // In a real implementation, you'd check actual permissions
    // For demo purposes, we assume permissions are granted
  }

  void _listenToTranscript() {
    EnhancedCallTranscriptService.transcriptStream.listen((message) {
      setState(() {
        _messages.add(message);
        if (_messages.length > 20) {
          _messages.removeAt(0);
        }
      });
    });
  }

  Future<void> _startTranscript() async {
    final success = await EnhancedCallTranscriptService.startCallTranscript();
    if (success && mounted) {
      setState(() {
        _isTranscriptActive = true;
        _messages.clear();
      });

      // Show overlay
      EnhancedTranscriptOverlayManager.show(
        context,
        onTap: () {
          print('Transcript overlay tapped');
        },
        onStop: _stopTranscript,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('📞 Enhanced transcript started - Check dynamic island!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Simulate some demo messages
      _simulateDemoMessages();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to start transcript'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _stopTranscript() async {
    await EnhancedCallTranscriptService.stopCallTranscript();
    EnhancedTranscriptOverlayManager.hide();

    setState(() {
      _isTranscriptActive = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⏹ Enhanced transcript stopped'),
        ),
      );
    }
  }

  void _simulateDemoMessages() {
    // Simulate incoming and outgoing messages for demonstration
    Future.delayed(const Duration(seconds: 2), () {
      if (_isTranscriptActive) {
        EnhancedCallTranscriptService.addTranscriptMessage(
          text: "Hello, this is John calling about the project update.",
          speakerType: SpeakerType.incoming,
        );
      }
    });

    Future.delayed(const Duration(seconds: 5), () {
      if (_isTranscriptActive) {
        EnhancedCallTranscriptService.addTranscriptMessage(
          text:
              "Hi John! Thanks for calling. I have the latest status ready to share.",
          speakerType: SpeakerType.outgoing,
        );
      }
    });

    Future.delayed(const Duration(seconds: 8), () {
      if (_isTranscriptActive) {
        EnhancedCallTranscriptService.addTranscriptMessage(
          text: "Great! Can you walk me through the main highlights?",
          speakerType: SpeakerType.incoming,
        );
      }
    });

    Future.delayed(const Duration(seconds: 11), () {
      if (_isTranscriptActive) {
        EnhancedCallTranscriptService.addTranscriptMessage(
          text:
              "Absolutely. We've completed the UI redesign and are now working on the backend integration.",
          speakerType: SpeakerType.outgoing,
        );
      }
    });

    Future.delayed(const Duration(seconds: 15), () {
      if (_isTranscriptActive) {
        EnhancedCallTranscriptService.addTranscriptMessage(
          text: "That sounds excellent. What's the timeline looking like?",
          speakerType: SpeakerType.incoming,
        );
      }
    });
  }

  void _addManualMessage(SpeakerType speakerType) {
    final controllers = {
      SpeakerType.incoming: TextEditingController(
          text: "This is an incoming message from the caller."),
      SpeakerType.outgoing: TextEditingController(
          text: "This is your outgoing message response."),
      SpeakerType.system:
          TextEditingController(text: "System: Call quality is excellent."),
    };

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add ${speakerType.name.capitalize()} Message'),
        content: TextField(
          controller: controllers[speakerType],
          decoration: const InputDecoration(
            labelText: 'Message text',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final text = controllers[speakerType]!.text;
              if (text.isNotEmpty) {
                EnhancedCallTranscriptService.addTranscriptMessage(
                  text: text,
                  speakerType: speakerType,
                );
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Color _getSpeakerColor(SpeakerType speakerType) {
    switch (speakerType) {
      case SpeakerType.incoming:
        return Colors.blue;
      case SpeakerType.outgoing:
        return Colors.grey.shade800;
      case SpeakerType.system:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enhanced Transcript Test'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              setState(() {
                _messages.clear();
              });
            },
            icon: const Icon(Icons.clear_all),
            tooltip: 'Clear Messages',
          ),
        ],
      ),
      body: Column(
        children: [
          // Status Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      _isTranscriptActive
                          ? Icons.record_voice_over
                          : Icons.voice_over_off,
                      color: _isTranscriptActive ? Colors.red : Colors.grey,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isTranscriptActive
                                ? 'Enhanced Transcript Active'
                                : 'Enhanced Transcript Inactive',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isTranscriptActive
                                ? 'Real-time transcription with color coding is active'
                                : 'Start transcript to see dynamic island with colored text',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Color Legend
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Speaker Color Legend:',
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildLegendItem('Incoming (Blue)', Colors.blue),
                          _buildLegendItem(
                              'Outgoing (White)', Colors.grey.shade700),
                          _buildLegendItem('System (Orange)', Colors.orange),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Control Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isTranscriptActive
                        ? _stopTranscript
                        : _startTranscript,
                    icon: Icon(
                        _isTranscriptActive ? Icons.stop : Icons.play_arrow),
                    label: Text(_isTranscriptActive
                        ? 'Stop Transcript'
                        : 'Start Transcript'),
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          _isTranscriptActive ? Colors.red : Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Manual Message Buttons (for testing)
          if (_isTranscriptActive)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _addManualMessage(SpeakerType.incoming),
                      icon: const Icon(Icons.call_received, color: Colors.blue),
                      label: const Text('Add Incoming'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _addManualMessage(SpeakerType.outgoing),
                      icon: Icon(Icons.call_made, color: Colors.grey.shade700),
                      label: const Text('Add Outgoing'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _addManualMessage(SpeakerType.system),
                      icon: const Icon(Icons.info, color: Colors.orange),
                      label: const Text('Add System'),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Message History
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Message History',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _messages.isEmpty
                        ? Center(
                            child: Text(
                              'No messages yet.\nStart transcript and messages will appear here.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.7),
                                  ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final message = _messages[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _getSpeakerColor(message.speakerType)
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _getSpeakerColor(message.speakerType)
                                        .withOpacity(0.3),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: _getSpeakerColor(
                                                message.speakerType),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          message.speaker,
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: _getSpeakerColor(
                                                    message.speakerType),
                                              ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          DateTime.parse(message.timestamp)
                                              .toString()
                                              .substring(11, 19),
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      message.text,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
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
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }
}

extension StringCapitalization on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}
