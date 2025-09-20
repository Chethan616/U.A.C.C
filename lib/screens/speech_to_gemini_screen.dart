import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/gemini_speech_service.dart';
import '../widgets/task_card.dart';
import '../widgets/event_card.dart';

class SpeechToGeminiScreen extends StatefulWidget {
  const SpeechToGeminiScreen({Key? key}) : super(key: key);

  @override
  State<SpeechToGeminiScreen> createState() => _SpeechToGeminiScreenState();
}

class _SpeechToGeminiScreenState extends State<SpeechToGeminiScreen>
    with TickerProviderStateMixin {
  final GeminiSpeechService _speechService = GeminiSpeechService();
  final TextEditingController _instructionsController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isInitialized = false;
  bool _isProcessing = false;
  String _currentTranscript = '';
  String _status = 'Ready';
  GeminiResponse? _lastResponse;
  String? _error;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
    _setupAnimations();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _initializeSpeech() async {
    try {
      setState(() => _status = 'Initializing speech recognition...');

      final initialized = await _speechService.initializeSpeech();

      if (initialized) {
        setState(() {
          _isInitialized = true;
          _status = 'Ready to record';
        });
      } else {
        setState(() {
          _error = 'Speech recognition not available on this device';
          _status = 'Error';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to initialize: $e';
        _status = 'Error';
      });
    }
  }

  Future<void> _startRecording() async {
    if (!_isInitialized) return;

    setState(() {
      _isProcessing = true;
      _currentTranscript = '';
      _error = null;
      _status = 'Listening...';
    });

    _pulseController.repeat();

    try {
      final response = await _speechService.recordAndProcess(
        instructions: _instructionsController.text.trim().isEmpty
            ? null
            : _instructionsController.text.trim(),
        onTranscriptUpdate: (transcript) {
          setState(() {
            _currentTranscript = transcript;
          });
        },
      );

      setState(() {
        _lastResponse = response;
        _status = 'Processing complete';
        _isProcessing = false;
      });

      _scrollToResults();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _status = 'Error';
        _isProcessing = false;
      });
    } finally {
      _pulseController.stop();
    }
  }

  void _stopRecording() {
    _speechService.stopListening();
    _pulseController.stop();
    setState(() {
      _isProcessing = false;
      _status =
          _currentTranscript.isEmpty ? 'No speech detected' : 'Processing...';
    });
  }

  void _scrollToResults() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _clearResults() {
    setState(() {
      _lastResponse = null;
      _currentTranscript = '';
      _error = null;
      _status = 'Ready to record';
    });
  }

  @override
  void dispose() {
    _speechService.dispose();
    _instructionsController.dispose();
    _scrollController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice to Tasks'),
        elevation: 0,
        actions: [
          if (_lastResponse != null)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: _clearResults,
              tooltip: 'Clear results',
            ),
        ],
      ),
      body: user == null ? _buildSignInPrompt() : _buildMainContent(),
    );
  }

  Widget _buildSignInPrompt() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_circle,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Please sign in to use voice features',
            style: TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        _buildControlPanel(),
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_currentTranscript.isNotEmpty) _buildTranscriptSection(),
                if (_error != null) _buildErrorSection(),
                if (_lastResponse != null) _buildResultsSection(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControlPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status display
          Row(
            children: [
              Icon(
                _getStatusIcon(),
                color: _getStatusColor(),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _status,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: _getStatusColor(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Instructions input
          TextField(
            controller: _instructionsController,
            decoration: const InputDecoration(
              labelText: 'Special instructions (optional)',
              hintText:
                  'e.g., "Focus on urgent tasks" or "Include location details"',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            maxLines: 2,
            enabled: !_isProcessing,
          ),

          const SizedBox(height: 16),

          // Record button
          Center(
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _isProcessing ? _pulseAnimation.value : 1.0,
                  child: FloatingActionButton.extended(
                    onPressed: _isInitialized && !_isProcessing
                        ? _startRecording
                        : _isProcessing
                            ? _stopRecording
                            : null,
                    icon: Icon(_isProcessing ? Icons.stop : Icons.mic),
                    label: Text(
                        _isProcessing ? 'Stop Recording' : 'Start Recording'),
                    backgroundColor: _isProcessing
                        ? Colors.red
                        : Theme.of(context).primaryColor,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranscriptSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Transcript',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).dividerColor,
            ),
          ),
          child: Text(
            _currentTranscript,
            style: const TextStyle(fontSize: 16),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildErrorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.error, color: Colors.red.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _error!,
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildResultsSection() {
    final response = _lastResponse!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Results',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Summary
        if (response.summary.isNotEmpty) ...[
          _buildSectionHeader('Summary', Icons.summarize),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              response.summary,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Tasks
        if (response.tasks.isNotEmpty) ...[
          _buildSectionHeader('Tasks', Icons.task_alt),
          ...response.tasks.map((task) => TaskCard(task: task)).toList(),
          const SizedBox(height: 24),
        ],

        // Events
        if (response.events.isNotEmpty) ...[
          _buildSectionHeader('Calendar Events', Icons.event),
          ...response.events.map((event) => EventCard(event: event)).toList(),
          const SizedBox(height: 24),
        ],

        // Raw response (if available)
        if (response.rawResponse != null) ...[
          ExpansionTile(
            title: const Text('Raw Response'),
            subtitle: const Text('Debug information'),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: SelectableText(
                  response.rawResponse!,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon() {
    if (_isProcessing) return Icons.mic;
    if (_error != null) return Icons.error;
    if (_lastResponse != null) return Icons.check_circle;
    return Icons.mic_none;
  }

  Color _getStatusColor() {
    if (_isProcessing) return Colors.red;
    if (_error != null) return Colors.red;
    if (_lastResponse != null) return Colors.green;
    return Colors.grey;
  }
}
