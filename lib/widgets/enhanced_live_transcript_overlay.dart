import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/enhanced_call_transcript_service.dart';
import 'dart:async';

/// Enhanced live transcript overlay with speaker color coding
class EnhancedLiveTranscriptOverlay extends StatefulWidget {
  final List<TranscriptMessage> recentMessages;
  final bool isRecording;
  final VoidCallback onTap;
  final VoidCallback onStop;

  const EnhancedLiveTranscriptOverlay({
    Key? key,
    required this.recentMessages,
    required this.isRecording,
    required this.onTap,
    required this.onStop,
  }) : super(key: key);

  @override
  State<EnhancedLiveTranscriptOverlay> createState() =>
      _EnhancedLiveTranscriptOverlayState();
}

class _EnhancedLiveTranscriptOverlayState
    extends State<EnhancedLiveTranscriptOverlay> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _expandController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _expandAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isExpanded = false;
  Timer? _autoCollapseTimer;

  @override
  void initState() {
    super.initState();

    // Pulse animation for recording indicator
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Expand animation for the overlay
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _expandAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _expandController, curve: Curves.elasticOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _expandController, curve: Curves.easeInOut),
    );

    // Slide animation for new messages
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.elasticOut));

    if (widget.isRecording) {
      _pulseController.repeat(reverse: true);
      _expandController.forward();
      _slideController.forward();
    }
  }

  @override
  void didUpdateWidget(EnhancedLiveTranscriptOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isRecording && !oldWidget.isRecording) {
      _pulseController.repeat(reverse: true);
      _expandController.forward();
      _slideController.forward();
    } else if (!widget.isRecording && oldWidget.isRecording) {
      _pulseController.stop();
      _startAutoCollapseTimer();
    }

    // Animate when new messages arrive
    if (widget.recentMessages.length > oldWidget.recentMessages.length) {
      _resetAutoCollapseTimer();
      _slideController.reset();
      _slideController.forward();
    }
  }

  void _resetAutoCollapseTimer() {
    _autoCollapseTimer?.cancel();
    _startAutoCollapseTimer();
  }

  void _startAutoCollapseTimer() {
    _autoCollapseTimer = Timer(const Duration(seconds: 4), () {
      if (!widget.isRecording && mounted) {
        _collapse();
      }
    });
  }

  void _expand() {
    setState(() {
      _isExpanded = true;
    });
    _autoCollapseTimer?.cancel();
    HapticFeedback.lightImpact();
  }

  void _collapse() {
    setState(() {
      _isExpanded = false;
    });
    _startAutoCollapseTimer();
  }

  void _onTap() {
    if (_isExpanded) {
      _collapse();
    } else {
      _expand();
    }
    widget.onTap();
  }

  Color _getSpeakerColor(SpeakerType speakerType) {
    switch (speakerType) {
      case SpeakerType.incoming:
        return Colors.blue.shade300; // Blue for incoming
      case SpeakerType.outgoing:
        return Colors.white; // White for outgoing (user)
      case SpeakerType.system:
        return Colors.grey.shade400; // Gray for system
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _expandAnimation,
      builder: (context, child) {
        if (_expandAnimation.value == 0.0) {
          return const SizedBox.shrink();
        }

        return Positioned(
          top: MediaQuery.of(context).padding.top + 12,
          left: 16,
          right: 16,
          child: SlideTransition(
            position: _slideAnimation,
            child: Transform.scale(
              scale: _expandAnimation.value,
              child: Material(
                color: Colors.transparent,
                child: GestureDetector(
                  onTap: _onTap,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.elasticOut,
                    height: _isExpanded ? 160 : 64,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.black.withOpacity(0.9),
                          Colors.black.withOpacity(0.8),
                        ],
                      ),
                      borderRadius:
                          BorderRadius.circular(_isExpanded ? 24 : 32),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 24,
                          spreadRadius: 4,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: _isExpanded
                        ? _buildExpandedContent()
                        : _buildCollapsedContent(),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCollapsedContent() {
    final latestMessage =
        widget.recentMessages.isNotEmpty ? widget.recentMessages.last : null;

    return Row(
      children: [
        // Recording indicator with enhanced animation
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: widget.isRecording
                    ? Colors.red.withOpacity(_pulseAnimation.value)
                    : Colors.green.withOpacity(0.8),
                shape: BoxShape.circle,
                boxShadow: widget.isRecording
                    ? [
                        BoxShadow(
                          color: Colors.red
                              .withOpacity(0.3 * _pulseAnimation.value),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
            );
          },
        ),

        const SizedBox(width: 12),

        // Live transcript preview
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.isRecording ? 'Live Transcript' : 'Transcript Ready',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (latestMessage != null) ...[
                const SizedBox(height: 2),
                Text(
                  '${latestMessage.speaker}: ${latestMessage.text}',
                  style: TextStyle(
                    color: _getSpeakerColor(latestMessage.speakerType)
                        .withOpacity(0.8),
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),

        // Audio waveform animation
        if (widget.isRecording) _buildEnhancedWaveform(),

        const SizedBox(width: 8),

        // Expand indicator
        Icon(
          _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
          color: Colors.white.withOpacity(0.7),
          size: 20,
        ),
      ],
    );
  }

  Widget _buildExpandedContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Enhanced header
        Row(
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: widget.isRecording
                        ? Colors.red.withOpacity(_pulseAnimation.value)
                        : Colors.green.withOpacity(0.8),
                    shape: BoxShape.circle,
                    boxShadow: widget.isRecording
                        ? [
                            BoxShadow(
                              color: Colors.red
                                  .withOpacity(0.3 * _pulseAnimation.value),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                );
              },
            ),

            const SizedBox(width: 12),

            const Expanded(
              child: Text(
                'Call Transcript',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Color legend
            Row(
              children: [
                _buildColorLegend('You', Colors.white),
                const SizedBox(width: 8),
                _buildColorLegend('Caller', Colors.blue.shade300),
              ],
            ),

            const SizedBox(width: 12),

            // Stop button
            if (widget.isRecording)
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  widget.onStop();
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.stop,
                    color: Colors.red,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 12),

        // Enhanced transcript content with color coding
        Expanded(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: widget.recentMessages.isEmpty
                  ? Center(
                      child: Text(
                        widget.isRecording
                            ? 'Listening...'
                            : 'No transcript yet',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: widget.recentMessages
                            .take(5) // Show last 5 messages
                            .map((message) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: '${message.speaker}: ',
                                          style: TextStyle(
                                            color: _getSpeakerColor(
                                                    message.speakerType)
                                                .withOpacity(0.9),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        TextSpan(
                                          text: message.text,
                                          style: TextStyle(
                                            color: _getSpeakerColor(
                                                message.speakerType),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w400,
                                            fontStyle: message.isFinal
                                                ? FontStyle.normal
                                                : FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildColorLegend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedWaveform() {
    return Row(
      children: List.generate(5, (index) {
        return AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final heightMultiplier = (index + 1) / 5;
            final animationDelay = index * 0.2;
            final adjustedAnimation =
                (_pulseAnimation.value + animationDelay) % 1.0;

            return Container(
              margin: const EdgeInsets.only(right: 2),
              width: 3,
              height: (16 * adjustedAnimation * heightMultiplier).clamp(4, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.red.withOpacity(0.8),
                    Colors.red.withOpacity(0.4),
                  ],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          },
        );
      }),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _expandController.dispose();
    _slideController.dispose();
    _autoCollapseTimer?.cancel();
    super.dispose();
  }
}

/// Manager for the enhanced transcript overlay
class EnhancedTranscriptOverlayManager {
  static OverlayEntry? _overlayEntry;
  static bool _isVisible = false;
  static StreamSubscription<TranscriptMessage>? _transcriptSubscription;
  static final List<TranscriptMessage> _recentMessages = [];

  static void show(
    BuildContext context, {
    required VoidCallback onTap,
    required VoidCallback onStop,
  }) {
    if (_overlayEntry != null) {
      hide();
    }

    _overlayEntry = OverlayEntry(
      builder: (context) => EnhancedLiveTranscriptOverlay(
        recentMessages: _recentMessages,
        isRecording: EnhancedCallTranscriptService.isListening,
        onTap: onTap,
        onStop: onStop,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    _isVisible = true;

    // Subscribe to transcript updates
    _transcriptSubscription =
        EnhancedCallTranscriptService.transcriptStream.listen((message) {
      _recentMessages.add(message);

      // Keep only recent messages (last 10)
      if (_recentMessages.length > 10) {
        _recentMessages.removeAt(0);
      }

      // Trigger rebuild
      _overlayEntry?.markNeedsBuild();
    });
  }

  static void hide() {
    _transcriptSubscription?.cancel();
    _transcriptSubscription = null;

    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
      _isVisible = false;
    }

    _recentMessages.clear();
  }

  static bool get isVisible => _isVisible;
}
