import 'package:flutter_test/flutter_test.dart';
import 'package:nhom14_app/models/personal_topic_model.dart';

void main() {
  test('maps personal topic rows to the shared Supabase schema', () {
    final topic = PersonalTopic.fromJson({
      'id': 'topic-1',
      'user_id': 'student-1',
      'field_id': 'field-1',
      'fields': {'name': 'Trí tuệ nhân tạo'},
      'title': 'Nghiên cứu xe tự lái',
      'objective': 'Xây dựng mô hình nhận diện',
      'approach': 'Huấn luyện và đánh giá mô hình',
      'technologies': ['Flutter', 'Supabase'],
      'status': 'preparing',
      'source': 'ai',
      'created_at': '2026-11-28T10:00:00Z',
      'updated_at': '2026-11-28T10:00:00Z',
    });

    expect(topic.fieldName, 'Trí tuệ nhân tạo');
    expect(topic.objective, 'Xây dựng mô hình nhận diện');
    expect(topic.approach, 'Huấn luyện và đánh giá mô hình');
    expect(topic.technologies, ['Flutter', 'Supabase']);
    expect(topic.statusLabel, 'Chuẩn bị');
    expect(topic.source, 'ai');
  });

  test('serializes only writable columns for insert and update', () {
    const topic = PersonalTopic(
      fieldId: 'field-1',
      title: 'Nghiên cứu xe tự lái',
      objective: 'Xây dựng mô hình nhận diện',
      approach: 'Huấn luyện và đánh giá mô hình',
      technologies: ['Flutter', 'Supabase'],
    );

    expect(topic.toInsertJson().keys.toSet(), {
      'field_id',
      'title',
      'objective',
      'approach',
      'technologies',
      'status',
      'source',
    });
    expect(topic.toUpdateJson().keys.toSet(), {
      'field_id',
      'title',
      'objective',
      'approach',
      'technologies',
      'status',
    });
    expect(topic.toInsertJson()['status'], 'exploring');
    expect(topic.toInsertJson()['technologies'], ['Flutter', 'Supabase']);
  });
}
