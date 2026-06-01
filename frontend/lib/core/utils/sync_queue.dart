import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'app_logger.dart';

/// Represents a message queued for sending when connectivity is restored.
class QueuedMessage {
  final String id;
  final String chatId;
  final String content;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  QueuedMessage({
    required this.id,
    required this.chatId,
    required this.content,
    required this.timestamp,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'chatId': chatId,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
        'metadata': metadata,
      };

  factory QueuedMessage.fromJson(Map<String, dynamic> json) => QueuedMessage(
        id: json['id'] as String,
        chatId: json['chatId'] as String,
        content: json['content'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        metadata: json['metadata'] as Map<String, dynamic>?,
      );
}

/// Queue that stores messages locally when offline and syncs them when
/// connectivity is restored.
///
/// Uses FlutterSecureStorage for persistence so messages survive app restarts.
class SyncQueue {
  SyncQueue._();

  static final SyncQueue instance = SyncQueue._();

  static const String _storageKey = 'mio_sync_queue';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  List<QueuedMessage> _queue = [];
  bool _loaded = false;

  /// Load persisted queue from storage.
  Future<void> load() async {
    if (_loaded) return;
    try {
      final raw = await _storage.read(key: _storageKey);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
        _queue = decoded
            .map((e) => QueuedMessage.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      AppLogger.debug('SyncQueue: failed to load queue: $e');
      _queue = [];
    }
    _loaded = true;
  }

  /// Add a message to the queue for later sending.
  Future<void> enqueue(QueuedMessage message) async {
    await load();
    _queue.add(message);
    await _persist();
  }

  /// Remove a message from the queue after successful send.
  Future<void> dequeue(String messageId) async {
    await load();
    _queue.removeWhere((m) => m.id == messageId);
    await _persist();
  }

  /// Get all pending messages.
  Future<List<QueuedMessage>> getPending() async {
    await load();
    return List.unmodifiable(_queue);
  }

  /// Get pending messages for a specific chat.
  Future<List<QueuedMessage>> getPendingForChat(String chatId) async {
    await load();
    return _queue.where((m) => m.chatId == chatId).toList();
  }

  /// Get the count of pending messages.
  Future<int> get pendingCount async {
    await load();
    return _queue.length;
  }

  /// Clear all queued messages.
  Future<void> clear() async {
    _queue.clear();
    await _persist();
  }

  Future<void> _persist() async {
    try {
      final encoded = jsonEncode(_queue.map((m) => m.toJson()).toList());
      await _storage.write(key: _storageKey, value: encoded);
    } catch (e) {
      AppLogger.debug('SyncQueue: failed to persist queue: $e');
    }
  }
}
