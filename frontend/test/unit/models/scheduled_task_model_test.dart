import 'package:flutter_test/flutter_test.dart';
import 'package:mio/data/models/scheduled_task_model.dart';

void main() {
  group('ScheduledTaskModel', () {
    test('fromJson parses "once" schedule type with runAt', () {
      final json = <String, dynamic>{
        'id': 'task-001',
        'title': 'Remind me',
        'prompt': 'Send reminder about meeting',
        'schedule_type': 'once',
        'run_at': '2024-03-15T14:00:00.000Z',
        'run_time': null,
        'run_day': null,
        'next_run_at': '2024-03-15T14:00:00.000Z',
        'last_run_at': null,
        'status': 'active',
        'result': null,
      };

      final model = ScheduledTaskModel.fromJson(json);

      expect(model.id, 'task-001');
      expect(model.title, 'Remind me');
      expect(model.prompt, 'Send reminder about meeting');
      expect(model.scheduleType, 'once');
      expect(model.runAt, DateTime.utc(2024, 3, 15, 14, 0));
      expect(model.runTime, isNull);
      expect(model.runDay, isNull);
      expect(model.nextRunAt, DateTime.utc(2024, 3, 15, 14, 0));
      expect(model.lastRunAt, isNull);
      expect(model.status, 'active');
      expect(model.result, isNull);
    });

    test('fromJson parses "daily" schedule type with runTime', () {
      final json = <String, dynamic>{
        'id': 'task-002',
        'title': 'Daily summary',
        'prompt': 'Generate daily summary',
        'schedule_type': 'daily',
        'run_at': null,
        'run_time': '09:00',
        'run_day': null,
        'next_run_at': '2024-03-16T09:00:00.000Z',
        'last_run_at': '2024-03-15T09:00:00.000Z',
        'status': 'active',
        'result': 'Summary generated successfully',
      };

      final model = ScheduledTaskModel.fromJson(json);

      expect(model.scheduleType, 'daily');
      expect(model.runTime, '09:00');
      expect(model.runDay, isNull);
      expect(model.lastRunAt, DateTime.utc(2024, 3, 15, 9, 0));
      expect(model.result, 'Summary generated successfully');
    });

    test('fromJson parses "weekly" schedule type with runDay', () {
      final json = <String, dynamic>{
        'id': 'task-003',
        'title': 'Weekly report',
        'prompt': 'Generate weekly report',
        'schedule_type': 'weekly',
        'run_at': null,
        'run_time': '10:00',
        'run_day': 'monday',
        'next_run_at': '2024-03-18T10:00:00.000Z',
        'last_run_at': null,
        'status': 'active',
        'result': null,
      };

      final model = ScheduledTaskModel.fromJson(json);

      expect(model.scheduleType, 'weekly');
      expect(model.runDay, 'monday');
      expect(model.runTime, '10:00');
    });

    test('fromJson applies defaults when fields are null', () {
      final json = <String, dynamic>{};

      final model = ScheduledTaskModel.fromJson(json);

      expect(model.id, '');
      expect(model.title, '');
      expect(model.prompt, '');
      expect(model.scheduleType, 'once');
      expect(model.status, 'active');
      expect(model.runAt, isNull);
      expect(model.runTime, isNull);
      expect(model.runDay, isNull);
      expect(model.nextRunAt, isNull);
      expect(model.lastRunAt, isNull);
      expect(model.result, isNull);
    });

    test('fromJson handles completed status with result', () {
      final json = <String, dynamic>{
        'id': 'task-done',
        'title': 'Completed task',
        'prompt': 'Do something',
        'schedule_type': 'once',
        'run_at': '2024-01-01T00:00:00.000Z',
        'status': 'completed',
        'result': 'Task completed successfully',
      };

      final model = ScheduledTaskModel.fromJson(json);

      expect(model.status, 'completed');
      expect(model.result, 'Task completed successfully');
    });
  });
}
