import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_config.dart';
import 'plan_list_screen.dart';

class PlanningTabScreen extends StatefulWidget {
  const PlanningTabScreen({super.key, this.client});

  final SupabaseClient? client;

  @override
  State<PlanningTabScreen> createState() => _PlanningTabScreenState();
}

class _PlanningTabScreenState extends State<PlanningTabScreen> {
  late final SupabaseClient _client = widget.client ?? supabase;
  List<Map<String, dynamic>> _topics = [];
  String? _selectedTopicId;
  Object? _loadError;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTopics();
  }

  Future<void> _loadTopics() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw StateError('Cần đăng nhập để xem kế hoạch.');
      }

      final rows = await _client
          .from('personal_topics')
          .select('id, title')
          .eq('user_id', user.id);
      if (!mounted) return;

      final topics = List<Map<String, dynamic>>.from(rows);
      setState(() {
        _topics = topics;
        if (!topics.any((topic) => topic['id'] == _selectedTopicId)) {
          _selectedTopicId = topics.isEmpty
              ? null
              : topics.first['id'] as String;
        }
      });
    } catch (error) {
      if (mounted) setState(() => _loadError = error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Không thể tải đề tài cá nhân.'),
              const SizedBox(height: 8),
              Text('Chi tiết: $_loadError', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loadTopics,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (_topics.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Bạn cần tạo đề tài cá nhân trước khi lập kế hoạch.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      children: [
        if (_topics.length > 1)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: DropdownButtonFormField<String>(
              initialValue: _selectedTopicId,
              decoration: const InputDecoration(
                labelText: 'Đề tài cá nhân',
                border: OutlineInputBorder(),
              ),
              items: _topics
                  .map(
                    (topic) => DropdownMenuItem<String>(
                      value: topic['id'] as String,
                      child: Text(topic['title'] as String),
                    ),
                  )
                  .toList(),
              onChanged: (topicId) {
                if (topicId != null) {
                  setState(() => _selectedTopicId = topicId);
                }
              },
            ),
          ),
        Expanded(child: PlanListScreen(personalTopicId: _selectedTopicId!)),
      ],
    );
  }
}
