import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/field_model.dart';
import '../models/project_model.dart';
import '../services/project_repository_service.dart';

/// Màn hình biểu mẫu dùng chung cho:
/// - Student đề xuất đồ án mới
/// - Admin/Lecturer thêm đồ án mới
/// - Admin/Lecturer chỉnh sửa đồ án (`initialProject != null`)
class ProjectFormScreen extends StatefulWidget {
  const ProjectFormScreen({
    super.key,
    required this.userRole,
    required this.fields,
    this.initialProject,
    this.service,
  });

  final String userRole;
  final List<FieldModel> fields;
  final ProjectModel? initialProject;
  final ProjectRepositoryService? service;

  @override
  State<ProjectFormScreen> createState() => _ProjectFormScreenState();
}

class _ProjectFormScreenState extends State<ProjectFormScreen> {
  late final ProjectRepositoryService _service =
      widget.service ?? ProjectRepositoryService();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _yearController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _approachController;
  late final TextEditingController _technologiesController;

  // Các trường lưu trữ chỉ dành cho admin/lecturer
  late final TextEditingController _studentCodeController;
  late final TextEditingController _studentNameController;
  late final TextEditingController _classNameController;
  late final TextEditingController _supervisorController;
  late final TextEditingController _departmentController;

  String? _selectedFieldId;
  String _selectedStatus = 'published';
  bool _isSaving = false;
  String? _errorText;

  bool get _isManager {
    final normalized = widget.userRole.trim().toLowerCase();
    return normalized == 'admin' || normalized == 'lecturer';
  }

  bool get _isEditing => widget.initialProject != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialProject;

    _titleController = TextEditingController(text: initial?.title ?? '');
    _yearController = TextEditingController(
      text: initial != null
          ? (initial.year?.toString() ?? '')
          : DateTime.now().year.toString(),
    );
    _descriptionController = TextEditingController(
      text: initial?.description ?? '',
    );
    _approachController = TextEditingController(text: initial?.approach ?? '');
    _technologiesController = TextEditingController(
      text: initial?.technologies.join(', ') ?? '',
    );

    _studentCodeController = TextEditingController(
      text: initial?.studentCode ?? '',
    );
    _studentNameController = TextEditingController(
      text: initial?.studentName ?? '',
    );
    _classNameController = TextEditingController(
      text: initial?.className ?? '',
    );
    _supervisorController = TextEditingController(
      text: initial?.supervisorName ?? '',
    );
    _departmentController = TextEditingController(
      text: initial?.departmentName ?? '',
    );

    final initialFieldId = initial?.fieldId;
    if (initialFieldId != null &&
        widget.fields.any((f) => f.id == initialFieldId)) {
      _selectedFieldId = initialFieldId;
    }

    if (initial != null) {
      _selectedStatus = initial.status;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _yearController.dispose();
    _descriptionController.dispose();
    _approachController.dispose();
    _technologiesController.dispose();
    _studentCodeController.dispose();
    _studentNameController.dispose();
    _classNameController.dispose();
    _supervisorController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  List<String> _parseTechnologies() {
    return _technologiesController.text
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  String? _nullIfEmpty(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final yearText = _yearController.text.trim();
    final parsedYear = yearText.isEmpty ? null : int.tryParse(yearText);
    final technologies = _parseTechnologies();

    setState(() {
      _isSaving = true;
      _errorText = null;
    });

    try {
      if (_isManager) {
        final payload = <String, dynamic>{
          'title': _titleController.text.trim(),
          'field_id': _selectedFieldId,
          'year': parsedYear,
          'description': _nullIfEmpty(_descriptionController.text),
          'approach': _nullIfEmpty(_approachController.text),
          'technologies': technologies,
          'student_code': _nullIfEmpty(_studentCodeController.text),
          'student_name': _nullIfEmpty(_studentNameController.text),
          'class_name': _nullIfEmpty(_classNameController.text),
          'supervisor_name': _nullIfEmpty(_supervisorController.text),
          'department_name': _nullIfEmpty(_departmentController.text),
          if (!_isEditing) 'status': _selectedStatus,
        };

        await _service.saveProjectAsManager(
          payload,
          projectId: widget.initialProject?.id,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Đã cập nhật thông tin đồ án.'
                  : 'Đã thêm đồ án mới vào kho.',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        await _service.submitProjectProposal(
          title: _titleController.text.trim(),
          fieldId: _selectedFieldId,
          year: parsedYear,
          description: _nullIfEmpty(_descriptionController.text),
          approach: _nullIfEmpty(_approachController.text),
          technologies: technologies,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã gửi đề xuất, đang chờ duyệt'),
            backgroundColor: AppColors.success,
          ),
        );
      }

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorText = '$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenTitle = _isManager
        ? (_isEditing ? 'Chỉnh sửa đồ án' : 'Thêm đồ án mới')
        : 'Đề xuất đồ án mới';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(screenTitle)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 740),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_errorText != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.danger.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            _errorText!,
                            style: const TextStyle(
                              color: AppColors.danger,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      const Text(
                        'Thông tin đồ án',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Tên đề tài *',
                          hintText: 'Nhập tên đề tài đồ án',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập tên đề tài';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String?>(
                        initialValue: _selectedFieldId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Lĩnh vực',
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Chưa chọn lĩnh vực'),
                          ),
                          ...widget.fields.map(
                            (field) => DropdownMenuItem<String?>(
                              value: field.id,
                              child: Text(
                                field.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _selectedFieldId = value),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _yearController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Năm thực hiện (1900 - 2200)',
                          hintText: 'Ví dụ: 2025',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return null;
                          }
                          final year = int.tryParse(value.trim());
                          if (year == null || year < 1900 || year > 2200) {
                            return 'Năm phải nằm trong khoảng 1900 - 2200';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _technologiesController,
                        decoration: const InputDecoration(
                          labelText: 'Công nghệ sử dụng',
                          hintText:
                              'Nhập cách nhau bởi dấu phẩy, VD: Flutter, Supabase, PostgreSQL',
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Mô tả đồ án',
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _approachController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Hướng tiếp cận',
                          alignLabelWithHint: true,
                        ),
                      ),
                      if (_isManager) ...[
                        const Divider(height: 32, color: AppColors.border),
                        const Text(
                          'Thông tin lưu trữ (Dành cho Quản trị / Giảng viên)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (!_isEditing) ...[
                          DropdownButtonFormField<String>(
                            initialValue: _selectedStatus,
                            decoration: const InputDecoration(
                              labelText: 'Trạng thái công bố',
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'published',
                                child: Text('Công bố ngay (published)'),
                              ),
                              DropdownMenuItem(
                                value: 'pending',
                                child: Text('Chờ duyệt (pending)'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedStatus = value);
                              }
                            },
                          ),
                          const SizedBox(height: 14),
                        ],
                        TextFormField(
                          controller: _studentCodeController,
                          decoration: const InputDecoration(
                            labelText: 'Mã sinh viên',
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _studentNameController,
                          decoration: const InputDecoration(
                            labelText: 'Tên sinh viên thực hiện',
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _classNameController,
                          decoration: const InputDecoration(labelText: 'Lớp'),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _supervisorController,
                          decoration: const InputDecoration(
                            labelText: 'Giảng viên hướng dẫn',
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _departmentController,
                          decoration: const InputDecoration(
                            labelText: 'Bộ môn / Khoa',
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: _isSaving
                                ? null
                                : () => Navigator.of(context).pop(false),
                            child: const Text('Hủy'),
                          ),
                          const SizedBox(width: 12),
                          FilledButton.icon(
                            onPressed: _isSaving ? null : _submit,
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Icon(
                                    _isManager
                                        ? Icons.save_outlined
                                        : Icons.send_rounded,
                                    size: 18,
                                  ),
                            label: Text(
                              _isManager
                                  ? (_isEditing ? 'Lưu thay đổi' : 'Lưu')
                                  : 'Gửi đề xuất',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
