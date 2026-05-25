class ConnectorModel {
  final String name;
  final String label;
  final String description;
  final String authType;
  final bool isConnected;

  const ConnectorModel({
    required this.name,
    required this.label,
    required this.description,
    required this.authType,
    this.isConnected = false,
  });

  factory ConnectorModel.fromJson(Map<String, dynamic> json) {
    return ConnectorModel(
      name: json['name'] as String? ?? '',
      label: json['label'] as String? ?? '',
      description: json['description'] as String? ?? '',
      authType: json['auth_type'] as String? ?? 'oauth2',
      isConnected: json['connected'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'label': label,
      'description': description,
      'auth_type': authType,
      'connected': isConnected,
    };
  }
}
