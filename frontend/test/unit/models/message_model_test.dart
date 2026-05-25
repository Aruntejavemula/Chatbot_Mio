import 'package:flutter_test/flutter_test.dart';
import 'package:mio/data/models/message_model.dart';

void main() {
  group('MessageModel', () {
    test('fromJson parses all required fields correctly', () {
      final json = <String, dynamic>{
        'id': 'msg-001',
        'chatId': 'chat-001',
        'role': 'user',
        'content': 'Hello world',
        'createdAt': '2024-01-15T10:30:00.000Z',
      };

      final model = MessageModel.fromJson(json);

      expect(model.id, 'msg-001');
      expect(model.chatId, 'chat-001');
      expect(model.role, 'user');
      expect(model.content, 'Hello world');
      expect(model.createdAt, DateTime.utc(2024, 1, 15, 10, 30));
      expect(model.hasThinking, false);
      expect(model.thinkingContent, isNull);
      expect(model.model, isNull);
    });

    test('fromJson parses optional fields and snake_case keys', () {
      final json = <String, dynamic>{
        'id': 'msg-002',
        'chatId': 'chat-002',
        'role': 'assistant',
        'content': 'Hi there',
        'createdAt': '2024-01-15T10:31:00.000Z',
        'tokensInput': 150,
        'tokensOutput': 300,
        'model': 'gpt-4o',
        'thinking_content': 'Let me think...',
        'has_thinking': true,
        'provider': 'openai',
        'cached_tokens': 50,
        'total_input_tokens': 200,
        'output_tokens': 300,
        'image_url': 'https://example.com/img.png',
        'image_prompt': 'A cat',
      };

      final model = MessageModel.fromJson(json);

      expect(model.tokensInput, 150);
      expect(model.tokensOutput, 300);
      expect(model.model, 'gpt-4o');
      expect(model.thinkingContent, 'Let me think...');
      expect(model.hasThinking, true);
      expect(model.provider, 'openai');
      expect(model.cachedTokens, 50);
      expect(model.totalInputTokens, 200);
      expect(model.outputTokens, 300);
      expect(model.imageUrl, 'https://example.com/img.png');
      expect(model.imagePrompt, 'A cat');
    });

    test('toJson produces correct keys including snake_case', () {
      final model = MessageModel(
        id: 'msg-003',
        chatId: 'chat-003',
        role: 'assistant',
        content: 'Response content',
        createdAt: DateTime.utc(2024, 1, 15, 12, 0),
        tokensInput: 100,
        tokensOutput: 200,
        model: 'claude-sonnet-4-5',
        thinkingContent: 'Thinking...',
        hasThinking: true,
        provider: 'anthropic',
        cachedTokens: 25,
        totalInputTokens: 125,
        outputTokens: 200,
        imageUrl: null,
        imagePrompt: null,
      );

      final json = model.toJson();

      expect(json['id'], 'msg-003');
      expect(json['chatId'], 'chat-003');
      expect(json['role'], 'assistant');
      expect(json['content'], 'Response content');
      expect(json['createdAt'], '2024-01-15T12:00:00.000Z');
      expect(json['tokensInput'], 100);
      expect(json['tokensOutput'], 200);
      expect(json['model'], 'claude-sonnet-4-5');
      expect(json['thinking_content'], 'Thinking...');
      expect(json['has_thinking'], true);
      expect(json['provider'], 'anthropic');
      expect(json['cached_tokens'], 25);
      expect(json['total_input_tokens'], 125);
      expect(json['output_tokens'], 200);
    });

    test('fromJson/toJson roundtrip preserves data', () {
      final originalJson = <String, dynamic>{
        'id': 'msg-rt',
        'chatId': 'chat-rt',
        'role': 'user',
        'content': 'Roundtrip test',
        'createdAt': '2024-06-01T08:00:00.000Z',
        'tokensInput': 10,
        'tokensOutput': 20,
        'model': 'gpt-4o-mini',
        'thinking_content': null,
        'has_thinking': false,
        'provider': 'openai',
        'cached_tokens': null,
        'total_input_tokens': null,
        'output_tokens': null,
        'image_url': null,
        'image_prompt': null,
      };

      final model = MessageModel.fromJson(originalJson);
      final resultJson = model.toJson();

      expect(resultJson['id'], originalJson['id']);
      expect(resultJson['chatId'], originalJson['chatId']);
      expect(resultJson['role'], originalJson['role']);
      expect(resultJson['content'], originalJson['content']);
      expect(resultJson['createdAt'], originalJson['createdAt']);
      expect(resultJson['has_thinking'], false);
    });

    test('copyWith creates new instance with updated fields', () {
      final original = MessageModel(
        id: 'msg-copy',
        chatId: 'chat-copy',
        role: 'user',
        content: 'Original',
        createdAt: DateTime.utc(2024, 1, 1),
      );

      final updated = original.copyWith(content: 'Updated', role: 'assistant');

      expect(updated.id, 'msg-copy');
      expect(updated.content, 'Updated');
      expect(updated.role, 'assistant');
      expect(updated.chatId, 'chat-copy');
    });
  });
}
