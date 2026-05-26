import 'package:flutter_test/flutter_test.dart';
import 'package:mio/data/models/project_model.dart';

void main() {
  group('ProjectModel', () {
    test('fromJson parses all fields correctly', () {
      final json = <String, dynamic>{
        'id': 'proj-001',
        'user_id': 'user-123',
        'name': 'My Project',
        'color': '#FF5733',
        'system_prompt': 'You are a helpful assistant.',
        'created_at': '2024-01-15T10:00:00.000Z',
        'updated_at': '2024-01-16T12:00:00.000Z',
      };

      final model = ProjectModel.fromJson(json);

      expect(model.id, 'proj-001');
      expect(model.userId, 'user-123');
      expect(model.name, 'My Project');
      expect(model.color, '#FF5733');
      expect(model.systemPrompt, 'You are a helpful assistant.');
      expect(model.createdAt, DateTime.utc(2024, 1, 15, 10, 0));
      expect(model.updatedAt, DateTime.utc(2024, 1, 16, 12, 0));
    });

    test('fromJson uses DateTime.now fallback for invalid dates', () {
      final now = DateTime.now();
      final json = <String, dynamic>{
        'id': 'proj-002',
        'user_id': 'user-456',
        'name': 'Fallback Project',
        'color': '#000000',
        'system_prompt': 'Prompt',
        'created_at': 'invalid-date',
        'updated_at': null,
      };

      final model = ProjectModel.fromJson(json);

      expect(model.id, 'proj-002');
      // The fallback should be approximately now (within 1 second)
      expect(
        model.createdAt.difference(now).inSeconds.abs(),
        lessThanOrEqualTo(1),
      );
      expect(
        model.updatedAt.difference(now).inSeconds.abs(),
        lessThanOrEqualTo(1),
      );
    });

    test('toJson outputs correct snake_case keys', () {
      final model = ProjectModel(
        id: 'proj-003',
        userId: 'user-789',
        name: 'Test Project',
        color: '#123456',
        systemPrompt: 'Be concise.',
        createdAt: DateTime.utc(2024, 3, 1, 9, 0),
        updatedAt: DateTime.utc(2024, 3, 2, 10, 0),
      );

      final json = model.toJson();

      expect(json['id'], 'proj-003');
      expect(json['user_id'], 'user-789');
      expect(json['name'], 'Test Project');
      expect(json['color'], '#123456');
      expect(json['system_prompt'], 'Be concise.');
      expect(json['created_at'], '2024-03-01T09:00:00.000Z');
      expect(json['updated_at'], '2024-03-02T10:00:00.000Z');
    });

    test('fromJson/toJson roundtrip preserves data', () {
      final originalJson = <String, dynamic>{
        'id': 'proj-rt',
        'user_id': 'user-rt',
        'name': 'Roundtrip',
        'color': '#ABCDEF',
        'system_prompt': 'System prompt here',
        'created_at': '2024-06-15T14:30:00.000Z',
        'updated_at': '2024-06-16T08:00:00.000Z',
      };

      final model = ProjectModel.fromJson(originalJson);
      final resultJson = model.toJson();

      expect(resultJson['id'], originalJson['id']);
      expect(resultJson['user_id'], originalJson['user_id']);
      expect(resultJson['name'], originalJson['name']);
      expect(resultJson['color'], originalJson['color']);
      expect(resultJson['system_prompt'], originalJson['system_prompt']);
      expect(resultJson['created_at'], originalJson['created_at']);
      expect(resultJson['updated_at'], originalJson['updated_at']);
    });

    test('copyWith creates modified copy', () {
      final original = ProjectModel(
        id: 'proj-cw',
        userId: 'user-cw',
        name: 'Original Name',
        color: '#111111',
        systemPrompt: 'Original prompt',
        createdAt: DateTime.utc(2024, 1, 1),
        updatedAt: DateTime.utc(2024, 1, 1),
      );

      final updated = original.copyWith(
        name: 'Updated Name',
        color: '#222222',
      );

      expect(updated.name, 'Updated Name');
      expect(updated.color, '#222222');
      expect(updated.id, 'proj-cw');
      expect(updated.systemPrompt, 'Original prompt');
    });
  });
}
