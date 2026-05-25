import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../repositories/chat_repository.dart';
import '../services/chat_service.dart';

class UsageState {
  final int dailyUsed;
  final int dailyLimit;
  final bool isLoading;
  final String? error;

  const UsageState({
    this.dailyUsed = 0,
    this.dailyLimit = AppConstants.defaultDailyTokenLimit,
    this.isLoading = true,
    this.error,
  });

  UsageState copyWith({
    int? dailyUsed,
    int? dailyLimit,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return UsageState(
      dailyUsed: dailyUsed ?? this.dailyUsed,
      dailyLimit: dailyLimit ?? this.dailyLimit,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class UsageNotifier extends StateNotifier<UsageState> {
  final ChatService _chatService;
  Timer? _refreshTimer;
  bool _isFirstLoad = true;

  UsageNotifier(this._chatService) : super(const UsageState()) {
    refresh();
    _refreshTimer = Timer.periodic(
      Duration(seconds: AppConstants.usageRefreshIntervalSeconds),
      (_) => refresh(),
    );
  }

  Future<void> refresh() async {
    try {
      if (_isFirstLoad) {
        state = state.copyWith(isLoading: true);
      }
      final response = await _chatService.getTokenUsage();
      final dailyUsed = _extractInt(response, 'daily_used');
      final dailyLimit = _extractInt(response, 'daily_limit',
          defaultValue: AppConstants.defaultDailyTokenLimit);
      state = UsageState(
        dailyUsed: dailyUsed,
        dailyLimit: dailyLimit,
        isLoading: false,
      );
      _isFirstLoad = false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load usage data',
      );
      _isFirstLoad = false;
    }
  }

  int _extractInt(Map<String, Object?> data, String key,
      {int defaultValue = 0}) {
    final value = data[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return defaultValue;
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}

final usageProvider =
    StateNotifierProvider<UsageNotifier, UsageState>((ref) {
  final chatService = ref.read(chatServiceProvider);
  return UsageNotifier(chatService);
});
