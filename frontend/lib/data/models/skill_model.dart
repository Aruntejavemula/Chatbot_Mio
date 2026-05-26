class SkillModel {
  final String name;
  final String label;
  final String icon;
  final String plan;
  final bool isActive;

  const SkillModel({
    required this.name,
    required this.label,
    required this.icon,
    required this.plan,
    this.isActive = false,
  });

  factory SkillModel.fromJson(Map<String, dynamic> json) {
    return SkillModel(
      name: json['name'] as String? ?? '',
      label: json['label'] as String? ?? '',
      icon: json['icon'] as String? ?? '',
      plan: json['plan'] as String? ?? 'basic',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'label': label,
      'icon': icon,
      'plan': plan,
    };
  }

  SkillModel copyWith({bool? isActive}) {
    return SkillModel(
      name: name,
      label: label,
      icon: icon,
      plan: plan,
      isActive: isActive ?? this.isActive,
    );
  }
}
