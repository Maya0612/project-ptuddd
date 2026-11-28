import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_config.dart';
import '../models/field_model.dart';
import '../models/project_model.dart';

/// Exception chuẩn hóa cho các thao tác với kho đồ án trên Supabase.
class ProjectRepositoryException implements Exception {
  const ProjectRepositoryException({
    required this.operation,
    required this.message,
    this.code,
  });

  final String operation;
  final String message;
  final String? code;

  @override
  String toString() {
    if (code != null && code!.isNotEmpty) {
      return '$operation thất bại ($code): $message';
    }
    return '$operation thất bại: $message';
  }
}

/// Service thao tác với `fields`, `projects`, `favorites` tuân thủ RLS.
class ProjectRepositoryService {
  ProjectRepositoryService({this._client});

  final SupabaseClient? _client;

  static const String _studentSelectColumns =
      'id, title, field_id, year, description, approach, technologies, '
      'status, submitted_by, reviewed_at, created_at, updated_at';

  static const Set<String> _validReviewStatuses = {
    'pending',
    'published',
    'rejected',
  };

  SupabaseClient get _supabase => _client ?? SupabaseConfig.client;

  String get _currentUserId {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw const ProjectRepositoryException(
        operation: 'Xác thực người dùng',
        message: 'Người dùng chưa đăng nhập hệ thống.',
      );
    }
    return user.id;
  }

  /// 1. Lấy danh sách lĩnh vực từ bảng `fields`, sắp xếp theo `name`.
  Future<List<FieldModel>> fetchFields() async {
    return _execute('Tải danh sách lĩnh vực', () async {
      final response = await _supabase
          .from('fields')
          .select('id, name')
          .order('name', ascending: true);

      return (response as List)
          .map(
            (json) => FieldModel.fromJson(
              Map<String, dynamic>.from(json as Map),
            ),
          )
          .toList();
    });
  }

  /// 2a. Tạo mới lĩnh vực trên bảng `fields` (chỉ admin/lecturer).
  Future<FieldModel> createField(String name) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw const ProjectRepositoryException(
        operation: 'Tạo lĩnh vực',
        message: 'Tên lĩnh vực không được để trống.',
      );
    }

    return _execute('Tạo lĩnh vực', () async {
      final response = await _supabase
          .from('fields')
          .insert({'name': trimmedName})
          .select('id, name')
          .single();

      return FieldModel.fromJson(Map<String, dynamic>.from(response));
    });
  }

  /// 2b. Cập nhật tên lĩnh vực trên bảng `fields` (chỉ admin/lecturer).
  Future<FieldModel> updateField(String id, String name) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw const ProjectRepositoryException(
        operation: 'Cập nhật lĩnh vực',
        message: 'Tên lĩnh vực không được để trống.',
      );
    }

    return _execute('Cập nhật lĩnh vực', () async {
      final response = await _supabase
          .from('fields')
          .update({'name': trimmedName})
          .eq('id', id)
          .select('id, name')
          .single();

      return FieldModel.fromJson(Map<String, dynamic>.from(response));
    });
  }

  /// 2c. Xóa lĩnh vực trên bảng `fields` (chỉ admin/lecturer).
  Future<void> deleteField(String id) async {
    return _execute('Xóa lĩnh vực', () async {
      await _supabase.from('fields').delete().eq('id', id);
    });
  }

  /// 3. Lấy danh sách đồ án cho student (chỉ select đúng 12 cột được cấp quyền).
  Future<List<ProjectModel>> fetchProjectsForStudent() async {
    return _execute('Tải danh sách đồ án', () async {
      final response = await _supabase
          .from('projects')
          .select(_studentSelectColumns)
          .order('created_at', ascending: false);

      return (response as List)
          .map(
            (json) => ProjectModel.fromJson(
              Map<String, dynamic>.from(json as Map),
            ),
          )
          .toList();
    });
  }

  /// 4. Lấy toàn bộ dữ liệu đồ án (bao gồm thông tin lịch sử) cho admin/lecturer.
  Future<List<ProjectModel>> fetchProjectsForManager() async {
    return _execute('Tải kho đồ án quản lý', () async {
      final response = await _supabase.rpc('get_repository_projects');

      return (response as List)
          .map(
            (json) => ProjectModel.fromJson(
              Map<String, dynamic>.from(json as Map),
            ),
          )
          .toList();
    });
  }

  /// 5. Student gửi đề xuất đồ án mới (DB tự gán `status = 'pending'`).
  Future<ProjectModel> submitProjectProposal({
    required String title,
    String? fieldId,
    int? year,
    String? description,
    String? approach,
    List<String> technologies = const [],
  }) async {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      throw const ProjectRepositoryException(
        operation: 'Gửi đề xuất đồ án',
        message: 'Tên đồ án không được để trống.',
      );
    }

    final userId = _currentUserId;
    final payload = <String, dynamic>{
      'title': trimmedTitle,
      'field_id': fieldId,
      'year': year,
      'description': description,
      'approach': approach,
      'technologies': technologies,
      'submitted_by': userId,
    };

    return _execute('Gửi đề xuất đồ án', () async {
      final response = await _supabase
          .from('projects')
          .insert(payload)
          .select(_studentSelectColumns)
          .single();

      return ProjectModel.fromJson(Map<String, dynamic>.from(response));
    });
  }

  /// 6. Tạo hoặc cập nhật đồ án bằng RPC `save_repository_project` (admin/lecturer).
  Future<String> saveProjectAsManager(
    Map<String, dynamic> data, {
    String? projectId,
  }) async {
    return _execute('Lưu đồ án', () async {
      final response = await _supabase.rpc(
        'save_repository_project',
        params: {
          'p_data': data,
          'p_project_id': projectId,
        },
      );

      return response.toString();
    });
  }

  /// 7. Duyệt hoặc cập nhật trạng thái đồ án bằng RPC `review_project` (admin/lecturer).
  Future<void> reviewProject(String projectId, String status) async {
    if (!_validReviewStatuses.contains(status)) {
      throw ProjectRepositoryException(
        operation: 'Duyệt đồ án',
        message:
            'Trạng thái "$status" không hợp lệ. Chỉ chấp nhận: pending, published, rejected.',
      );
    }

    return _execute('Duyệt đồ án', () async {
      await _supabase.rpc(
        'review_project',
        params: {
          'p_project_id': projectId,
          'p_status': status,
        },
      );
    });
  }

  /// 8. Lấy tập `project_id` đã yêu thích của user hiện tại.
  Future<Set<String>> fetchFavoriteProjectIds() async {
    final userId = _currentUserId;

    return _execute('Tải danh sách yêu thích', () async {
      final response = await _supabase
          .from('favorites')
          .select('project_id')
          .eq('user_id', userId);

      return (response as List)
          .map((row) => (row as Map)['project_id']?.toString())
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .toSet();
    });
  }

  /// 9. Thêm hoặc bỏ yêu thích đồ án cho user hiện tại.
  Future<void> toggleFavorite(
    String projectId,
    bool isCurrentlyFavorite,
  ) async {
    final userId = _currentUserId;

    return _execute('Cập nhật yêu thích', () async {
      if (isCurrentlyFavorite) {
        await _supabase
            .from('favorites')
            .delete()
            .eq('user_id', userId)
            .eq('project_id', projectId);
      } else {
        await _supabase.from('favorites').insert({
          'user_id': userId,
          'project_id': projectId,
        });
      }
    });
  }

  Future<T> _execute<T>(
    String operation,
    Future<T> Function() request,
  ) async {
    try {
      return await request();
    } on ProjectRepositoryException {
      rethrow;
    } on PostgrestException catch (error) {
      debugPrint(
        '❌ [ProjectRepositoryService] $operation (${error.code}): ${error.message}',
      );
      if (error.code == '42501') {
        throw ProjectRepositoryException(
          operation: operation,
          code: error.code,
          message: 'Tài khoản không có quyền thực hiện thao tác này.',
        );
      }
      if (error.code == '23505') {
        throw ProjectRepositoryException(
          operation: operation,
          code: error.code,
          message: 'Dữ liệu đã tồn tại trong hệ thống.',
        );
      }
      throw ProjectRepositoryException(
        operation: operation,
        code: error.code,
        message: error.message,
      );
    } on AuthException catch (error) {
      debugPrint(
        '❌ [ProjectRepositoryService] $operation AuthException: ${error.message}',
      );
      throw ProjectRepositoryException(
        operation: operation,
        code: error.statusCode,
        message: error.message,
      );
    } on StateError catch (error) {
      debugPrint(
        '❌ [ProjectRepositoryService] $operation StateError: ${error.message}',
      );
      throw ProjectRepositoryException(
        operation: operation,
        message: error.message,
      );
    } catch (error) {
      debugPrint('❌ [ProjectRepositoryService] $operation: $error');
      throw ProjectRepositoryException(
        operation: operation,
        message: error.toString(),
      );
    }
  }
}
