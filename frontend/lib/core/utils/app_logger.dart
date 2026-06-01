import 'package:flutter/foundation.dart';

/// Lightweight logger that is a no-op in release builds.
///
/// Using this instead of `print`/`debugPrint` directly guarantees that user
/// content, tokens, API keys, and other sensitive data never reach device logs
/// (logcat / Console) in production builds.
class AppLogger {
  AppLogger._();

  static void debug(String message) {
    if (kDebugMode) debugPrint(message);
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (!kDebugMode) return;
    debugPrint('ERROR: $message${error != null ? ' | $error' : ''}');
    if (stackTrace != null) debugPrint(stackTrace.toString());
  }
}
