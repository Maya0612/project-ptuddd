import 'package:flutter/material.dart';

import '../models/ai_suggestion_model.dart';
import '../services/ai_suggestion_service.dart';
import '../services/project_comparison_service.dart';
import '../personal_topic_service.dart';

class AiSuggestionScreen extends StatefulWidget {
  const AiSuggestionScreen({super.key});

  @override
  State<AiSuggestionScreen> createState() => _AiSuggestionScreenState();
}

class _AiSuggestionScreenState extends State<AiSuggestionScreen> {
  final _formKey = GlobalKey<FormState>();

  final _interestsController = TextEditingController();
  final _skillsController = TextEditingController();
  final _technologiesController = TextEditingController();
  final _descriptionController = TextEditingController();

  final _aiService = AiSuggestionService();
  final _comparisonService = ProjectComparisonService();
  final _personalTopicService = PersonalTopicService();

  List<AiTopicSuggestion> _suggestions = [];

  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _interestsController.dispose();
    _skillsController.dispose();
    _technologiesController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  List<String> _splitInput(String value) {
    return value
        .split(RegExp(r'[,;\n]'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  Future<void> _generateSuggestions() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _suggestions = [];
    });

    final request = AiSuggestionRequest(
      interests: _splitInput(_interestsController.text),
      skills: _splitInput(_skillsController.text),
      technologies: _splitInput(_technologiesController.text),
      description: _descriptionController.text.trim(),
    );

    try {
      final suggestions = await _aiService.generateSuggestions(request);

      if (!mounted) return;

      setState(() {
        _suggestions = suggestions;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveSuggestion(AiTopicSuggestion suggestion) async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await _personalTopicService.saveFromAiSuggestion(
        title: suggestion.title,
        description: suggestion.description,
        objectives: suggestion.objectives,
        field: suggestion.field,
        technologies: suggestion.technologies.join(', '),
        implementationPlan: suggestion.methodology,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã lưu đề tài vào danh sách đề tài cá nhân.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Không thể lưu đề tài: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  List<ProjectComparisonResult> _compareSuggestion(
    AiTopicSuggestion suggestion,
  ) {
    // Chưa có nguồn đồ án TV2 tích hợp.
    // Không tạo dữ liệu giả để đối chiếu.
    return _comparisonService.compareSuggestionToProjects(
      suggestion: suggestion,
      approvedProjects: [],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    bool requiredField = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
          alignLabelWithHint: maxLines > 1,
        ),
        validator: requiredField
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập $label';
                }
                return null;
              }
            : null,
      ),
    );
  }

  Widget _buildInputForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Thông tin định hướng',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _interestsController,
                label: 'Sở thích / lĩnh vực quan tâm',
                hint: 'Ví dụ: AI, giáo dục, quản lý dữ liệu',
                maxLines: 2,
                requiredField: true,
              ),
              _buildTextField(
                controller: _skillsController,
                label: 'Kỹ năng hiện có',
                hint: 'Ví dụ: Flutter, SQL, Python',
                maxLines: 2,
                requiredField: true,
              ),
              _buildTextField(
                controller: _technologiesController,
                label: 'Công nghệ mong muốn',
                hint: 'Ví dụ: Flutter, Supabase, Firebase',
                maxLines: 2,
              ),
              _buildTextField(
                controller: _descriptionController,
                label: 'Mô tả định hướng thêm',
                hint: 'Mục tiêu, yêu cầu, quy mô hoặc ý tưởng...',
                maxLines: 4,
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _generateSuggestions,
                  icon: const Icon(Icons.auto_awesome),
                  label: Text(
                    _isLoading ? 'Đang tạo đề tài...' : 'AI gợi ý đề tài',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComparisonSection(AiTopicSuggestion suggestion) {
    final comparisons = _compareSuggestion(suggestion);

    if (comparisons.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 12),
        child: Text(
          'Chưa có dữ liệu đồ án đã duyệt để đối chiếu. '
          'Chức năng sẽ được kết nối với nguồn dữ liệu TV2.',
          style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: comparisons.map((comparison) {
        return ListTile(
          title: Text(comparison.projectName),
          subtitle: Text(comparison.warning),
          trailing: Text('${comparison.similarityScore.toStringAsFixed(1)}%'),
        );
      }).toList(),
    );
  }

  Widget _buildSuggestionCard(AiTopicSuggestion suggestion, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Đề tài ${index + 1}: ${suggestion.title}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            const Text('Mô tả', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(suggestion.description),

            const SizedBox(height: 12),
            const Text(
              'Mục tiêu',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(suggestion.objectives),

            const SizedBox(height: 12),
            const Text(
              'Phương pháp dự kiến',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(suggestion.methodology),

            const SizedBox(height: 12),
            const Text(
              'Lĩnh vực',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(suggestion.field.isEmpty ? 'Chưa xác định' : suggestion.field),

            const SizedBox(height: 12),
            const Text(
              'Công nghệ đề xuất',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: suggestion.technologies.map((technology) {
                return Chip(label: Text(technology));
              }).toList(),
            ),

            const Divider(height: 24),

            const Text(
              'Đối chiếu với đồ án đã duyệt',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            _buildComparisonSection(suggestion),

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isSaving ? null : () => _saveSuggestion(suggestion),
                icon: const Icon(Icons.bookmark_add_outlined),
                label: const Text('Lưu đề tài này'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Text(
            'Kết quả gợi ý',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
        ..._suggestions.asMap().entries.map((entry) {
          return _buildSuggestionCard(entry.value, entry.key);
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI gợi ý đề tài')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInputForm(),

            if (_isLoading) ...[
              const SizedBox(height: 24),
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 8),
              const Center(
                child: Text('AI đang phân tích thông tin của bạn...'),
              ),
            ],

            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],

            _buildResults(),
          ],
        ),
      ),
    );
  }
}
