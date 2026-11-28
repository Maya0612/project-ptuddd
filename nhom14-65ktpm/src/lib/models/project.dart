enum ProjectStatus { pending, approved, rejected }

class Project {
  final String id;
  final String name;
  final String summary;
  final String studentName;
  final String supervisor;
  final int year;
  final String fieldId;
  final List<String> technologies;
  final String? fileUrl;
  final ProjectStatus status;
  final String? userId;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? rejectReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? field;

  const Project({
    required this.id,
    required this.name,
    required this.summary,
    required this.studentName,
    required this.supervisor,
    required this.year,
    required this.fieldId,
    required this.technologies,
    this.fileUrl,
    required this.status,
    this.userId,
    this.reviewedBy,
    this.reviewedAt,
    this.rejectReason,
    this.createdAt,
    this.updatedAt,
    this.field,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    final relatedField = json['fields'];
    final fieldJson = relatedField is List
        ? (relatedField.isEmpty ? null : relatedField.first)
        : relatedField;

    return Project(
      id: json['id'] as String,
      name: json['name'] as String,
      summary: json['summary'] as String,
      studentName: json['student_name'] as String,
      supervisor: json['supervisor'] as String,
      year: json['year'] as int,
      fieldId: json['field_id'] as String,
      technologies: (json['technologies'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      fileUrl: json['file_url'] as String?,
      status: ProjectStatus.values.byName(json['status'] as String),
      userId: json['user_id'] as String?,
      reviewedBy: json['reviewed_by'] as String?,
      reviewedAt: json['reviewed_at'] == null
          ? null
          : DateTime.tryParse(json['reviewed_at'].toString()),
      rejectReason: json['reject_reason'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse(json['created_at'].toString()),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.tryParse(json['updated_at'].toString()),
      field: fieldJson is Map<String, dynamic> ? fieldJson : null,
    );
  }

  Map<String, dynamic> toJson({bool includeId = false}) {
    final json = <String, dynamic>{
      'name': name,
      'summary': summary,
      'student_name': studentName,
      'supervisor': supervisor,
      'year': year,
      'field_id': fieldId,
      'technologies': technologies,
      'file_url': fileUrl,
      'status': status.name,
      'user_id': userId,
      'reviewed_by': reviewedBy,
      'reviewed_at': reviewedAt?.toIso8601String(),
      'reject_reason': rejectReason,
    };
    if (includeId) json['id'] = id;
    return json;
  }
}
