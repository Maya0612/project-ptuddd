import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/field_model.dart';
import '../models/project_model.dart';
import '../services/project_repository_service.dart';
import 'project_form_screen.dart';

/// Màn hình chi tiết đồ án tốt nghiệp.
class ProjectDetailScreen extends StatefulWidget {
  const ProjectDetailScreen({
    super.key,
    required this.project,
    required this.userRole,
    required this.fields,
    this.isFavorite = false,
    this.service,
  });

  final ProjectModel project;
  final String userRole;
  final List<FieldModel> fields;
  final bool isFavorite;
  final ProjectRepositoryService? service;

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  late final ProjectRepositoryService _service =
      widget.service ?? ProjectRepositoryService();

  late ProjectModel _project;
  late bool _isFavorite;
  bool _isTogglingFavorite = false;
  bool _isReviewing = false;
  bool _hasChanges = false;

  String get _normalizedRole => widget.userRole.trim().toLowerCase();
  bool get _isManager =>
      _normalizedRole == 'admin' || _normalizedRole == 'lecturer';
  bool get _isStudent => _normalizedRole == 'student';

  @override
  void initState() {
    super.initState();
    _project = widget.project;
    _isFavorite = widget.isFavorite;
  }

  String get _fieldName {
    if (_project.fieldId == null) return 'Chưa phân loại';
    for (final field in widget.fields) {
      if (field.id == _project.fieldId) {
        return field.name;
      }
    }
    return 'Chưa phân loại';
  }

  Future<void> _handleToggleFavorite() async {
    if (_isTogglingFavorite) return;

    final previous = _isFavorite;
    setState(() {
      _isTogglingFavorite = true;
      _isFavorite = !previous;
    });

    try {
      await _service.toggleFavorite(_project.id, previous);
      if (!mounted) return;
      _hasChanges = true;
      _showSnackBar(
        _isFavorite
            ? 'Đã lưu vào danh sách yêu thích.'
            : 'Đã bỏ khỏi danh sách yêu thích.',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isFavorite = previous);
      _showSnackBar('Không thể cập nhật yêu thích: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isTogglingFavorite = false);
      }
    }
  }

  Future<void> _handleEditProject() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ProjectFormScreen(
          userRole: widget.userRole,
          fields: widget.fields,
          initialProject: _project,
          service: _service,
        ),
      ),
    );

    if (saved == true && mounted) {
      _hasChanges = true;
      await _reloadCurrentProject();
    }
  }

  Future<void> _reloadCurrentProject() async {
    try {
      final list = _isManager
          ? await _service.fetchProjectsForManager()
          : await _service.fetchProjectsForStudent();

      final updated = list.where((item) => item.id == _project.id).firstOrNull;
      if (updated != null && mounted) {
        setState(() => _project = updated);
      }
    } catch (_) {
      // Nếu không tải lại được ngay, giữ dữ liệu hiện có và vẫn trả _hasChanges về màn hình trước.
    }
  }

  Future<void> _confirmAndReview(String targetStatus) async {
    final isPublishing = targetStatus == 'published';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isPublishing ? 'Duyệt công bố đồ án' : 'Từ chối đồ án'),
        content: Text(
          isPublishing
              ? 'Xác nhận duyệt và công bố đồ án "${_project.title}" lên kho chung?'
              : 'Xác nhận từ chối đồ án "${_project.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor:
                  isPublishing ? AppColors.success : AppColors.danger,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(isPublishing ? 'Duyệt công bố' : 'Từ chối'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isReviewing = true);
    try {
      await _service.reviewProject(_project.id, targetStatus);
      if (!mounted) return;
      setState(() {
        _project = _project.copyWith(
          status: targetStatus,
          reviewedAt: DateTime.now(),
        );
        _hasChanges = true;
      });
      _showSnackBar(
        isPublishing ? 'Đã duyệt công bố đồ án.' : 'Đã từ chối đồ án.',
      );
      await _reloadCurrentProject();
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('$e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isReviewing = false);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.danger : AppColors.success,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    return '$day/$month/${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    final canToggleFavorite = _isStudent && _project.isPublished;

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          Navigator.of(context).pop(_hasChanges);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Chi tiết đồ án'),
          leading: IconButton(
            tooltip: 'Quay lại',
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).pop(_hasChanges),
          ),
          actions: [
            if (canToggleFavorite)
              IconButton(
                tooltip: _isFavorite ? 'Bỏ lưu yêu thích' : 'Lưu yêu thích',
                onPressed: _isTogglingFavorite ? null : _handleToggleFavorite,
                icon: Icon(
                  _isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: _isFavorite ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            if (_isManager)
              IconButton(
                tooltip: 'Chỉnh sửa',
                onPressed: _isReviewing ? null : _handleEditProject,
                icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
              ),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildHeaderCard(canToggleFavorite),
                const SizedBox(height: 16),
                _buildSectionCard(
                  title: 'Mô tả đồ án',
                  icon: Icons.description_outlined,
                  child: Text(
                    (_project.description != null &&
                            _project.description!.trim().isNotEmpty)
                        ? _project.description!
                        : 'Chưa có mô tả chi tiết.',
                    style: TextStyle(
                      fontSize: 14.5,
                      height: 1.55,
                      color: (_project.description != null &&
                              _project.description!.trim().isNotEmpty)
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontStyle: (_project.description != null &&
                              _project.description!.trim().isNotEmpty)
                          ? FontStyle.normal
                          : FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildSectionCard(
                  title: 'Hướng tiếp cận',
                  icon: Icons.lightbulb_outline_rounded,
                  child: Text(
                    (_project.approach != null &&
                            _project.approach!.trim().isNotEmpty)
                        ? _project.approach!
                        : 'Chưa có thông tin hướng tiếp cận.',
                    style: TextStyle(
                      fontSize: 14.5,
                      height: 1.55,
                      color: (_project.approach != null &&
                              _project.approach!.trim().isNotEmpty)
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontStyle: (_project.approach != null &&
                              _project.approach!.trim().isNotEmpty)
                          ? FontStyle.normal
                          : FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildSectionCard(
                  title: 'Công nghệ sử dụng',
                  icon: Icons.code_rounded,
                  child: _project.technologies.isEmpty
                      ? const Text(
                          'Chưa cập nhật danh sách công nghệ.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        )
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _project.technologies
                              .map((tech) => _buildTechChip(tech))
                              .toList(),
                        ),
                ),
                if (_isManager) ...[
                  const SizedBox(height: 16),
                  _buildArchiveInfoCard(),
                  const SizedBox(height: 16),
                  _buildManagerActionsCard(),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(bool canToggleFavorite) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildStatusBadge(_project.status),
                const Spacer(),
                if (_project.createdAt != null)
                  Text(
                    'Tạo ngày ${_formatDate(_project.createdAt!)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              _project.title,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                _buildMetaBadge(
                  icon: Icons.category_outlined,
                  label: _fieldName,
                  highlighted: true,
                ),
                if (_project.year != null)
                  _buildMetaBadge(
                    icon: Icons.calendar_today_outlined,
                    label: 'Năm ${_project.year}',
                  ),
                if (_project.reviewedAt != null)
                  _buildMetaBadge(
                    icon: Icons.verified_outlined,
                    label: 'Duyệt: ${_formatDate(_project.reviewedAt!)}',
                  ),
              ],
            ),
            if (canToggleFavorite) ...[
              const SizedBox(height: 16),
              const Divider(height: 1, color: AppColors.borderSubtle),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerLeft,
                child: _isFavorite
                    ? FilledButton.icon(
                        onPressed:
                            _isTogglingFavorite ? null : _handleToggleFavorite,
                        icon: const Icon(Icons.favorite_rounded, size: 18),
                        label: const Text('Đã lưu yêu thích (Bỏ lưu)'),
                      )
                    : OutlinedButton.icon(
                        onPressed:
                            _isTogglingFavorite ? null : _handleToggleFavorite,
                        icon: const Icon(
                          Icons.favorite_border_rounded,
                          size: 18,
                        ),
                        label: const Text('Lưu vào yêu thích'),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildArchiveInfoCard() {
    return _buildSectionCard(
      title: 'Thông tin lưu trữ',
      icon: Icons.inventory_2_outlined,
      child: Column(
        children: [
          _buildInfoRow('Sinh viên thực hiện', _project.studentName),
          _buildInfoRow('Mã sinh viên', _project.studentCode),
          _buildInfoRow('Lớp', _project.className),
          _buildInfoRow('Giảng viên hướng dẫn', _project.supervisorName),
          _buildInfoRow(
            'Bộ môn / Khoa',
            _project.departmentName,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value, {bool isLast = false}) {
    final displayValue = (value != null && value.trim().isNotEmpty)
        ? value.trim()
        : 'Chưa cập nhật';
    final hasValue = value != null && value.trim().isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 170,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              displayValue,
              style: TextStyle(
                fontSize: 14,
                fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
                color: hasValue ? AppColors.textPrimary : AppColors.textSecondary,
                fontStyle: hasValue ? FontStyle.normal : FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManagerActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thao tác quản trị',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: _isReviewing ? null : _handleEditProject,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Chỉnh sửa'),
                ),
                if (!_project.isPublished)
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.success,
                    ),
                    onPressed: _isReviewing
                        ? null
                        : () => _confirmAndReview('published'),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Duyệt công bố'),
                  ),
                if (!_project.isRejected)
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.danger,
                    ),
                    onPressed: _isReviewing
                        ? null
                        : () => _confirmAndReview('rejected'),
                    icon: const Icon(Icons.cancel_outlined, size: 18),
                    label: const Text('Từ chối'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final (String label, Color color) = switch (status) {
      'published' => (
        _isStudent ? 'Được duyệt' : 'Đã công bố',
        AppColors.success,
      ),
      'rejected' => (
        _isStudent ? 'Bị từ chối' : 'Từ chối',
        AppColors.danger,
      ),
      _ => ('Chờ duyệt', AppColors.warning),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildMetaBadge({
    required IconData icon,
    required String label,
    bool highlighted = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: highlighted ? AppColors.primaryLight : AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: highlighted ? AppColors.secondary : AppColors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: highlighted ? AppColors.primary : AppColors.textSecondary,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: highlighted ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechChip(String tech) {
    return Chip(
      label: Text(
        tech,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      backgroundColor: AppColors.background,
      side: const BorderSide(color: AppColors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}
