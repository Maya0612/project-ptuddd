import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_config.dart';
import '../models/ai_suggestion_model.dart';

/// Service xử lý việc gửi yêu cầu và nhận đề tài từ AI.
///
/// AI được gọi thông qua Supabase Edge Function.
/// API key của mô hình AI không được lưu trong Flutter.
class AiSuggestionService {
  AiSuggestionService({SupabaseClient? client})
    : _client = client ?? SupabaseConfig.client;

  final SupabaseClient _client;

  /// Tên Edge Function sẽ được triển khai ở backend.
  static const String _functionName = 'ai-topic-suggestions';

  /// Gửi yêu cầu đề xuất đề tài tới backend.
  Future<List<AiTopicSuggestion>> generateSuggestions(
    AiSuggestionRequest request,
  ) async {
    final validationError = request.validate();

    if (validationError != null) {
      throw ArgumentError(validationError);
    }

    try {
      final response = await _client.functions.invoke(
        _functionName,
        body: request.toJson(),
      );

      if (response.status != 200) {
        throw Exception('AI backend trả về mã HTTP ${response.status}.');
      }

      final data = response.data;

      if (data is! Map<String, dynamic>) {
        throw const FormatException(
          'Phản hồi AI không đúng định dạng JSON object.',
        );
      }

      final suggestionsData = data['suggestions'];

      if (suggestionsData is! List) {
        throw const FormatException(
          'Phản hồi AI không chứa danh sách suggestions hợp lệ.',
        );
      }

      final suggestions = suggestionsData
          .whereType<Map<String, dynamic>>()
          .map(AiTopicSuggestion.fromJson)
          .toList();

      if (suggestions.isEmpty) {
        throw const FormatException('AI không trả về đề tài hợp lệ.');
      }

      if (suggestions.length > 5) {
        return suggestions.take(5).toList();
      }

      return suggestions;
    } on FunctionException {
      rethrow;
    } on FormatException {
      rethrow;
    } on ArgumentError {
      rethrow;
    } catch (e) {
      throw Exception('Không thể lấy gợi ý đề tài từ AI: $e');
    }
  }
}
