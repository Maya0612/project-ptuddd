class PersonalTopic {
  final String? id;
  final String userId;
  final String title;
  final String? description;
  final String? objectives;
  final String? field;
  final String? technologies;
  final String? implementationPlan;
  final String status;
  final String source;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PersonalTopic({
    this.id,
    required this.userId,
    required this.title,
    this.description,
    this.objectives,
    this.field,
    this.technologies,
    this.implementationPlan,
    this.status = 'Ý tưởng',
    this.source = 'manual',
    this.createdAt,
    this.updatedAt,
  });

  // Chuyển dữ liệu từ Supabase (JSON) sang Object Flutter
  factory PersonalTopic.fromJson(Map<String, dynamic> json) {
    return PersonalTopic(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      description: json['description'],
      objectives: json['objectives'],
      field: json['field'],
      technologies: json['technologies'],
      implementationPlan: json['implementation_plan'],
      status: json['status'] ?? 'Ý tưởng',
      source: json['source'] ?? 'manual',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  // Chuyển dữ liệu từ Flutter sang JSON để gửi lên Supabase
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'objectives': objectives,
      'field': field,
      'technologies': technologies,
      'implementation_plan': implementationPlan,
      'status': status,
      'source': source,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}