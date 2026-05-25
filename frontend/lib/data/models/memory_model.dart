class MemoryModel {
  final String id;
  final String content;
  final int importance;
  final DateTime createdAt;
  final String? sourceChatId;

  const MemoryModel({
    required this.id,
    required this.content,
    required this.importance,
    required this.createdAt,
    this.sourceChatId,
  });

  factory MemoryModel.fromJson(Map<String, dynamic> json) {
    return MemoryModel(
      id: json['id'] as String? ?? '',
      content: json['content'] as String? ?? '',
      importance: json['importance'] as int? ?? 5,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      sourceChatId: json['source_chat_id'] as String?,
    );
  }

  String get importanceLabel {
    if (importance >= 10) return 'Critical';
    if (importance >= 7) return 'Important';
    if (importance >= 4) return 'Normal';
    return 'Low importance';
  }
}
