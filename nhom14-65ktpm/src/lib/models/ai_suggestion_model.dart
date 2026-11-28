
/// Dữ liệu đầu vào để yêu cầu AI đề xuất đề tài.
class AiSuggestionRequest {
  final List<String> interests;
  final List<String> skills;
  final List<String> technologies;
  final String description;

  const AiSuggestionRequest({
    required this.interests,
    required this.skills,
    required this.technologies,
    required this.description,
  });

  /// Kiểm tra dữ liệu đầu vào trước khi gửi AI.
  String? validate() {
    if (interests.isEmpty) {
      return 'Vui lòng nhập ít nhất một lĩnh vực quan tâm.';
    }

    if (skills.isEmpty) {
      return 'Vui lòng nhập ít nhất một kỹ năng.';
    }

    if (description.trim().isEmpty) {
      return 'Vui lòng mô tả định hướng đề tài của bạn.';
    }

    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'interests': interests,
      'skills': skills,
      'technologies': technologies,
      'description': description.trim(),
    };
  }
}

/// Một đề tài do AI đề xuất.
class AiTopicSuggestion {
  final String title;
  final String description;
  final String objectives;
  final String methodology;
  final String field;
  final List<String> technologies;

  const AiTopicSuggestion({
    required this.title,
    required this.description,
    required this.objectives,
    required this.methodology,
    required this.field,
    required this.technologies,
  });

  factory AiTopicSuggestion.fromJson(Map<String, dynamic> json) {
    return AiTopicSuggestion(
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      objectives: json['objectives']?.toString() ?? '',
      methodology: json['methodology']?.toString() ?? '',
      field: json['field']?.toString() ?? '',
      technologies: _parseStringList(json['technologies']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'objectives': objectives,
      'methodology': methodology,
      'field': field,
      'technologies': technologies,
    };
  }

  static List<String> _parseStringList(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }

    return [];
  }
}

/// Kết quả đối chiếu một đề tài AI với đề tài trong kho.
class ProjectComparisonResult {
  final String projectId;
  final String projectName;
  final String summary;
  final String field;
  final List<String> technologies;
  final double similarityScore;
  final List<String> overlappingTechnologies;
  final String warning;

  const ProjectComparisonResult({
    required this.projectId,
    required this.projectName,
    required this.summary,
    required this.field,
    required this.technologies,
    required this.similarityScore,
    required this.overlappingTechnologies,
    required this.warning,
  });

  factory ProjectComparisonResult.fromJson(
    Map<String, dynamic> json,
  ) {
    return ProjectComparisonResult(
      projectId: json['projectId']?.toString() ?? '',
      projectName: json['projectName']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
      field: json['field']?.toString() ?? '',
      technologies: _parseStringList(json['technologies']),
      similarityScore: _parseDouble(json['similarityScore']),
      overlappingTechnologies:
          _parseStringList(json['overlappingTechnologies']),
      warning: json['warning']?.toString() ?? '',
    );
  }

  static List<String> _parseStringList(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }

    return [];
  }

  static double _parseDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }
}
