import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/profile.dart';
import '../providers/auth_provider.dart';
import '../providers/project_provider.dart';
import '../widgets/project_card.dart';
import '../widgets/role_gate.dart';
import 'login_screen.dart';
import 'project_detail_screen.dart';
import 'project_form_screen.dart';

class ProjectListScreen extends StatefulWidget {
  final UserRole? role;
  final bool isAuthenticated;

  const ProjectListScreen({super.key, this.role, this.isAuthenticated = false});

  @override
  State<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> {
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ProjectProvider>().load(status: _statusFilter);
      }
    });
  }

  @override
  void didUpdateWidget(covariant ProjectListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.role != widget.role ||
        oldWidget.isAuthenticated != widget.isAuthenticated) {
      _statusFilter = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<ProjectProvider>().load();
      });
    }
  }

  void _changeFilter(String? value) {
    setState(() => _statusFilter = value);
    context.read<ProjectProvider>().load(status: value);
  }

  Future<void> _signOut() async {
    final auth = context.read<AuthProvider>();
    final success = await auth.signOut();
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage ?? 'Không thể đăng xuất')),
      );
    }
  }

  Future<void> _openLogin() async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isStaff =
        widget.role == UserRole.lecturer || widget.role == UserRole.admin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kho đồ án'),
        actions: [
          if (isStaff)
            DropdownButton<String?>(
              value: _statusFilter,
              hint: const Text('Tất cả'),
              items: const [
                DropdownMenuItem<String?>(value: null, child: Text('Tất cả')),
                DropdownMenuItem(value: 'pending', child: Text('Chờ duyệt')),
                DropdownMenuItem(value: 'approved', child: Text('Đã duyệt')),
                DropdownMenuItem(value: 'rejected', child: Text('Bị từ chối')),
              ],
              onChanged: _changeFilter,
            ),
          if (auth.isAuthenticated)
            IconButton(
              tooltip: 'Đăng xuất',
              onPressed: auth.isLoading ? null : _signOut,
              icon: const Icon(Icons.logout),
            )
          else
            TextButton(onPressed: _openLogin, child: const Text('Đăng nhập')),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          if (auth.isAuthenticated && auth.errorMessage != null)
            MaterialBanner(
              content: Text(auth.errorMessage!),
              actions: [
                TextButton(
                  onPressed: auth.isLoading ? null : auth.refresh,
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          Expanded(
            child: Consumer<ProjectProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (provider.errorMessage != null) {
                  return RefreshIndicator(
                    onRefresh: () => provider.load(status: _statusFilter),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.sizeOf(context).height * 0.6,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(provider.errorMessage!),
                                const SizedBox(height: 12),
                                FilledButton(
                                  onPressed: () =>
                                      provider.load(status: _statusFilter),
                                  child: const Text('Thử lại'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                if (provider.projects.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () => provider.load(status: _statusFilter),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.sizeOf(context).height * 0.7,
                          child: const Center(
                            child: Text('Chưa có đồ án phù hợp'),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => provider.load(status: _statusFilter),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.projects.length,
                    itemBuilder: (context, index) {
                      final project = provider.projects[index];
                      return ProjectCard(
                        project: project,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProjectDetailScreen(
                                projectId: project.id,
                                role: widget.role,
                              ),
                            ),
                          );
                          if (context.mounted) {
                            provider.load(status: _statusFilter);
                          }
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: RoleGate(
        role: widget.role,
        child: FloatingActionButton.extended(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProjectFormScreen(role: widget.role),
              ),
            );
            if (context.mounted) {
              context.read<ProjectProvider>().load(status: _statusFilter);
            }
          },
          icon: const Icon(Icons.add),
          label: const Text('Thêm đồ án'),
        ),
      ),
    );
  }
}
