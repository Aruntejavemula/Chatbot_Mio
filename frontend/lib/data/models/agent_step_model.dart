class AgentStepModel {
  final int stepNumber;
  final String tool;
  final String status;
  final String? preview;

  const AgentStepModel({
    required this.stepNumber,
    required this.tool,
    required this.status,
    this.preview,
  });

  factory AgentStepModel.fromJson(Map<String, dynamic> json) {
    return AgentStepModel(
      stepNumber: json['step'] as int? ?? 0,
      tool: json['tool'] as String? ?? '',
      status: json['status'] as String? ?? 'executing',
      preview: json['preview'] as String?,
    );
  }
}
