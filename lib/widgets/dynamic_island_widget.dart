import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../services/call_overlay_service.dart';

// Provider for Dynamic Island state
final dynamicIslandProvider =
    StateNotifierProvider<DynamicIslandNotifier, DynamicIslandState>((ref) {
  return DynamicIslandNotifier();
});

class DynamicIslandState {
  final bool isVisible;
  final bool isExpanded;
  final bool isTranscribing;
  final String transcript;
  final String callState;
  final DateTime? lastUpdate;

  const DynamicIslandState({
    this.isVisible = false,
    this.isExpanded = false,
    this.isTranscribing = false,
    this.transcript = '',
    this.callState = 'idle',
    this.lastUpdate,
  });

  DynamicIslandState copyWith({
    bool? isVisible,
    bool? isExpanded,
    bool? isTranscribing,
    String? transcript,
    String? callState,
    DateTime? lastUpdate,
  }) {
    return DynamicIslandState(
      isVisible: isVisible ?? this.isVisible,
      isExpanded: isExpanded ?? this.isExpanded,
      isTranscribing: isTranscribing ?? this.isTranscribing,
      transcript: transcript ?? this.transcript,
      callState: callState ?? this.callState,
      lastUpdate: lastUpdate ?? this.lastUpdate,
    );
  }
}

class DynamicIslandNotifier extends StateNotifier<DynamicIslandState> {
  DynamicIslandNotifier() : super(const DynamicIslandState()) {
    _listenToOverlayEvents();
  }

  StreamSubscription? _eventSubscription;

  void _listenToOverlayEvents() {
    _eventSubscription = CallOverlayService.eventStream.listen((event) {
      final eventType = event['type'] as String?;

      switch (eventType) {
        case 'transcriptUpdate':
          final transcript = event['transcript'] as String? ?? '';
          updateTranscript(transcript);
          break;

        case 'callStateChanged':
          final callState = event['callState'] as String? ?? 'idle';
          updateCallState(callState);
          break;

        case 'overlayStateChanged':
          final isVisible = event['isVisible'] as bool? ?? false;
          final isExpanded = event['isExpanded'] as bool? ?? false;
          updateOverlayState(isVisible, isExpanded);
          break;

        case 'transcriptionStateChanged':
          final isTranscribing = event['isTranscribing'] as bool? ?? false;
          updateTranscriptionState(isTranscribing);
          break;

        case 'error':
          final errorType = event['errorType'] as String? ?? 'unknown';
          final errorMessage =
              event['errorMessage'] as String? ?? 'Unknown error';
          handleError(errorType, errorMessage);
          break;
      }
    });
  }

  void updateTranscript(String transcript) {
    state = state.copyWith(
      transcript: transcript,
      lastUpdate: DateTime.now(),
    );
  }

  void updateCallState(String callState) {
    state = state.copyWith(
      callState: callState,
      isVisible: callState != 'idle',
      lastUpdate: DateTime.now(),
    );
  }

  void updateOverlayState(bool isVisible, bool isExpanded) {
    state = state.copyWith(
      isVisible: isVisible,
      isExpanded: isExpanded,
      lastUpdate: DateTime.now(),
    );
  }

  void updateTranscriptionState(bool isTranscribing) {
    state = state.copyWith(
      isTranscribing: isTranscribing,
      lastUpdate: DateTime.now(),
    );
  }

  void handleError(String errorType, String errorMessage) {
    // Handle error - could show a snackbar or log
    print('Dynamic Island Error: $errorType - $errorMessage');
  }

  Future<void> toggleExpansion() async {
    if (state.isExpanded) {
      await CallOverlayService.collapseDynamicIsland();
    } else {
      await CallOverlayService.expandDynamicIsland();
    }
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }
}

class DynamicIslandWidget extends ConsumerWidget {
  const DynamicIslandWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dynamicIslandProvider);

    if (!state.isVisible) {
      return const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      child: state.isExpanded
          ? _buildExpandedIsland(context, ref, state)
          : _buildCompactIsland(context, ref, state),
    );
  }

  Widget _buildCompactIsland(
      BuildContext context, WidgetRef ref, DynamicIslandState state) {
    return GestureDetector(
      onTap: () => ref.read(dynamicIslandProvider.notifier).toggleExpansion(),
      child: Container(
        width: 120,
        height: 35,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.grey.shade900,
              Colors.grey.shade800,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.grey.shade700,
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (state.isTranscribing) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: _buildPulsingAnimation(),
              ),
              const SizedBox(width: 8),
            ],
            Icon(
              Icons.mic,
              color: Colors.white.withOpacity(0.8),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedIsland(
      BuildContext context, WidgetRef ref, DynamicIslandState state) {
    return GestureDetector(
      onTap: () => ref.read(dynamicIslandProvider.notifier).toggleExpansion(),
      child: Container(
        width: 320,
        constraints: const BoxConstraints(
          minHeight: 120,
          maxHeight: 200,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.grey.shade900,
              Colors.grey.shade800,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.grey.shade700,
            width: 0.5,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (state.isTranscribing) ...[
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: _buildPulsingAnimation(),
                  ),
                  const SizedBox(width: 12),
                ],
                Icon(
                  Icons.phone,
                  color: Colors.white.withOpacity(0.9),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Call in Progress',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    state.isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white.withOpacity(0.7),
                    size: 20,
                  ),
                  onPressed: () => ref
                      .read(dynamicIslandProvider.notifier)
                      .toggleExpansion(),
                ),
              ],
            ),
            if (state.transcript.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.grey.shade700.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.transcribe,
                          color: Colors.blue.shade300,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Live Transcript',
                          style: TextStyle(
                            color: Colors.blue.shade300,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.transcript,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        height: 1.4,
                      ),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ] else if (state.isTranscribing) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.blue.shade300,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Listening...',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (state.callState != 'idle') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    color: Colors.white.withOpacity(0.6),
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatCallDuration(state.lastUpdate),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPulsingAnimation() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 1.0),
      duration: const Duration(milliseconds: 1500),
      builder: (context, value, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(value),
            shape: BoxShape.circle,
          ),
        );
      },
      onEnd: () {
        // Restart animation
      },
    );
  }

  String _formatCallDuration(DateTime? startTime) {
    if (startTime == null) return '';

    final duration = DateTime.now().difference(startTime);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
