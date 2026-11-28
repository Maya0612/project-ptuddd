import 'package:flutter/material.dart';

import '../core/supabase_config.dart';
import '../core/theme/app_theme.dart';
import '../models/field_model.dart';
import '../models/project_model.dart';
import '../services/project_repository_service.dart';
import 'project_detail_screen.dart';
import 'project_form_screen.dart';

/// Màn hình Kho đồ án tốt nghiệp (hỗ trợ cả `student` và `lecturer`/`admin`).
class ProjectRepositoryScreen extends StatefulWidget {
  const ProjectRepositoryScreen({
    super.key,
    this.userRole,
    this.service,
    this.initialTabIndex = 0,
  });

  /// Vai trò người dùng ('student', 'lecturer', 'admin').
  /// Nếu bỏ trống, màn hình sẽ tự truy vấn bảng `profiles`.
  final String? userRole;
  final ProjectRepositoryService? service;
  final int initialTabIndex;

  @override
  State<ProjectRepositoryScreen> createState() =>
      _ProjectRepositoryScreenState();
}

class _ProjectRepositoryScreenState extends State<ProjectRepositoryScreen>
    with SingleTickerProviderStateMixin {
  late final ProjectRepositoryService _service =
      widget.service ?? ProjectRepositoryService();
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  String? _role;
  bool _isLoading = true;
  String? _errorMessage;

  List<FieldModel> _fields = [];
  List<ProjectModel> _projects = [];
  Set<String> _favoriteIds = {};
  final Set<String> _togglingFavoriteIds = {};

  String _searchQuery = '';
  String? _selectedFieldId;
  int? _selectedYear;
  String? _selectedTechnology;

  bool get _isManager => _role == 'lecturer' || _role == 'admin';
  bool get _isStudent => _role == 'student';

  String? get _currentUserId {
    if (!SupabaseConfig.isInitialized) return null;
    return supabase.auth.currentUser?.id;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 2),
    );
    _tabController.addListener(_onTabChanged);
    _initScreen();
  }

  @override
  void didUpdateWidget(covariant ProjectRepositoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userRole != widget.userRole) {
      _initScreen();
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging && mounted) {
      setState(() {});
    }
  }

  Future<void> _initScreen() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final resolvedRole = await _resolveUserRole();
      if (!mounted) return;

      if (resolvedRole == null) {
        setState(() {
          _role = null;
          _isLoading = false;
          _errorMessage = 'Không xác định được vai trò tài khoản hiện tại.';
        });
        return;
      }

      setState(() => _role = resolvedRole);
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Không thể khởi tạo kho đồ án: $e';
      });
    }
  }

  Future<String?> _resolveUserRole() async {
    final provided = widget.userRole?.trim().toLowerCase();
    if (provided == 'student' ||
        provided == 'lecturer' ||
        provided == 'admin') {
      return provided;
    }

    if (!SupabaseConfig.isInitialized) return null;
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    final profile = await supabase
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .single();

    final role = (profile['role'] as String?)?.trim().toLowerCase();
    if (role == 'student' || role == 'lecturer' || role == 'admin') {
      return role;
    }
    return null;
  }

  Future<void> _loadData() async {
    if (_role == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final fields = await _service.fetchFields();
      final List<ProjectModel> projects;
      Set<String> favoriteIds = _favoriteIds;

      if (_isManager) {
        projects = await _service.fetchProjectsForManager();
      } else {
        final results = await Future.wait([
          _service.fetchProjectsForStudent(),
          _service.fetchFavoriteProjectIds(),
        ]);
        projects = results[0] as List<ProjectModel>;
        favoriteIds = results[1] as Set<String>;
      }

      if (!mounted) return;
      setState(() {
        _fields = fields;
        _projects = projects;
        _favoriteIds = favoriteIds;
        _sanitizeSelectedFilters();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = '$e';
      });
    }
  }

  void _sanitizeSelectedFilters() {
    if (_selectedFieldId != null &&
        !_fields.any((f) => f.id == _selectedFieldId)) {
      _selectedFieldId = null;
    }
    if (_selectedYear != null && !_availableYears.contains(_selectedYear)) {
      _selectedYear = null;
    }
    if (_selectedTechnology != null &&
        !_availableTechnologies.contains(_selectedTechnology)) {
      _selectedTechnology = null;
    }
  }

  Map<String, String> get _fieldNameById => {
    for (final field in _fields) field.id: field.name,
  };

  List<int> get _availableYears {
    final years = _projects
        .map((p) => p.year)
        .whereType<int>()
        .toSet()
        .toList();
    years.sort((a, b) => b.compareTo(a));
    return years;
  }

  List<String> get _availableTechnologies {
    final techs = <String>{};
    for (final project in _projects) {
      for (final tech in project.technologies) {
        final trimmed = tech.trim();
        if (trimmed.isNotEmpty) {
          techs.add(trimmed);
        }
      }
    }
    final sorted = techs.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return sorted;
  }

  bool get _hasActiveFilters =>
      _searchQuery.trim().isNotEmpty ||
      _selectedFieldId != null ||
      _selectedYear != null ||
      _selectedTechnology != null;

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _selectedFieldId = null;
      _selectedYear = null;
      _selectedTechnology = null;
    });
  }

  List<ProjectModel> _filterProjects(List<ProjectModel> source) {
    final query = _searchQuery.trim().toLowerCase();

    return source.where((project) {
      if (_selectedFieldId != null && project.fieldId != _selectedFieldId) {
        return false;
      }
      if (_selectedYear != null && project.year != _selectedYear) {
        return false;
      }
      if (_selectedTechnology != null &&
          !project.technologies.any(
            (t) => t.toLowerCase() == _selectedTechnology!.toLowerCase(),
          )) {
        return false;
      }
      if (query.isNotEmpty) {
        final titleMatch = project.title.toLowerCase().contains(query);
        final descMatch =
            (project.description ?? '').toLowerCase().contains(query);
        final techMatch = project.technologies.any(
          (t) => t.toLowerCase().contains(query),
        );
        if (!titleMatch && !descMatch && !techMatch) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  Future<void> _handleToggleFavorite(ProjectModel project) async {
    if (_togglingFavoriteIds.contains(project.id)) return;

    final isCurrentlyFavorite = _favoriteIds.contains(project.id);
    setState(() {
      _togglingFavoriteIds.add(project.id);
      if (isCurrentlyFavorite) {
        _favoriteIds.remove(project.id);
      } else {
        _favoriteIds.add(project.id);
      }
    });

    try {
      await _service.toggleFavorite(project.id, isCurrentlyFavorite);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (isCurrentlyFavorite) {
          _favoriteIds.add(project.id);
        } else {
          _favoriteIds.remove(project.id);
        }
      });
      _showSnackBar('Không thể cập nhật yêu thích: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _togglingFavoriteIds.remove(project.id));
      }
    }
  }

  Future<void> _openProjectDetail(ProjectModel project) async {
    final role = _role;
    if (role == null) return;

    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ProjectDetailScreen(
          project: project,
          userRole: role,
          fields: _fields,
          isFavorite: _favoriteIds.contains(project.id),
          service: _service,
        ),
      ),
    );

    if (changed == true && mounted) {
      await _loadData();
    }
  }

  Future<void> _openProjectForm() async {
    final role = _role;
    if (role == null) return;

    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ProjectFormScreen(
          userRole: role,
          fields: _fields,
          service: _service,
        ),
      ),
    );

    if (saved == true && mounted) {
      await _loadData();
    }
  }

  Future<void> _openFieldForm({FieldModel? field}) async {
    final isEditing = field != null;
    final nameController = TextEditingController(text: field?.name ?? '');
    final formKey = GlobalKey<FormState>();
    var isSaving = false;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Text(isEditing ? 'Chỉnh sửa lĩnh vực' : 'Thêm lĩnh vực mới'),
            content: Form(
              key: formKey,
              child: TextFormField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Tên lĩnh vực',
                  hintText: 'Ví dụ: Trí tuệ nhân tạo',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tên lĩnh vực';
                  }
                  return null;
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.of(ctx).pop(false),
                child: const Text('Hủy'),
              ),
              FilledButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setDialogState(() => isSaving = true);
                        try {
                          if (isEditing) {
                            await _service.updateField(
                              field.id,
                              nameController.text.trim(),
                            );
                          } else {
                            await _service.createField(
                              nameController.text.trim(),
                            );
                          }
                          if (ctx.mounted) Navigator.of(ctx).pop(true);
                        } catch (e) {
                          setDialogState(() => isSaving = false);
                          if (mounted) {
                            _showSnackBar('$e', isError: true);
                          }
                        }
                      },
                child: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(isEditing ? 'Cập nhật' : 'Thêm mới'),
              ),
            ],
          );
        },
      ),
    );

    nameController.dispose();

    if (saved == true && mounted) {
      _showSnackBar(
        isEditing ? 'Đã cập nhật lĩnh vực.' : 'Đã thêm lĩnh vực mới.',
      );
      await _loadData();
    }
  }

  Future<void> _confirmDeleteField(FieldModel field) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa lĩnh vực'),
        content: Text(
          'Bạn có chắc muốn xóa lĩnh vực "${field.name}" không?\n'
          'Các đồ án thuộc lĩnh vực này sẽ chuyển về chưa phân loại.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _service.deleteField(field.id);
      if (!mounted) return;
      _showSnackBar('Đã xóa lĩnh vực "${field.name}".');
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('$e', isError: true);
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

  @override
  Widget build(BuildContext context) {
    final showProjectFilters =
        _role != null && !(_isManager && _tabController.index == 2);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeaderWithTabs(),
          if (_role != null && showProjectFilters) _buildSearchAndFilterBar(),
          Expanded(child: _buildBodyContent()),
        ],
      ),
      floatingActionButton: _role == null
          ? null
          : FloatingActionButton.extended(
              onPressed: _openProjectForm,
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textLight,
              icon: const Icon(Icons.add_rounded),
              label: Text(
                _isManager ? 'Thêm đồ án mới' : 'Đề xuất đồ án',
              ),
            ),
    );
  }

  Widget _buildHeaderWithTabs() {
    final tabs = _isManager
        ? const [
            Tab(text: 'Tất cả đồ án'),
            Tab(text: 'Chờ duyệt'),
            Tab(text: 'Quản lý lĩnh vực'),
          ]
        : const [
            Tab(text: 'Kho đồ án'),
            Tab(text: 'Yêu thích'),
            Tab(text: 'Đề xuất của tôi'),
          ];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 16, 6),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.library_books_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isManager
                            ? 'Quản lý kho đồ án'
                            : 'Kho đồ án tốt nghiệp',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        _isManager
                            ? 'Quản trị đồ án lưu trữ, duyệt đề xuất và danh mục lĩnh vực'
                            : 'Tham khảo đồ án khóa trước, lưu yêu thích và đề xuất bổ sung',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Làm mới',
                  onPressed: _isLoading ? null : _loadData,
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          if (_role != null)
            TabBar(
              controller: _tabController,
              tabs: tabs,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              indicatorColor: AppColors.primary,
              indicatorWeight: 2.5,
              dividerColor: Colors.transparent,
            ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    final years = _availableYears;
    final technologies = _availableTechnologies;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Tìm theo tên đề tài, mô tả hoặc công nghệ...',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      tooltip: 'Xóa từ khóa',
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 11,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 210,
                child: DropdownButtonFormField<String?>(
                  key: ValueKey('field_$_selectedFieldId'),
                  initialValue: _selectedFieldId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Lĩnh vực',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Tất cả lĩnh vực'),
                    ),
                    ..._fields.map(
                      (field) => DropdownMenuItem<String?>(
                        value: field.id,
                        child: Text(
                          field.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() => _selectedFieldId = value),
                ),
              ),
              SizedBox(
                width: 150,
                child: DropdownButtonFormField<int?>(
                  key: ValueKey('year_$_selectedYear'),
                  initialValue: _selectedYear,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Năm thực hiện',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Tất cả năm'),
                    ),
                    ...years.map(
                      (year) => DropdownMenuItem<int?>(
                        value: year,
                        child: Text('$year'),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() => _selectedYear = value),
                ),
              ),
              SizedBox(
                width: 190,
                child: DropdownButtonFormField<String?>(
                  key: ValueKey('tech_$_selectedTechnology'),
                  initialValue: _selectedTechnology,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Công nghệ',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Tất cả công nghệ'),
                    ),
                    ...technologies.map(
                      (tech) => DropdownMenuItem<String?>(
                        value: tech,
                        child: Text(tech, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => _selectedTechnology = value),
                ),
              ),
              if (_hasActiveFilters)
                TextButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                  label: const Text('Xóa lọc'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBodyContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: AppColors.danger,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _role == null ? _initScreen : _loadData,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (_isManager) {
      final allProjects = _filterProjects(_projects);
      final pendingProjects = _filterProjects(
        _projects.where((p) => p.isPending).toList(),
      );

      return TabBarView(
        controller: _tabController,
        children: [
          _buildProjectList(
            projects: allProjects,
            showStatusBadge: true,
            emptyMessage: 'Chưa có đồ án nào phù hợp trong kho.',
          ),
          _buildProjectList(
            projects: pendingProjects,
            showStatusBadge: true,
            emptyMessage: 'Không có đề xuất đồ án nào đang chờ duyệt.',
          ),
          _buildFieldManagementTab(),
        ],
      );
    }

    final publishedProjects = _filterProjects(
      _projects.where((p) => p.isPublished).toList(),
    );
    final favoriteProjects = _filterProjects(
      _projects
          .where((p) => p.isPublished && _favoriteIds.contains(p.id))
          .toList(),
    );
    final myProposals = _filterProjects(
      _projects
          .where(
            (p) =>
                _currentUserId != null && p.submittedBy == _currentUserId,
          )
          .toList(),
    );

    return TabBarView(
      controller: _tabController,
      children: [
        _buildProjectList(
          projects: publishedProjects,
          showStatusBadge: false,
          emptyMessage: 'Chưa có đồ án công bố nào phù hợp.',
        ),
        _buildProjectList(
          projects: favoriteProjects,
          showStatusBadge: false,
          emptyMessage: 'Bạn chưa lưu đồ án yêu thích nào.',
        ),
        _buildProjectList(
          projects: myProposals,
          showStatusBadge: true,
          emptyMessage: 'Bạn chưa gửi đề xuất đồ án nào.',
        ),
      ],
    );
  }

  Widget _buildProjectList({
    required List<ProjectModel> projects,
    required bool showStatusBadge,
    required String emptyMessage,
  }) {
    if (projects.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(32),
          children: [
            const SizedBox(height: 48),
            Icon(
              Icons.folder_open_rounded,
              size: 56,
              color: AppColors.secondary.withValues(alpha: 0.9),
            ),
            const SizedBox(height: 12),
            Text(
              emptyMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            if (_hasActiveFilters) ...[
              const SizedBox(height: 12),
              Center(
                child: OutlinedButton(
                  onPressed: _clearFilters,
                  child: const Text('Xóa bộ lọc hiện tại'),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
        itemCount: projects.length,
        itemBuilder: (context, index) {
          final project = projects[index];
          return _buildProjectCard(
            project: project,
            showStatusBadge: showStatusBadge,
          );
        },
      ),
    );
  }

  Widget _buildProjectCard({
    required ProjectModel project,
    required bool showStatusBadge,
  }) {
    final fieldName = project.fieldId != null
        ? (_fieldNameById[project.fieldId] ?? 'Chưa phân loại')
        : 'Chưa phân loại';
    final isFavorite = _favoriteIds.contains(project.id);
    final showFavoriteButton = _isStudent && project.isPublished;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openProjectDetail(project),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      project.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        height: 1.3,
                      ),
                    ),
                  ),
                  if (showStatusBadge) ...[
                    const SizedBox(width: 8),
                    _buildStatusBadge(project.status),
                  ],
                  if (showFavoriteButton) ...[
                    const SizedBox(width: 4),
                    IconButton(
                      tooltip: isFavorite ? 'Bỏ yêu thích' : 'Lưu yêu thích',
                      onPressed: () => _handleToggleFavorite(project),
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: isFavorite
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _buildMetaTag(
                    icon: Icons.category_outlined,
                    label: fieldName,
                    isHighlighted: true,
                  ),
                  if (project.year != null)
                    _buildMetaTag(
                      icon: Icons.calendar_today_outlined,
                      label: 'Năm ${project.year}',
                    ),
                ],
              ),
              if (project.description != null &&
                  project.description!.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  project.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
              if (project.technologies.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: project.technologies
                      .map((tech) => _buildTechChip(tech))
                      .toList(),
                ),
              ],
            ],
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildMetaTag({
    required IconData icon,
    required String label,
    bool isHighlighted = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isHighlighted ? AppColors.primaryLight : AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isHighlighted ? AppColors.secondary : AppColors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isHighlighted ? AppColors.primary : AppColors.textSecondary,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color:
                  isHighlighted ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechChip(String tech) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        tech,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildFieldManagementTab() {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Danh mục lĩnh vực (${_fields.length})',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: () => _openFieldForm(),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Thêm lĩnh vực'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_fields.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Chưa có lĩnh vực nào. Nhấn "Thêm lĩnh vực" để tạo mới.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            ..._fields.map(
              (field) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.category_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                  title: Text(
                    field.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Sửa lĩnh vực',
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: AppColors.primary,
                        ),
                        onPressed: () => _openFieldForm(field: field),
                      ),
                      IconButton(
                        tooltip: 'Xóa lĩnh vực',
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: AppColors.danger,
                        ),
                        onPressed: () => _confirmDeleteField(field),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
