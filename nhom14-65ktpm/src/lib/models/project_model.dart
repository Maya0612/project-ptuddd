/// Model đại diện cho đồ án trong kho dữ liệu `public.projects`.
class ProjectModel {
  // Các trường public (student xem được)
  final String id;
  final String title;
  final String? fieldId;
  final int? year;
  final String? description;
  final String? approach;
  final List<String> technologies;
  final String status; // 'pending', 'published', 'rejected'
  final String? submittedBy;
  final DateTime? reviewedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Các trường lịch sử (chỉ admin/lecturer có, có thể null)
  final String? studentCode;
  final String? studentName;
  final String? className;
  final String? supervisorName;
  final String? departmentName;
  final String? reviewedBy;

  const ProjectModel({
    required this.id,
    required this.title,
    this.fieldId,
    this.year,
    this.description,
    this.approach,
    this.technologies = const [],
    this.status = 'pending',
    this.submittedBy,
    this.reviewedAt,
    this.createdAt,
    this.updatedAt,
    this.studentCode,
    this.studentName,
    this.className,
    this.supervisorName,
    this.departmentName,
    this.reviewedBy,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      fieldId: json['field_id']?.toString(),
      year: _parseInt(json['year']),
      description: json['description']?.toString(),
      approach: json['approach']?.toString(),
      technologies: _parseStringList(json['technologies']),
      status: json['status']?.toString() ?? 'pending',
      submittedBy: json['submitted_by']?.toString(),
      reviewedAt: _parseDateTime(json['reviewed_at']),
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
      studentCode: json['student_code']?.toString(),
      studentName: json['student_name']?.toString(),
      className: json['class_name']?.toString(),
      supervisorName: json['supervisor_name']?.toString(),
      departmentName: json['department_name']?.toString(),
      reviewedBy: json['reviewed_by']?.toString(),
    );
  }

  ProjectModel copyWith({
    String? id,
    String? title,
    String? fieldId,
    int? year,
    String? description,
    String? approach,
    List<String>? technologies,
    String? status,
    String? submittedBy,
    DateTime? reviewedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? studentCode,
    String? studentName,
    String? className,
    String? supervisorName,
    String? departmentName,
    String? reviewedBy,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      title: title ?? this.title,
      fieldId: fieldId ?? this.fieldId,
      year: year ?? this.year,
      description: description ?? this.description,
      approach: approach ?? this.approach,
      technologies: technologies ?? this.technologies,
      status: status ?? this.status,
      submittedBy: submittedBy ?? this.submittedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      studentCode: studentCode ?? this.studentCode,
      studentName: studentName ?? this.studentName,
      className: className ?? this.className,
      supervisorName: supervisorName ?? this.supervisorName,
      departmentName: departmentName ?? this.departmentName,
      reviewedBy: reviewedBy ?? this.reviewedBy,
    );
  }

  bool get isPending => status == 'pending';
  bool get isPublished => status == 'published';
  bool get isRejected => status == 'rejected';

  // Hàm tiện ích chuyển mã status tiếng Anh sang nhãn tiếng Việt hiển thị trên UI
  String get statusLabel {
    switch (status) {
      case 'published':
        return 'Đã công bố';
      case 'rejected':
        return 'Từ chối';
      case 'pending':
      default:
        return 'Chờ duyệt';
    }
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static List<String> _parseStringList(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    return const [];
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
