import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../models/quiz_set.dart';
import '../providers/library_provider.dart';
import '../widgets/common.dart';
import 'main_shell.dart';
import 'quiz_detail_screen.dart';
import 'quiz_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});
  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  bool _history = false;
  String _q = '';

  Future<void> _confirmDelete(QuizSet quiz) async {
    final lib = context.read<LibraryProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa bộ đề?'),
        content: Text('"${quiz.title}" sẽ bị xóa khỏi máy chủ, mọi người dùng khác cũng không còn thấy bộ đề này.'),
        actions: [
          TextButton(
              key: const Key('delete_cancel'),
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy')),
          FilledButton(
              key: const Key('delete_confirm'),
              style: FilledButton.styleFrom(
                  minimumSize: const Size(90, 40),
                  backgroundColor: Theme.of(context).colorScheme.error),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Xóa')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await lib.deleteQuiz(quiz.id);
      messenger.showSnackBar(const SnackBar(content: Text('Đã xóa bộ đề')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Không xóa được: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final lib = context.watch<LibraryProvider>();
    final saved = lib.favorites;
    final hist = lib.history;
    final q = _q.trim().toLowerCase();
    final items = [
      for (final e in (_history ? hist : saved))
        if (q.isEmpty || e.title.toLowerCase().contains(q) || e.category.toLowerCase().contains(q)) e
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        Text('Thư viện của tôi', style: AppTheme.head(size: 22, w: FontWeight.w800)),
        const SizedBox(height: 4),
        Text('Bộ đề đã lưu và lịch sử luyện tập',
            style: TextStyle(color: cs.onSurfaceVariant)),
        const SizedBox(height: 16),
        SegmentedButton<bool>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(
                value: false,
                icon: const Icon(Icons.bookmark_border),
                label: Text('Đã lưu (${saved.length})', key: const Key('seg_saved'))),
            ButtonSegment(
                value: true,
                icon: const Icon(Icons.history),
                label: Text('Lịch sử (${hist.length})', key: const Key('seg_history'))),
          ],
          selected: {_history},
          onSelectionChanged: (s) => setState(() => _history = s.first),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('library_search'),
          onChanged: (v) => setState(() => _q = v),
          decoration: const InputDecoration(
              hintText: 'Tìm trong thư viện...', prefixIcon: Icon(Icons.search)),
        ),
        const SizedBox(height: 16),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.all(28),
            child: Center(
              child: Text(
                _history
                    ? 'Bạn chưa làm bộ đề nào.'
                    : 'Chưa có bộ đề nào được lưu.\nMở một bộ đề và bấm biểu tượng đánh dấu để lưu.',
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            ),
          ),
        for (final quiz in items) ...[
          _LibraryCard(
            quiz: quiz,
            onDelete: () => _confirmDelete(quiz),
          ),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 8),
        AppCard(
          color: cs.primary.withValues(alpha: 0.08),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Muốn thêm bộ đề?', style: AppTheme.head(size: 16)),
            const SizedBox(height: 4),
            Text('Import từ file Excel hoặc chọn một bộ có sẵn ở Trang chủ.',
                style: TextStyle(color: cs.onSurfaceVariant)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  key: const Key('lib_go_import'),
                  onPressed: () => MainShellState.of(context)?.goTo(2),
                  child: const Text('Import Excel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  key: const Key('lib_go_home'),
                  onPressed: () => MainShellState.of(context)?.goTo(0),
                  child: const Text('Xem bộ đề'),
                ),
              ),
            ]),
          ]),
        ),
      ],
    );
  }
}

class _LibraryCard extends StatelessWidget {
  final QuizSet quiz;
  final VoidCallback onDelete;
  const _LibraryCard({required this.quiz, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final lib = context.watch<LibraryProvider>();
    final last = lib.lastPracticed(quiz.id);
    final best = lib.bestCorrect(quiz.id);
    final pct = quiz.length == 0 ? 0 : (best * 100 / quiz.length).round();

    return AppCard(
      key: Key('lib_card_${quiz.id}'),
      onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => QuizDetailScreen(quizId: quiz.id))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Pill(quiz.category, color: cs.secondary),
            ),
          ),
          IconButton(
            key: Key('delete_${quiz.id}'),
            tooltip: 'Xóa bộ đề',
            icon: const Icon(Icons.delete_outline),
            onPressed: onDelete,
          ),
        ]),
        Text(quiz.title, style: AppTheme.head(size: 17)),
        if (quiz.description.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(quiz.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
        ],
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: Wrap(spacing: 14, runSpacing: 4, children: [
              Text('${quiz.length} câu', style: Theme.of(context).textTheme.bodySmall),
              Text(last == null ? 'Chưa làm' : 'Luyện ${timeAgo(last)}',
                  style: Theme.of(context).textTheme.bodySmall),
              if (last != null)
                Text('Tốt nhất $pct%',
                    style: AppTheme.head(size: 12, color: cs.primary)),
            ]),
          ),
          IconButton.filled(
            key: Key('play_${quiz.id}'),
            tooltip: 'Làm bài',
            icon: const Icon(Icons.play_arrow),
            onPressed: () => startQuiz(context, quiz),
          ),
        ]),
      ]),
    );
  }
}
