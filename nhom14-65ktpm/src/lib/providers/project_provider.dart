import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/project.dart';
import '../services/project_service.dart';

class ProjectProvider extends ChangeNotifier {
  final ProjectService _service = ProjectService();
  final List<Project> projects = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> load({String? status}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      projects
        ..clear()
        ..addAll(await _service.getProjects(status: status));
    } on PostgrestException catch (e) {
      errorMessage = e.code == '42501'
          ? 'Bạn không có quyền truy cập dữ liệu này'
          : 'Không thể tải danh sách đồ án';
    } catch (_) {
      errorMessage = 'Không thể tải danh sách đồ án';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
