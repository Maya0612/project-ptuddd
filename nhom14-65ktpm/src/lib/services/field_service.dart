import '../core/supabase_config.dart';
import '../models/field.dart';

class FieldService {
  /// Lấy danh sách lĩnh vực cho dropdown của form.
  Future<List<FieldItem>> getFields() async {
    final data = await supabase
        .from('fields')
        .select('id, name, description')
        .order('name');
    return (data as List<dynamic>)
        .map((item) => FieldItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
