import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/library_provider.dart';
import '../services/api_client.dart';
import '../widgets/common.dart';
import 'quiz_detail_screen.dart';

class _QuestionDraft {
  final TextEditingController text = TextEditingController();
  final TextEditingController optionA = TextEditingController();
  final TextEditingController optionB = TextEditingController();
  final TextEditingController optionC = TextEditingController();
  final TextEditingController optionD = TextEditingController();
  final TextEditingController explanation = TextEditingController();
  String correctAnswer = 'A';

  void dispose() {
    text.dispose();
    optionA.dispose();
    optionB.dispose();
    optionC.dispose();
    optionD.dispose();
    explanation.dispose();
  }
}

class CreateQuizScreen extends StatefulWidget {
  const CreateQuizScreen({super.key});

  @override
  State<CreateQuizScreen> createState() => _CreateQuizScreenState();
}

class _CreateQuizScreenState extends State<CreateQuizScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _timeLimitController = TextEditingController(text: '15');
  String _difficulty = 'MEDIUM';

  final List<_QuestionDraft> _questions = [];
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _addQuestion(); // Bắt đầu với 1 câu hỏi mẫu
  }

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    _timeLimitController.dispose();
    for (final q in _questions) {
      q.dispose();
    }
    super.dispose();
  }

  void _addQuestion() {
    setState(() {
      _questions.add(_QuestionDraft());
    });
  }

  void _removeQuestion(int index) {
    if (_questions.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bộ đề cần ít nhất 1 câu hỏi')),
      );
      return;
    }
    setState(() {
      final removed = _questions.removeAt(index);
      removed.dispose();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng điền đầy đủ các thông tin bắt buộc')),
      );
      return;
    }

    final questionsPayload = <Map<String, dynamic>>[];
    for (var i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      final text = q.text.text.trim();
      final a = q.optionA.text.trim();
      final b = q.optionB.text.trim();
      final c = q.optionC.text.trim();
      final d = q.optionD.text.trim();

      if (text.isEmpty || a.isEmpty || b.isEmpty) {
        setState(() {
          _error = 'Câu hỏi số ${i + 1} chưa nhập đủ nội dung hoặc đáp án A, B.';
        });
        return;
      }

      questionsPayload.add({
        'questionText': text,
        'optionA': a,
        'optionB': b,
        'optionC': c.isNotEmpty ? c : null,
        'optionD': d.isNotEmpty ? d : null,
        'correctAnswer': q.correctAnswer,
        'explanation': q.explanation.text.trim().isNotEmpty ? q.explanation.text.trim() : null,
      });
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final lib = context.read<LibraryProvider>();
      final minutes = int.tryParse(_timeLimitController.text.trim()) ?? 15;
      final created = await lib.createQuiz(
        title: _titleController.text.trim(),
        category: _categoryController.text.trim(),
        description: _descriptionController.text.trim(),
        timeLimitMinutes: minutes,
        difficulty: _difficulty,
        questions: questionsPayload,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tạo bộ đề "${created.title}" thành công!')),
      );

      _resetForm();

      // Mở xem chi tiết bộ đề vừa tạo
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => QuizDetailScreen(quizId: created.id)),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e is ApiException ? e.message : 'Tạo bộ đề thất bại: $e';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _resetForm() {
    _titleController.clear();
    _categoryController.clear();
    _descriptionController.clear();
    _timeLimitController.text = '15';
    for (final q in _questions) {
      q.dispose();
    }
    _questions.clear();
    _addQuestion();
    setState(() => _error = null);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        Text('Tạo bộ đề thủ công', style: AppTheme.head(size: 22, w: FontWeight.w800)),
        const SizedBox(height: 4),
        Text('Tự soạn câu hỏi và đáp án cho bài thi trắc nghiệm.',
            style: TextStyle(color: cs.onSurfaceVariant)),
        const SizedBox(height: 16),
        if (_error != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: cs.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_error!, style: TextStyle(color: cs.onErrorContainer)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Thông tin bộ đề', style: AppTheme.head(size: 16, w: FontWeight.w700)),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('create_quiz_title'),
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Tên bộ đề *',
                        hintText: 'Ví dụ: Ôn thi PRM393 - Kỳ FA24',
                        prefixIcon: Icon(Icons.title),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tên bộ đề' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('create_quiz_category'),
                      controller: _categoryController,
                      decoration: const InputDecoration(
                        labelText: 'Danh mục / Môn học *',
                        hintText: 'Ví dụ: PRM393, Flutter, Triết học',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập danh mục' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('create_quiz_description'),
                      controller: _descriptionController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Mô tả (tùy chọn)',
                        hintText: 'Ghi chú về bộ đề ôn tập...',
                        prefixIcon: Icon(Icons.description_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            key: const Key('create_quiz_time_limit'),
                            controller: _timeLimitController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Thời gian (phút)',
                              prefixIcon: Icon(Icons.timer_outlined),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return null;
                              final n = int.tryParse(v.trim());
                              if (n == null || n <= 0) return 'Số phút không hợp lệ';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            key: const Key('create_quiz_difficulty'),
                            initialValue: _difficulty,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Độ khó',
                            ),
                            items: const [
                              DropdownMenuItem(value: 'EASY', child: Text('EASY')),
                              DropdownMenuItem(value: 'MEDIUM', child: Text('MEDIUM')),
                              DropdownMenuItem(value: 'HARD', child: Text('HARD')),
                            ],
                            onChanged: (v) => setState(() => _difficulty = v ?? 'MEDIUM'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text('Danh sách câu hỏi (${_questions.length})',
                        style: AppTheme.head(size: 18, w: FontWeight.w700)),
                  ),
                  TextButton.icon(
                    key: const Key('add_question_btn'),
                    onPressed: _addQuestion,
                    icon: const Icon(Icons.add),
                    label: const Text('Thêm câu hỏi'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              for (var i = 0; i < _questions.length; i++) ...[
                _QuestionCard(
                  index: i,
                  draft: _questions[i],
                  onRemove: () => _removeQuestion(i),
                  canRemove: _questions.length > 1,
                  onCorrectAnswerChanged: (ans) {
                    setState(() => _questions[i].correctAnswer = ans);
                  },
                ),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 12),
              FilledButton.icon(
                key: const Key('submit_create_quiz'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                onPressed: _busy ? null : _submit,
                icon: _busy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(_busy ? 'Đang tạo...' : 'Tạo bộ đề'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final int index;
  final _QuestionDraft draft;
  final VoidCallback onRemove;
  final bool canRemove;
  final ValueChanged<String> onCorrectAnswerChanged;

  const _QuestionCard({
    required this.index,
    required this.draft,
    required this.onRemove,
    required this.canRemove,
    required this.onCorrectAnswerChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Câu hỏi ${index + 1}',
                  style: AppTheme.head(size: 15, w: FontWeight.w700, color: cs.primary)),
              if (canRemove)
                IconButton(
                  tooltip: 'Xóa câu này',
                  icon: Icon(Icons.delete_outline, color: cs.error, size: 20),
                  onPressed: onRemove,
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            key: Key('q_text_$index'),
            controller: draft.text,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Nội dung câu hỏi *',
              hintText: 'Nhập câu hỏi...',
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập câu hỏi' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: Key('q_opt_a_$index'),
            controller: draft.optionA,
            decoration: const InputDecoration(
              labelText: 'Đáp án A *',
              prefixText: 'A. ',
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập đáp án A' : null,
          ),
          const SizedBox(height: 8),
          TextFormField(
            key: Key('q_opt_b_$index'),
            controller: draft.optionB,
            decoration: const InputDecoration(
              labelText: 'Đáp án B *',
              prefixText: 'B. ',
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập đáp án B' : null,
          ),
          const SizedBox(height: 8),
          TextFormField(
            key: Key('q_opt_c_$index'),
            controller: draft.optionC,
            decoration: const InputDecoration(
              labelText: 'Đáp án C (tùy chọn)',
              prefixText: 'C. ',
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            key: Key('q_opt_d_$index'),
            controller: draft.optionD,
            decoration: const InputDecoration(
              labelText: 'Đáp án D (tùy chọn)',
              prefixText: 'D. ',
            ),
          ),
          const SizedBox(height: 12),
          Text('Đáp án đúng:', style: AppTheme.head(size: 13, w: FontWeight.w600)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['A', 'B', 'C', 'D'].map((opt) {
              final isSelected = draft.correctAnswer == opt;
              return ChoiceChip(
                key: Key('q_${index}_ans_$opt'),
                label: Text('Đáp án $opt'),
                selected: isSelected,
                onSelected: (_) => onCorrectAnswerChanged(opt),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: Key('q_exp_$index'),
            controller: draft.explanation,
            decoration: const InputDecoration(
              labelText: 'Giải thích (tùy chọn)',
              hintText: 'Giải thích vì sao đáp án này đúng...',
              prefixIcon: Icon(Icons.info_outline),
            ),
          ),
        ],
      ),
    );
  }
}

