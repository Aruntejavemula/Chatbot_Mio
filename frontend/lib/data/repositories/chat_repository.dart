import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/loading_words.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../services/chat_service.dart';

final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService();
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(ref);
});

final chatsProvider = StateProvider<List<ChatModel>>((ref) {
  return [];
});

final currentChatProvider = StateProvider<ChatModel?>((ref) {
  return null;
});

final messagesProvider = StateProvider<List<MessageModel>>((ref) {
  return [];
});

final isStreamingProvider = StateProvider<bool>((ref) {
  return false;
});

final streamingTextProvider = StateProvider<String>((ref) {
  return '';
});

final streamingThinkingTextProvider = StateProvider<String>((ref) {
  return '';
});

final isThinkingStreamingProvider = StateProvider<bool>((ref) {
  return false;
});

final loadingWordIndexProvider = StateProvider<int>((ref) {
  return 0;
});

final tokenCapProvider = StateProvider<Map<String, Object?>?>((ref) {
  return null;
});

class ChatRepository {
  final Ref _ref;

  ChatRepository(this._ref);

  ChatService get _chatService => _ref.read(chatServiceProvider);

  Future<List<ChatModel>> loadChats() async {
    try {
      final chats = await _chatService.getChats();
      _ref.read(chatsProvider.notifier).state = chats;
      return chats;
    } catch (e) {
      rethrow;
    }
  }

  Future<ChatModel> createNewChat(String model, String provider) async {
    try {
      final chat = await _chatService.createChat(model, provider);
      final currentChats = _ref.read(chatsProvider);
      _ref.read(chatsProvider.notifier).state = [chat, ...currentChats];
      _ref.read(currentChatProvider.notifier).state = chat;
      return chat;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<MessageModel>> loadMessages(String chatId) async {
    try {
      final messages = await _chatService.getMessages(chatId);
      _ref.read(messagesProvider.notifier).state = messages;
      return messages;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> sendMessage({
    required String chatId,
    required String content,
    required String model,
    required String provider,
    required bool useOurTokens,
    String? projectId,
  }) async {
    try {
      _ref.read(tokenCapProvider.notifier).state = null;

      final userMessage = MessageModel(
        id: const Uuid().v4(),
        chatId: chatId,
        role: 'user',
        content: content,
        createdAt: DateTime.now(),
      );

      final currentMessages = _ref.read(messagesProvider);
      _ref.read(messagesProvider.notifier).state = [
        ...currentMessages,
        userMessage,
      ];

      _ref.read(isStreamingProvider.notifier).state = true;
      _ref.read(streamingTextProvider.notifier).state = '';
      _ref.read(streamingThinkingTextProvider.notifier).state = '';
      _ref.read(isThinkingStreamingProvider.notifier).state = false;

      final wordIndex = _ref.read(loadingWordIndexProvider);
      LoadingWords.getWord(wordIndex);
      _ref.read(loadingWordIndexProvider.notifier).state = wordIndex + 1;

      final stream = _chatService.streamMessage(
        chatId: chatId,
        content: content,
        model: model,
        provider: provider,
        useOurTokens: useOurTokens,
        projectId: projectId,
      );

      final buffer = StringBuffer();
      final thinkingBuffer = StringBuffer();
      var dirty = false;
      var thinkingDirty = false;
      Timer? flushTimer;

      void flush() {
        if (dirty) {
          _ref.read(streamingTextProvider.notifier).state = buffer.toString();
          dirty = false;
        }
        if (thinkingDirty) {
          _ref.read(streamingThinkingTextProvider.notifier).state =
              thinkingBuffer.toString();
          thinkingDirty = false;
        }
      }

      await for (final event in stream) {
        switch (event.type) {
          case ChatStreamEventType.thinking:
            if (!_ref.read(isThinkingStreamingProvider)) {
              _ref.read(isThinkingStreamingProvider.notifier).state = true;
            }
            thinkingBuffer.write(event.content);
            thinkingDirty = true;
            flushTimer ??= Timer(const Duration(milliseconds: 80), () {
              flush();
              flushTimer = null;
            });
          case ChatStreamEventType.text:
            if (_ref.read(isThinkingStreamingProvider)) {
              _ref.read(isThinkingStreamingProvider.notifier).state = false;
            }
            buffer.write(event.content);
            dirty = true;
            flushTimer ??= Timer(const Duration(milliseconds: 80), () {
              flush();
              flushTimer = null;
            });
          case ChatStreamEventType.done:
            break;
        }
      }

      flushTimer?.cancel();
      flush();

      final capWarning = _chatService.lastCapWarning;
      if (capWarning != null) {
        _ref.read(tokenCapProvider.notifier).state = capWarning;
      }

      final thinkingContent = thinkingBuffer.toString();

      final aiMessage = MessageModel(
        id: const Uuid().v4(),
        chatId: chatId,
        role: 'assistant',
        content: buffer.toString(),
        model: model,
        createdAt: DateTime.now(),
        thinkingContent: thinkingContent.isNotEmpty ? thinkingContent : null,
        hasThinking: thinkingContent.isNotEmpty,
      );

      final updatedMessages = _ref.read(messagesProvider);
      _ref.read(messagesProvider.notifier).state = [
        ...updatedMessages,
        aiMessage,
      ];

      _ref.read(isStreamingProvider.notifier).state = false;
      _ref.read(streamingTextProvider.notifier).state = '';
      _ref.read(streamingThinkingTextProvider.notifier).state = '';
      _ref.read(isThinkingStreamingProvider.notifier).state = false;
    } catch (e) {
      _ref.read(isStreamingProvider.notifier).state = false;
      _ref.read(streamingTextProvider.notifier).state = '';
      _ref.read(streamingThinkingTextProvider.notifier).state = '';
      _ref.read(isThinkingStreamingProvider.notifier).state = false;
      rethrow;
    }
  }

  Future<void> deleteChat(String chatId) async {
    try {
      await _chatService.deleteChat(chatId);
      final currentChats = _ref.read(chatsProvider);
      _ref.read(chatsProvider.notifier).state =
          currentChats.where((chat) => chat.id != chatId).toList();
    } catch (e) {
      rethrow;
    }
  }
}
