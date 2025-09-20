import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class LiveTranscriptOverlay extends StatefulWidget {
  final String currentTranscript;
  final bool isRecording;
  final VoidCallback onTap;
  final VoidCallback onStop;

  const LiveTranscriptOverlay({
    Key? key,
    required this.currentTranscript,
    required this.isRecording,
    required this.onTap,
    required this.onStop,
  }) : super(key: key);

  @override
  State<LiveTranscriptOverlay> createState() => _LiveTranscriptOverlayState();
}

class _LiveTranscriptOverlayState extends State<LiveTranscriptOverlay>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _expandController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _expandAnimation;
  late Animation<double> _fadeAnimation;

  bool _isExpanded = false;
  Timer? _autoCollapseTimer;

  @override
  void initState() {
    super.initState();

    // Pulse animation for recording indicator
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Expand animation for pill
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _expandController, curve: Curves.elasticOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _expandController, curve: Curves.easeInOut),
    );

    if (widget.isRecording) {
      _pulseController.repeat(reverse: true);
      _expandController.forward();
    }
  }

  @override
  void didUpdateWidget(LiveTranscriptOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isRecording && !oldWidget.isRecording) {
      _pulseController.repeat(reverse: true);
      _expandController.forward();
    } else if (!widget.isRecording && oldWidget.isRecording) {
      _pulseController.stop();
      _startAutoCollapseTimer();
    }

    if (widget.currentTranscript != oldWidget.currentTranscript &&
        widget.currentTranscript.isNotEmpty) {
      // Reset auto-collapse timer when new transcript comes
      _resetAutoCollapseTimer();
    }
  }

  void _resetAutoCollapseTimer() {
    _autoCollapseTimer?.cancel();
    _startAutoCollapseTimer();
  }

  void _startAutoCollapseTimer() {
    _autoCollapseTimer = Timer(const Duration(seconds: 3), () {
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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _expandAnimation,
      builder: (context, child) {
        if (_expandAnimation.value == 0.0) {
          return const SizedBox.shrink();
        }

        return Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          left: 16,
          right: 16,
          child: Transform.scale(
            scale: _expandAnimation.value,
            child: Material(
              color: Colors.transparent,
              child: GestureDetector(
                onTap: _onTap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.elasticOut,
                  height: _isExpanded ? 120 : 56,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(_isExpanded ? 20 : 28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
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
        );
      },
    );
  }

  Widget _buildCollapsedContent() {
    return Row(
      children: [
        // Recording indicator
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: widget.isRecording
                    ? Colors.red.withOpacity(_pulseAnimation.value)
                    : Colors.green,
                shape: BoxShape.circle,
              ),
            );
          },
        ),

        const SizedBox(width: 12),

        // Status text
        Expanded(
          child: Text(
            widget.isRecording
                ? 'Recording...'
                : (widget.currentTranscript.isEmpty
                    ? 'Tap to expand'
                    : 'Transcript ready'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // Waveform indicator
        if (widget.isRecording) _buildWaveform(),

        const SizedBox(width: 8),

        // Expand icon
        const Icon(
          Icons.keyboard_arrow_down,
          color: Colors.white70,
          size: 20,
        ),
      ],
    );
  }

  Widget _buildExpandedContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: widget.isRecording
                        ? Colors.red.withOpacity(_pulseAnimation.value)
                        : Colors.green,
                    shape: BoxShape.circle,
                  ),
                );
              },
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Text(
                widget.isRecording ? 'Live Transcript' : 'Call Transcript',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Stop button (only when recording)
            if (widget.isRecording)
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  widget.onStop();
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.stop,
                    color: Colors.red,
                    size: 16,
                  ),
                ),
              ),

            const SizedBox(width: 8),

            // Collapse icon
            const Icon(
              Icons.keyboard_arrow_up,
              color: Colors.white70,
              size: 20,
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Transcript content
        Expanded(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: widget.currentTranscript.isEmpty
                  ? const Text(
                      'Listening...',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  : Text(
                      widget.currentTranscript,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        height: 1.3,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWaveform() {
    return Row(
      children: List.generate(4, (index) {
        return AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Container(
              margin: const EdgeInsets.only(right: 2),
              width: 2,
              height:
                  (12 * _pulseAnimation.value * (index + 1) / 4).clamp(2, 12),
              decoration: BoxDecoration(
                color: Colors.white70,
                borderRadius: BorderRadius.circular(1),
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
    _autoCollapseTimer?.cancel();
    super.dispose();
  }
}

// Overlay Entry Manager for showing the transcript overlay
class TranscriptOverlayManager {
  static OverlayEntry? _overlayEntry;
  static bool _isVisible = false;

  static void show(
    BuildContext context, {
    required String transcript,
    required bool isRecording,
    required VoidCallback onTap,
    required VoidCallback onStop,
  }) {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
    }

    _overlayEntry = OverlayEntry(
      builder: (context) => LiveTranscriptOverlay(
        currentTranscript: transcript,
        isRecording: isRecording,
        onTap: onTap,
        onStop: onStop,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    _isVisible = true;
  }

  static void update({
    String? transcript,
    bool? isRecording,
  }) {
    if (_overlayEntry != null && _isVisible) {
      _overlayEntry!.markNeedsBuild();
    }
  }

  static void hide() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
      _isVisible = false;
    }
  }

  static bool get isVisible => _isVisible;
}
