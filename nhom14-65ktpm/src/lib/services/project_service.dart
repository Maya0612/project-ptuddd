import '../core/supabase_config.dart';
import '../models/project.dart';

class ProjectService {
  /// Tải danh sách đồ án. RLS quyết định dữ liệu khách/sinh viên/staff được xem.
  Future<List<Project>> getProjects({String? status}) async {
    var query = supabase.from('projects').select('*, fields(id, name)');
    if (status != null) {
      query = query.eq('status', status);
    }
    final data = await query.order('created_at', ascending: false);
    return (data as List<dynamic>)
        .map((item) => Project.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Project> getProjectById(String id) async {
    final data = await supabase
        .from('projects')
        .select('*, fields(id, name)')
        .eq('id', id)
        .single();
    return Project.fromJson(data);
  }

  Future<Project> create(Map<String, dynamic> values) async {
    final data = await supabase
        .from('projects')
        .insert(values)
        .select('*, fields(id, name)')
        .single();
    return Project.fromJson(data);
  }

  Future<Project> update(String id, Map<String, dynamic> values) async {
    final data = await supabase
        .from('projects')
        .update(values)
        .eq('id', id)
        .select('*, fields(id, name)');
    if (data.isEmpty) {
      throw const ProjectPermissionException();
    }
    return Project.fromJson(data.first);
  }

  Future<void> delete(String id) async {
    final data = await supabase
        .from('projects')
        .delete()
        .eq('id', id)
        .select('id');
    if (data.isEmpty) {
      throw const ProjectPermissionException();
    }
  }
}

class ProjectPermissionException implements Exception {
  const ProjectPermissionException();

  @override
  String toString() => 'Bạn không có quyền thực hiện thao tác này';
}
