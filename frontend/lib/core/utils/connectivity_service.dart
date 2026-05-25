import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Singleton service that monitors network connectivity.
///
/// Uses connectivity_plus to detect online/offline state changes
/// and exposes a stream for UI components to react to.
class ConnectivityService {
  ConnectivityService._() {
    _init();
  }

  static final ConnectivityService instance = ConnectivityService._();

  final Connectivity _connectivity = Connectivity();
  final ValueNotifier<bool> isOnline = ValueNotifier<bool>(true);

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  void _init() {
    // Check initial state
    _connectivity.checkConnectivity().then(_updateStatus);
    // Listen for changes
    _subscription = _connectivity.onConnectivityChanged.listen(_updateStatus);
  }

  void _updateStatus(List<ConnectivityResult> results) {
    final connected = results.any(
      (r) => r != ConnectivityResult.none,
    );
    if (isOnline.value != connected) {
      isOnline.value = connected;
      debugPrint('ConnectivityService: online=$connected');
    }
  }

  /// Manually check current connectivity status.
  Future<bool> checkConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    _updateStatus(results);
    return isOnline.value;
  }

  /// Dispose the subscription. Call on app shutdown if needed.
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
