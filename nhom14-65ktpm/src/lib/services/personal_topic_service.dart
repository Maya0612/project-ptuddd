import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/personal_topic_model.dart';

class PersonalTopicService {
  final SupabaseClient _supabase = Supabase.instance.client;

  String get _currentUserId {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Người dùng chưa đăng nhập hệ thống');
    }
    return user.id;
  }

  void _requireSignedInUser() {
    if (_supabase.auth.currentUser == null) {
      throw StateError('Người dùng chưa đăng nhập hệ thống.');
    }
  }

  // 0. Lấy danh sách lĩnh vực từ bảng fields để hiển thị trong Dropdown
  Future<List<FieldItem>> fetchFields() async {
    final response = await _supabase.from('fields').select();
    return response
        .map((json) => FieldItem.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }

  // 1. Lấy danh sách toàn bộ đề tài cá nhân (kèm tên lĩnh vực nếu có)
  Future<List<PersonalTopic>> fetchPersonalTopics() async {
    final response = await _supabase
        .from('personal_topics')
        .select('*, fields(name)')
        .eq('user_id', _currentUserId)
        .order('created_at', ascending: false);

    return response
        .map((json) => PersonalTopic.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }

  // 2. Thêm đề tài mới từ ý tưởng cá nhân (Tự nhập)
  Future<PersonalTopic> createTopic(PersonalTopic topic) async {
    _requireSignedInUser();
    final data = topic.toInsertJson();
    data['source'] = 'manual';

    final response = await _supabase
        .from('personal_topics')
        .insert(data)
        .select('*, fields(name)')
        .single();

    return PersonalTopic.fromJson(response);
  }

  // 3. Lưu gợi ý từ AI (phối hợp với TV3) thành đề tài cá nhân
  Future<PersonalTopic> saveFromAiSuggestion({
    required String title,
    String? objective,
    String? approach,
    String? fieldId,
    List<String> technologies = const [],
  }) async {
    _requireSignedInUser();
    final data = <String, dynamic>{
      'field_id': fieldId,
      'title': title,
      'objective': objective,
      'approach': approach,
      'technologies': technologies,
      'status': 'exploring',
      'source': 'ai',
    };

    final response = await _supabase
        .from('personal_topics')
        .insert(data)
        .select('*, fields(name)')
        .single();

    return PersonalTopic.fromJson(response);
  }

  // 4. Chỉnh sửa thông tin hoặc cập nhật trạng thái đề tài
  Future<void> updateTopic(PersonalTopic topic) async {
    if (topic.id == null) return;
    await _supabase
        .from('personal_topics')
        .update(topic.toUpdateJson())
        .eq('id', topic.id!)
        .eq('user_id', _currentUserId);
  }

  // 5. Xóa đề tài cá nhân
  Future<void> deleteTopic(String topicId) async {
    await _supabase
        .from('personal_topics')
        .delete()
        .eq('id', topicId)
        .eq('user_id', _currentUserId);
  }
}
