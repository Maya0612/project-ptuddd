class FieldItem {
  const FieldItem({required this.id, required this.name});

  final String id;
  final String name;

  factory FieldItem.fromJson(Map<String, dynamic> json) {
    return FieldItem(
      id: json['id'].toString(),
      name: (json['name'] ?? json['title'] ?? 'Chưa đặt tên').toString(),
    );
  }
}

class PersonalTopic {
  const PersonalTopic({
    this.id,
    this.fieldId,
    this.fieldName,
    required this.title,
    this.objective,
    this.approach,
    this.technologies = const [],
    this.status = 'exploring',
    this.source = 'manual',
    this.createdAt,
    this.updatedAt,
  });

  final String? id;
  final String? fieldId;
  final String? fieldName;
  final String title;
  final String? objective;
  final String? approach;
  final List<String> technologies;
  final String status;
  final String source;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory PersonalTopic.fromJson(Map<String, dynamic> json) {
    final fields = json['fields'];
    final fieldName = fields is Map
        ? (fields['name'] ?? fields['title'])?.toString()
        : null;
    final technologies = json['technologies'] as List<dynamic>? ?? const [];

    return PersonalTopic(
      id: json['id']?.toString(),
      fieldId: json['field_id']?.toString(),
      fieldName: fieldName,
      title: json['title'] as String? ?? '',
      objective: json['objective'] as String?,
      approach: json['approach'] as String?,
      technologies: technologies.map((value) => value.toString()).toList(),
      status: json['status'] as String? ?? 'exploring',
      source: json['source'] as String? ?? 'manual',
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'field_id': fieldId,
      'title': title,
      'objective': objective,
      'approach': approach,
      'technologies': technologies,
      'status': status,
      'source': source,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'field_id': fieldId,
      'title': title,
      'objective': objective,
      'approach': approach,
      'technologies': technologies,
      'status': status,
    };
  }

  String get statusLabel {
    return switch (status) {
      'preparing' => 'Chuẩn bị',
      'in_progress' => 'Đang phát triển',
      'completed' => 'Hoàn thành',
      _ => 'Ý tưởng',
    };
  }
}
