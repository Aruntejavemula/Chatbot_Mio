import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Intent subclasses for each shortcut action
class NewChatIntent extends Intent {
  const NewChatIntent();
}

class SearchChatsIntent extends Intent {
  const SearchChatsIntent();
}

class ToggleSidebarIntent extends Intent {
  const ToggleSidebarIntent();
}

class FocusInputIntent extends Intent {
  const FocusInputIntent();
}

class CloseModalIntent extends Intent {
  const CloseModalIntent();
}

class MioShortcuts {
  MioShortcuts._();

  /// All keyboard shortcuts mapped for both Mac (Meta) and Win/Linux (Ctrl).
  static final Map<ShortcutActivator, Intent> shortcuts = {
    // New Chat: Cmd+N / Ctrl+N
    LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyN):
        const NewChatIntent(),
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyN):
        const NewChatIntent(),

    // Search Chats: Cmd+K / Ctrl+K
    LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyK):
        const SearchChatsIntent(),
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyK):
        const SearchChatsIntent(),

    // Toggle Sidebar: Cmd+B / Ctrl+B
    LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyB):
        const ToggleSidebarIntent(),
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyB):
        const ToggleSidebarIntent(),

    // Focus Input: Cmd+/ / Ctrl+/
    LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.slash):
        const FocusInputIntent(),
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.slash):
        const FocusInputIntent(),

    // Close Modal: Escape
    LogicalKeySet(LogicalKeyboardKey.escape): const CloseModalIntent(),
  };

  /// Human-readable descriptions for the help sheet.
  static const List<ShortcutInfo> allShortcuts = [
    ShortcutInfo(label: 'New Chat', macKey: '\u2318 N', winKey: 'Ctrl+N'),
    ShortcutInfo(label: 'Search Chats', macKey: '\u2318 K', winKey: 'Ctrl+K'),
    ShortcutInfo(
        label: 'Toggle Sidebar', macKey: '\u2318 B', winKey: 'Ctrl+B'),
    ShortcutInfo(label: 'Focus Input', macKey: '\u2318 /', winKey: 'Ctrl+/'),
    ShortcutInfo(label: 'Close Modal', macKey: 'Esc', winKey: 'Esc'),
  ];
}

class ShortcutInfo {
  final String label;
  final String macKey;
  final String winKey;

  const ShortcutInfo({
    required this.label,
    required this.macKey,
    required this.winKey,
  });
}
