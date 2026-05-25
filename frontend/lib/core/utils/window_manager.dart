import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Window management utility for desktop platforms.
///
/// Uses url_launcher as a fallback to open chats in browser.
/// setMinimumSize is a no-op stub since window_manager package is not included.
class MioWindowManager {
  MioWindowManager._();

  static final MioWindowManager instance = MioWindowManager._();

  /// No-op stub for minimum window size.
  /// When the window_manager package is added, this will enforce a
  /// minimum size constraint on desktop platforms.
  void setMinimumSize(double width, double height) {
    debugPrint(
      'MioWindowManager: setMinimumSize($width, $height) - stub, no-op',
    );
  }

  /// Opens a chat in the browser as a fallback for multi-window support.
  Future<bool> openChatInBrowser(String chatId, {String? baseUrl}) async {
    final url = baseUrl ?? 'https://mio.chat';
    final uri = Uri.parse('$url/chat/$chatId');

    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  /// Opens a URL in an external browser window.
  Future<bool> openExternal(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }
}
