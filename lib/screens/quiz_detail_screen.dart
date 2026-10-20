import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/library_provider.dart';
import '../widgets/common.dart';
import 'quiz_screen.dart';

/// Chi tiết bộ đề. Đã bỏ các số liệu giả của Stitch (Prof., Avg Score, Leaderboard)
/// vì app chưa có dữ liệu thật cho chúng.
class QuizDetailScreen extends StatefulWidget {
  final String quizId;
  const QuizDetailScreen({super.key, required this.quizId});
  @override
  State<QuizDetailScreen> createState() => _QuizDetailScreenState();
}

class _QuizDetailScreenState extends State<QuizDetailScreen> {
  bool _shuffle = true;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final lib = context.watch<LibraryProvider>();
    final quiz = lib.byId(widget.quizId);
    if (quiz == null) return const Scaffold(body: Center(child: Text('Không tìm thấy bộ đề')));
    final best = lib.bestCorrect(quiz.id);

    Widget stat(IconData i, String v, String l) => Expanded(
          child: AppCard(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(i, color: cs.primary),
              const SizedBox(height: 8),
              Text(v, style: AppTheme.head(size: 20, w: FontWeight.w800)),
              Text(l, style: Theme.of(context).textTheme.bodySmall),
            ]),
          ),
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết bộ đề'),
        actions: [
          IconButton(
            key: const Key('favorite_button'),
            icon: Icon(quiz.isFavorite ? Icons.bookmark : Icons.bookmark_border),
            onPressed: () => lib.toggleFavorite(quiz.id),
          ),
        ],
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Pill(quiz.category, color: cs.secondary),
        const SizedBox(height: 12),
        Text(quiz.title, style: AppTheme.head(size: 24, w: FontWeight.w800)),
        const SizedBox(height: 16),
        Row(children: [
          stat(Icons.format_list_numbered, '${quiz.length}', 'Câu hỏi'),
          const SizedBox(width: 12),
          stat(Icons.timer_outlined,
              quiz.timeLimit == null ? '∞' : '${quiz.timeLimit!.inMinutes}', 'Phút'),
          const SizedBox(width: 12),
          stat(Icons.stars_outlined, '${quiz.totalPoints}', 'Điểm'),
        ]),
        const SizedBox(height: 12),
        AppCard(
          child: Row(children: [
            Icon(Icons.military_tech, color: cs.tertiary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                best == 0 ? 'Bạn chưa làm bộ đề này' : 'Kết quả tốt nhất: $best/${quiz.length}',
                style: AppTheme.head(size: 15, w: FontWeight.w600),
              ),
            ),
          ]),
        ),
        if (quiz.description.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Giới thiệu', style: AppTheme.head(size: 16)),
          const SizedBox(height: 6),
          Text(quiz.description, style: TextStyle(color: cs.onSurfaceVariant, height: 1.4)),
        ],
        const SizedBox(height: 8),
        SwitchListTile(
          key: const Key('shuffle_switch'),
          contentPadding: EdgeInsets.zero,
          title: const Text('Trộn thứ tự câu hỏi & đáp án'),
          value: _shuffle,
          onChanged: (v) => setState(() => _shuffle = v),
        ),
      ]),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: FilledButton.icon(
          key: const Key('detail_start'),
          onPressed: () => startQuiz(context, quiz, shuffle: _shuffle),
          icon: const Icon(Icons.play_arrow),
          label: const Text('Bắt đầu làm bài'),
        ),
      ),
    );
  }
}
