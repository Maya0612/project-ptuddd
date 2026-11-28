import '../models/ai_suggestion_model.dart';

/// Service đối chiếu đề tài AI với danh sách đồ án đã duyệt.
///
/// Service này không tự truy vấn database.
/// Danh sách project được truyền vào từ nguồn dữ liệu bên ngoài.
class ProjectComparisonService {
  /// So sánh một đề tài AI với danh sách đồ án đã duyệt.
  ///
  /// [approvedProjects] là danh sách Map dữ liệu đồ án.
  /// Mỗi project có thể chứa:
  /// id, name, summary, field, technologies.
  List<ProjectComparisonResult> compareSuggestionToProjects({
    required AiTopicSuggestion suggestion,
    required List<Map<String, dynamic>> approvedProjects,
  }) {
    if (approvedProjects.isEmpty) {
      return [];
    }

    final suggestionText = _normalize(
      '${suggestion.title} ${suggestion.description} '
      '${suggestion.objectives} ${suggestion.methodology}',
    );

    final suggestionTokens = _tokenize(suggestionText);
    final suggestionTechnologies = _normalizeList(suggestion.technologies);
    final suggestionField = _normalize(suggestion.field);

    final results = approvedProjects.map((project) {
      final name = project['name']?.toString() ?? '';
      final summary = project['summary']?.toString() ?? '';
      final field = _extractField(project);
      final technologies = _extractTechnologies(project);

      final projectText = _normalize('$name $summary');
      final projectTokens = _tokenize(projectText);

      final textSimilarity = _jaccardSimilarity(
        suggestionTokens,
        projectTokens,
      );

      final projectTechnologies = _normalizeList(technologies);
      final technologySimilarity = _jaccardSimilarity(
        suggestionTechnologies.toSet(),
        projectTechnologies.toSet(),
      );

      final overlappingTechnologies = suggestion.technologies
          .where(
            (technology) =>
                projectTechnologies.contains(_normalize(technology)),
          )
          .toList();

      final normalizedProjectField = _normalize(field);
      final fieldMatch =
          suggestionField.isNotEmpty &&
          normalizedProjectField.isNotEmpty &&
          suggestionField == normalizedProjectField;

      // Kết hợp các chỉ số đối chiếu.
      // Đây là heuristic, không phải mô hình ML.
      final score =
          (textSimilarity * 0.65 +
                  technologySimilarity * 0.25 +
                  (fieldMatch ? 0.10 : 0.0))
              .clamp(0.0, 1.0);

      final warning = _buildWarning(
        score: score,
        overlappingTechnologies: overlappingTechnologies,
        fieldMatch: fieldMatch,
      );

      return ProjectComparisonResult(
        projectId: project['id']?.toString() ?? '',
        projectName: name,
        summary: summary,
        field: field,
        technologies: technologies,
        similarityScore: score * 100,
        overlappingTechnologies: overlappingTechnologies,
        warning: warning,
      );
    }).toList();

    // Sắp xếp đồ án có mức tương đồng cao lên đầu.
    results.sort((a, b) => b.similarityScore.compareTo(a.similarityScore));

    return results;
  }

  String _buildWarning({
    required double score,
    required List<String> overlappingTechnologies,
    required bool fieldMatch,
  }) {
    if (score >= 0.70) {
      return 'Có nhiều điểm tương đồng. '
          'Bạn nên xem xét điều chỉnh phạm vi hoặc hướng tiếp cận.';
    }

    if (score >= 0.40) {
      return 'Có một số điểm tương đồng. '
          'Hãy kiểm tra kỹ sự khác biệt về mục tiêu và phạm vi.';
    }

    if (overlappingTechnologies.isNotEmpty || fieldMatch) {
      return 'Có sự tương đồng về lĩnh vực hoặc công nghệ, '
          'nhưng chưa đủ cơ sở kết luận trùng đề tài.';
    }

    return 'Chưa phát hiện nhiều điểm tương đồng '
        'theo các tiêu chí đối chiếu hiện tại.';
  }

  String _extractField(Map<String, dynamic> project) {
    final field = project['field'];

    if (field is Map) {
      return field['name']?.toString() ?? '';
    }

    if (field is String) {
      return field;
    }

    // Hỗ trợ cấu trúc relation của Supabase.
    final fields = project['fields'];

    if (fields is Map) {
      return fields['name']?.toString() ?? '';
    }

    if (fields is List && fields.isNotEmpty && fields.first is Map) {
      return fields.first['name']?.toString() ?? '';
    }

    return '';
  }

  List<String> _extractTechnologies(Map<String, dynamic> project) {
    final value = project['technologies'];

    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }

    if (value is String && value.trim().isNotEmpty) {
      return value
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }

    return [];
  }

  List<String> _normalizeList(List<String> values) {
    return values.map(_normalize).where((value) => value.isNotEmpty).toList();
  }

  String _normalize(String value) {
    return value.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  Set<String> _tokenize(String value) {
    return value
        .split(RegExp(r'[^a-z0-9+#.]+'))
        .where((token) => token.length > 1)
        .toSet();
  }

  double _jaccardSimilarity(Set<String> a, Set<String> b) {
    if (a.isEmpty || b.isEmpty) {
      return 0.0;
    }

    final intersection = a.intersection(b).length;
    final union = a.union(b).length;

    if (union == 0) {
      return 0.0;
    }

    return intersection / union;
  }
}
