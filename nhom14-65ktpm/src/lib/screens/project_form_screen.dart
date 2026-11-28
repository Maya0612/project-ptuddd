import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_config.dart';
import '../models/field.dart';
import '../models/profile.dart';
import '../models/project.dart';
import '../services/field_service.dart';
import '../services/project_service.dart';

class ProjectFormScreen extends StatefulWidget {
  final UserRole? role;
  final Project? project;
  const ProjectFormScreen({super.key, required this.role, this.project});

  @override
  State<ProjectFormScreen> createState() => _ProjectFormScreenState();
}

class _ProjectFormScreenState extends State<ProjectFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _summaryController = TextEditingController();
  final _studentController = TextEditingController();
  final _supervisorController = TextEditingController();
  final _yearController = TextEditingController();
  final _technologyController = TextEditingController();
  final _fileUrlController = TextEditingController();
  final _rejectReasonController = TextEditingController();
  final _fieldService = FieldService();
  final _projectService = ProjectService();

  List<FieldItem> _fields = [];
  String? _fieldsError;
  String? _fieldId;
  ProjectStatus _status = ProjectStatus.approved;
  bool _isLoadingFields = true;
  bool _isSaving = false;

  bool get isEditing => widget.project != null;

  @override
  void initState() {
    super.initState();
    final project = widget.project;
    if (project != null) {
      _titleController.text = project.name;
      _summaryController.text = project.summary;
      _studentController.text = project.studentName;
      _supervisorController.text = project.supervisor;
      _yearController.text = project.year.toString();
      _technologyController.text = project.technologies.join(', ');
      _fileUrlController.text = project.fileUrl ?? '';
      _rejectReasonController.text = project.rejectReason ?? '';
      _fieldId = project.fieldId;
      _status = project.status;
    } else {
      _yearController.text = DateTime.now().year.toString();
    }
    _loadFields();
  }

  Future<void> _loadFields() async {
    try {
      _fields = await _fieldService.getFields();
      _fieldsError = _fields.isEmpty
          ? 'Chưa có lĩnh vực nào. Vui lòng thử lại sau.'
          : null;
    } on PostgrestException catch (error) {
      _fields = [];
      _fieldsError = error.code == '42501'
          ? 'Bạn không có quyền xem danh sách lĩnh vực'
          : 'Không thể tải danh sách lĩnh vực. Vui lòng thử lại.';
    } catch (_) {
      _fields = [];
      _fieldsError = 'Không thể tải danh sách lĩnh vực. Vui lòng thử lại.';
    } finally {
      if (mounted) setState(() => _isLoadingFields = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    _studentController.dispose();
    _supervisorController.dispose();
    _yearController.dispose();
    _technologyController.dispose();
    _fileUrlController.dispose();
    _rejectReasonController.dispose();
    super.dispose();
  }

  String _permissionMessage(Object error) {
    if (error is PostgrestException && error.code == '42501') {
      return 'Bạn không có quyền thực hiện thao tác này';
    }
    final text = error.toString();
    if (text.contains('42501') ||
        text.toLowerCase().contains('permission denied') ||
        text.contains('Không có quyền')) {
      return 'Bạn không có quyền thực hiện thao tác này';
    }
    return 'Không thể lưu đồ án';
  }

  Future<void> _save() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;
    if (_status == ProjectStatus.rejected &&
        _rejectReasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập lý do từ chối')),
      );
      return;
    }
    setState(() => _isSaving = true);

    final values = <String, dynamic>{
      'name': _titleController.text.trim(),
      'summary': _summaryController.text.trim(),
      'student_name': _studentController.text.trim(),
      'supervisor': _supervisorController.text.trim(),
      'year': int.parse(_yearController.text.trim()),
      'field_id': _fieldId,
      'technologies': _technologyController.text
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList(),
      'file_url': _fileUrlController.text.trim().isEmpty
          ? null
          : _fileUrlController.text.trim(),
      'status': _status.name,
      'reject_reason': _status == ProjectStatus.rejected
          ? _rejectReasonController.text.trim()
          : null,
    };

    try {
      if (isEditing) {
        final changed = <String, dynamic>{};
        final old = widget.project!;
        if (values['name'] != old.name) {
          changed['name'] = values['name'];
        }
        if (values['summary'] != old.summary) {
          changed['summary'] = values['summary'];
        }
        if (values['student_name'] != old.studentName) {
          changed['student_name'] = values['student_name'];
        }
        if (values['supervisor'] != old.supervisor) {
          changed['supervisor'] = values['supervisor'];
        }
        if (values['year'] != old.year) {
          changed['year'] = values['year'];
        }
        if (values['field_id'] != old.fieldId) {
          changed['field_id'] = values['field_id'];
        }
        final technologies = _technologyController.text
            .split(',')
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList();
        if (!listEquals(technologies, old.technologies)) {
          changed['technologies'] = values['technologies'];
        }
        if (values['file_url'] != old.fileUrl) {
          changed['file_url'] = values['file_url'];
        }
        if (values['status'] != old.status.name) {
          changed['status'] = values['status'];
        }
        if (values['reject_reason'] != old.rejectReason) {
          changed['reject_reason'] = values['reject_reason'];
        }
        if (changed.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không có thay đổi nào để lưu')),
          );
          return;
        }
        await _projectService.update(old.id, changed);
      } else {
        values['status'] = 'approved';
        values['user_id'] = supabase.auth.currentUser?.id;
        await _projectService.create(values);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? 'Đã cập nhật đồ án' : 'Đã thêm đồ án'),
        ),
      );
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_permissionMessage(error))));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Sửa đồ án' : 'Thêm đồ án')),
      body: _isLoadingFields
          ? const Center(child: CircularProgressIndicator())
          : _fieldsError != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_fieldsError!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _isLoadingFields = true;
                          _fieldsError = null;
                        });
                        _loadFields();
                      },
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Tên đề tài',
                      ),
                      validator: (value) => value?.trim().isEmpty == true
                          ? 'Vui lòng nhập tên đề tài'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _summaryController,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(labelText: 'Tóm tắt'),
                      validator: (value) => value?.trim().isEmpty == true
                          ? 'Vui lòng nhập tóm tắt'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _studentController,
                      decoration: const InputDecoration(labelText: 'Sinh viên'),
                      validator: (value) => value?.trim().isEmpty == true
                          ? 'Vui lòng nhập tên sinh viên'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _supervisorController,
                      decoration: const InputDecoration(
                        labelText: 'Giảng viên hướng dẫn',
                      ),
                      validator: (value) => value?.trim().isEmpty == true
                          ? 'Vui lòng nhập giảng viên hướng dẫn'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _yearController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Năm'),
                      validator: (value) {
                        final year = int.tryParse(value?.trim() ?? '');
                        if (year == null) return 'Năm phải là số';
                        if (year < 2000 || year > 2100) {
                          return 'Năm phải từ 2000 đến 2100';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _fieldId,
                      decoration: const InputDecoration(labelText: 'Lĩnh vực'),
                      items: _fields
                          .map(
                            (field) => DropdownMenuItem(
                              value: field.id,
                              child: Text(field.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() => _fieldId = value),
                      validator: (value) =>
                          value == null ? 'Vui lòng chọn lĩnh vực' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _technologyController,
                      decoration: const InputDecoration(
                        labelText: 'Công nghệ',
                        hintText: 'Flutter, Supabase, PostgreSQL',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _fileUrlController,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        labelText: 'URL tệp (không bắt buộc)',
                      ),
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.isEmpty) return null;
                        final uri = Uri.tryParse(text);
                        if (uri == null ||
                            !uri.hasAuthority ||
                            !{'http', 'https'}.contains(uri.scheme) ||
                            uri.host.isEmpty) {
                          return 'URL không hợp lệ';
                        }
                        return null;
                      },
                    ),
                    if (isEditing) ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<ProjectStatus>(
                        initialValue: _status,
                        decoration: const InputDecoration(
                          labelText: 'Trạng thái',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: ProjectStatus.pending,
                            child: Text('Chờ duyệt'),
                          ),
                          DropdownMenuItem(
                            value: ProjectStatus.approved,
                            child: Text('Đã duyệt'),
                          ),
                          DropdownMenuItem(
                            value: ProjectStatus.rejected,
                            child: Text('Bị từ chối'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => _status = value);
                        },
                      ),
                      if (_status == ProjectStatus.rejected) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _rejectReasonController,
                          minLines: 2,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Lý do từ chối',
                          ),
                        ),
                      ],
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed: _isSaving ? null : _save,
                        child: _isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(isEditing ? 'Lưu thay đổi' : 'Thêm đồ án'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
