import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../models/chat_model.dart';
import '../models/message_model.dart';
import 'api_service.dart';

enum ChatStreamEventType { thinking, text, done }

class ChatStreamEvent {
  final ChatStreamEventType type;
  final String content;

  const ChatStreamEvent({required this.type, this.content = ''});
}

class ChatService extends ApiService {
  Map<String, Object?>? lastCapWarning;

  Future<List<ChatModel>> getChats() async {
    try {
      final response = await get<List<dynamic>>('/chats');
      final data = response.data ?? [];
      return data
          .map((json) => ChatModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException {
      rethrow;
    }
  }

  Future<ChatModel> createChat(String model, String provider) async {
    try {
      final response = await post<Map<String, dynamic>>(
        '/chats',
        data: {'model': model, 'provider': provider},
      );
      return ChatModel.fromJson(response.data!);
    } on DioException {
      rethrow;
    }
  }

  Future<void> deleteChat(String chatId) async {
    try {
      await delete('/chats/$chatId');
    } on DioException {
      rethrow;
    }
  }

  Future<void> updateChatTitle(String chatId, String title) async {
    try {
      await patch(
        '/chats/$chatId',
        data: {'title': title},
      );
    } on DioException {
      rethrow;
    }
  }

  Stream<ChatStreamEvent> streamMessage({
    required String chatId,
    required String content,
    required String model,
    required String provider,
    bool useOurTokens = false,
  }) async* {
    lastCapWarning = null;
    try {
      final response = await dio.post<ResponseBody>(
        '/chat/stream',
        data: {
          'chat_id': chatId,
          'content': content,
          'model': model,
          'provider': provider,
          'use_our_tokens': useOurTokens,
        },
        options: Options(
          responseType: ResponseType.stream,
          headers: {
            'Accept': 'text/event-stream',
          },
        ),
      );

      final stream = response.data!.stream;
      String buffer = '';

      await for (final chunk in stream) {
        buffer += utf8.decode(chunk);
        final lines = buffer.split('\n');
        buffer = lines.removeLast();

        for (final line in lines) {
          if (line.startsWith('data: ')) {
            final data = line.substring(6).trim();

            if (data == '[DONE]') {
              return;
            }

            try {
              final json = jsonDecode(data) as Map<String, dynamic>;

              if (json.containsKey('error')) {
                throw DioException(
                  requestOptions: RequestOptions(path: '/chat/stream'),
                  error: json['error'] as String,
                );
              }

              if (json.containsKey('type') &&
                  json['type'] == 'cap_warning') {
                lastCapWarning = Map<String, Object?>.from(json);
                continue;
              }

              if (json.containsKey('type')) {
                final eventType = json['type'] as String;
                if (eventType == 'thinking') {
                  yield ChatStreamEvent(
                    type: ChatStreamEventType.thinking,
                    content: json['content'] as String? ?? '',
                  );
                  continue;
                } else if (eventType == 'text') {
                  yield ChatStreamEvent(
                    type: ChatStreamEventType.text,
                    content: json['content'] as String? ?? '',
                  );
                  continue;
                } else if (eventType == 'done') {
                  return;
                }
              }

              if (json.containsKey('content')) {
                yield ChatStreamEvent(
                  type: ChatStreamEventType.text,
                  content: json['content'] as String,
                );
              }
            } catch (e) {
              if (e is DioException) rethrow;
            }
          }
        }
      }
    } on DioException {
      rethrow;
    }
  }

  Future<List<MessageModel>> getMessages(String chatId) async {
    try {
      final response = await get<List<dynamic>>('/chats/$chatId/messages');
      final data = response.data ?? [];
      return data
          .map((json) => MessageModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException {
      rethrow;
    }
  }

  Future<String> makePrompt({
    required String roughText,
    required String provider,
    required String model,
  }) async {
    try {
      final response = await post<Map<String, dynamic>>(
        '/chat/make-prompt',
        data: {
          'rough_text': roughText,
          'provider': provider,
          'model': model,
        },
      );
      final data = response.data;
      if (data == null || !data.containsKey('improved_prompt')) {
        throw DioException(
          requestOptions: response.requestOptions,
          error: 'Invalid response: missing improved_prompt field',
        );
      }
      return data['improved_prompt'] as String;
    } on DioException {
      rethrow;
    }
  }

  Future<Uint8List> exportChatMarkdown(String chatId) async {
    try {
      final response = await dio.get<List<int>>(
        '/export/chat/$chatId/markdown',
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(response.data ?? []);
    } on DioException {
      rethrow;
    }
  }

  Future<Uint8List> exportChatPdf(String chatId) async {
    try {
      final response = await dio.get<List<int>>(
        '/export/chat/$chatId/pdf',
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(response.data ?? []);
    } on DioException {
      rethrow;
    }
  }

  Future<Uint8List> exportAllChats() async {
    try {
      final response = await dio.get<List<int>>(
        '/export/all/markdown',
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(response.data ?? []);
    } on DioException {
      rethrow;
    }
  }

  Future<Map<String, Object?>> getTokenUsage() async {
    try {
      final response = await get<Map<String, dynamic>>('/tokens/usage');
      return response.data ?? {};
    } on DioException {
      rethrow;
    }
  }
}
