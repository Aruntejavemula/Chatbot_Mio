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
  }) async {
    try {
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

      final wordIndex = _ref.read(loadingWordIndexProvider);
      LoadingWords.getWord(wordIndex);
      _ref.read(loadingWordIndexProvider.notifier).state = wordIndex + 1;

      final stream = _chatService.streamMessage(
        chatId: chatId,
        content: content,
        model: model,
        provider: provider,
        useOurTokens: useOurTokens,
      );

      final buffer = StringBuffer();

      await for (final chunk in stream) {
        buffer.write(chunk);
        _ref.read(streamingTextProvider.notifier).state = buffer.toString();
      }

      final capWarning = _chatService.lastCapWarning;
      if (capWarning != null) {
        _ref.read(tokenCapProvider.notifier).state = capWarning;
      }

      final aiMessage = MessageModel(
        id: const Uuid().v4(),
        chatId: chatId,
        role: 'assistant',
        content: buffer.toString(),
        model: model,
        createdAt: DateTime.now(),
      );

      final updatedMessages = _ref.read(messagesProvider);
      _ref.read(messagesProvider.notifier).state = [
        ...updatedMessages,
        aiMessage,
      ];

      _ref.read(isStreamingProvider.notifier).state = false;
      _ref.read(streamingTextProvider.notifier).state = '';
    } catch (e) {
      _ref.read(isStreamingProvider.notifier).state = false;
      _ref.read(streamingTextProvider.notifier).state = '';
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
