import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class BackgroundAgentState {
  final String? taskId;
  final String? prompt;
  final String status;

  const BackgroundAgentState({
    this.taskId,
    this.prompt,
    this.status = 'idle',
  });

  BackgroundAgentState copyWith({
    String? taskId,
    String? prompt,
    String? status,
    bool clearTask = false,
  }) {
    return BackgroundAgentState(
      taskId: clearTask ? null : (taskId ?? this.taskId),
      prompt: clearTask ? null : (prompt ?? this.prompt),
      status: status ?? this.status,
    );
  }

  bool get isRunning => status == 'running';
  bool get isDone => status == 'done';
  bool get isFailed => status == 'failed';
  bool get isIdle => status == 'idle';
}

class BackgroundAgentNotifier extends StateNotifier<BackgroundAgentState> {
  Timer? _pollTimer;

  BackgroundAgentNotifier() : super(const BackgroundAgentState());

  void start({required String taskId, required String prompt}) {
    state = BackgroundAgentState(
      taskId: taskId,
      prompt: prompt,
      status: 'running',
    );
    _startPolling();
  }

  void dismiss() {
    _pollTimer?.cancel();
    _pollTimer = null;
    state = const BackgroundAgentState();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _pollStatus();
    });
  }

  Future<void> _pollStatus() async {
    if (state.taskId == null) {
      _pollTimer?.cancel();
      return;
    }

    // Polling logic would call an API to check task status.
    // For now the state is updated externally or via mock.
  }

  void updateStatus(String status) {
    state = state.copyWith(status: status);
    if (status == 'done' || status == 'failed') {
      _pollTimer?.cancel();
      _pollTimer = null;
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}

final backgroundAgentProvider =
    StateNotifierProvider<BackgroundAgentNotifier, BackgroundAgentState>((ref) {
  return BackgroundAgentNotifier();
});
