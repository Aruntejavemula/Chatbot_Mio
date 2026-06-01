import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:home_widget/home_widget.dart';

import '../../core/utils/router.dart';

/// Drives the Mio home-screen widget from Dart via the `home_widget` package.
///
/// The native side is only a thin layout (Android `MioWidgetProvider` + XML).
/// All data and behaviour live here: we push a subtitle into the widget and
/// handle taps by opening the app on the chat screen.
class HomeWidgetService {
  HomeWidgetService._();

  /// Must match the Android receiver class name (and iOS widget kind).
  static const String _widgetName = 'MioWidgetProvider';
  static const String _subtitleKey = 'mio_widget_subtitle';

  static Future<void> initialize() async {
    try {
      await setSubtitle('Tap to start a new chat');
      HomeWidget.widgetClicked.listen(_handleUri);
      final launchUri = await HomeWidget.initiallyLaunchedFromHomeWidget();
      if (launchUri != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _handleUri(launchUri));
      }
    } catch (_) {
      // Platform without home-widget support (web/desktop) — ignore.
    }
  }

  /// Updates the text shown on the widget (e.g. the latest chat title).
  static Future<void> setSubtitle(String text) async {
    try {
      await HomeWidget.saveWidgetData<String>(_subtitleKey, text);
      await HomeWidget.updateWidget(name: _widgetName, androidName: _widgetName);
    } catch (_) {
      // No-op on unsupported platforms.
    }
  }

  static void _handleUri(Uri? uri) {
    if (uri == null) return;
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;
    // Every widget tap opens a fresh chat for now.
    context.go(AppRoutes.chat);
  }
}
