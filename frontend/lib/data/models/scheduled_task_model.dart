class ScheduledTaskModel {
  final String id;
  final String title;
  final String prompt;
  final String scheduleType;
  final DateTime? runAt;
  final String? runTime;
  final String? runDay;
  final DateTime? nextRunAt;
  final DateTime? lastRunAt;
  final String status;
  final String? result;

  const ScheduledTaskModel({
    required this.id,
    required this.title,
    required this.prompt,
    required this.scheduleType,
    this.runAt,
    this.runTime,
    this.runDay,
    this.nextRunAt,
    this.lastRunAt,
    required this.status,
    this.result,
  });

  factory ScheduledTaskModel.fromJson(Map<String, dynamic> json) {
    return ScheduledTaskModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      prompt: json['prompt'] as String? ?? '',
      scheduleType: json['schedule_type'] as String? ?? 'once',
      runAt: json['run_at'] != null ? DateTime.tryParse(json['run_at'] as String) : null,
      runTime: json['run_time'] as String?,
      runDay: json['run_day'] as String?,
      nextRunAt: json['next_run_at'] != null ? DateTime.tryParse(json['next_run_at'] as String) : null,
      lastRunAt: json['last_run_at'] != null ? DateTime.tryParse(json['last_run_at'] as String) : null,
      status: json['status'] as String? ?? 'active',
      result: json['result'] as String?,
    );
  }
}
