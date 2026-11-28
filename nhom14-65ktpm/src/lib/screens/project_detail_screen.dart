import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/profile.dart';
import '../models/project.dart';
import '../services/project_service.dart';
import '../widgets/confirm_delete_dialog.dart';
import '../widgets/role_gate.dart';
import '../widgets/status_chip.dart';
import 'project_form_screen.dart';

class ProjectDetailScreen extends StatefulWidget {
  final String projectId;
  final UserRole? role;

  const ProjectDetailScreen({super.key, required this.projectId, this.role});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  final _service = ProjectService();
  late Future<Project> _future;
  bool _isDeleting = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _future = _service.getProjectById(widget.projectId);
  }

  String _permissionMessage(Object error) {
    if (error is ProjectPermissionException ||
        (error is PostgrestException && error.code == '42501')) {
      return 'Bạn không có quyền thực hiện thao tác này';
    }
    return 'Không thể thực hiện thao tác';
  }

  Future<void> _delete(Project project) async {
    if (_isDeleting) return;
    final confirmed = await confirmDeleteProject(context, project.name);
    if (!confirmed || !mounted) return;

    setState(() => _isDeleting = true);
    try {
      await _service.delete(project.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Đã xóa đồ án')));
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_permissionMessage(error))));
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  Future<void> _edit(Project project) async {
    if (_isEditing) return;
    setState(() => _isEditing = true);
    try {
      final changed = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ProjectFormScreen(role: widget.role, project: project),
        ),
      );
      if (!mounted) return;
      if (changed == true) {
        setState(() => _future = _service.getProjectById(widget.projectId));
      }
    } finally {
      if (mounted) setState(() => _isEditing = false);
    }
  }

  Future<void> _openFile(String url) async {
    try {
      final opened = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!opened && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Không thể mở tệp')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Không thể mở tệp')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết đồ án')),
      body: FutureBuilder<Project>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    snapshot.hasError
                        ? _permissionMessage(snapshot.error!)
                        : 'Không thể tải chi tiết đồ án',
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => setState(
                      () => _future = _service.getProjectById(widget.projectId),
                    ),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          final project = snapshot.data!;
          final fieldName = project.field?['name'] as String?;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                project.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              StatusChip(status: project.status),
              const SizedBox(height: 16),
              _detail('Tóm tắt', project.summary),
              _detail('Sinh viên', project.studentName),
              _detail('Giảng viên hướng dẫn', project.supervisor),
              _detail('Năm', project.year.toString()),
              _detail('Lĩnh vực', fieldName ?? 'Chưa xác định'),
              _detail('Công nghệ', project.technologies.join(', ')),
              if (project.fileUrl?.isNotEmpty == true)
                TextButton.icon(
                  onPressed: () => _openFile(project.fileUrl!),
                  icon: const Icon(Icons.open_in_new),
                  label: Text(project.fileUrl!),
                ),
              if (project.rejectReason?.isNotEmpty == true)
                _detail('Lý do từ chối', project.rejectReason!),
              const SizedBox(height: 24),
              RoleGate(
                role: widget.role,
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _isEditing || _isDeleting
                            ? null
                            : () => _edit(project),
                        icon: _isEditing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.edit),
                        label: const Text('Sửa'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isDeleting || _isEditing
                            ? null
                            : () => _delete(project),
                        icon: _isDeleting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.delete),
                        label: const Text('Xóa'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(value),
        ],
      ),
    );
  }
}
