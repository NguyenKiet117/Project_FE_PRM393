import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../models/quiz_set.dart';
import '../providers/auth_provider.dart';
import '../providers/library_provider.dart';
import '../widgets/common.dart';
import 'quiz_detail_screen.dart';
import 'quiz_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final lib = context.watch<LibraryProvider>();
    final user = context.watch<AuthProvider>().user;
    final name = user?.name.split(' ').last ?? 'bạn';
    final quizzes = lib.visible;

    return RefreshIndicator(
      onRefresh: lib.load,
      child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        // Thẻ chào
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(colors: [cs.primary, cs.secondary]),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Xin chào, $name! 👋',
                style: AppTheme.head(size: 22, w: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 4),
            const Text('Sẵn sàng luyện đề hôm nay chưa?',
                style: TextStyle(color: Colors.white70)),
          ]),
        ),
        const SizedBox(height: 16),
        TextField(
          key: const Key('home_search'),
          onChanged: lib.setQuery,
          decoration: const InputDecoration(
              hintText: 'Tìm bộ đề, môn học...', prefixIcon: Icon(Icons.search)),
        ),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _Stat(Icons.library_books_outlined, '${lib.totalQuizzes}', 'Bộ đề', cs.primary)),
          const SizedBox(width: 12),
          Expanded(child: _Stat(Icons.local_fire_department, '${user?.streak ?? 0}', 'Chuỗi ngày', cs.tertiary)),
        ]),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: Text('Bộ đề của bạn', style: AppTheme.head(size: 18))),
          SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: true, label: Text('Gần đây', key: Key('seg_recent'))),
              ButtonSegment(value: false, label: Text('Tất cả', key: Key('seg_all'))),
            ],
            selected: {lib.recentOnly},
            onSelectionChanged: (s) => lib.setRecentOnly(s.first),
          ),
        ]),
        const SizedBox(height: 12),
        if (quizzes.isEmpty) _EmptyState(lib: lib),
        for (final q in quizzes) ...[
          _QuizCard(quiz: q),
          const SizedBox(height: 12),
        ],
      ],
    ));
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String value, label;
  final Color color;
  const _Stat(this.icon, this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) => AppCard(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: AppTheme.head(size: 18, w: FontWeight.w800)),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ]),
        ]),
      );
}

class _QuizCard extends StatelessWidget {
  final QuizSet quiz;
  const _QuizCard({required this.quiz});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final lib = context.watch<LibraryProvider>();
    final best = lib.bestCorrect(quiz.id);
    final progress = lib.progress(quiz);
    final last = lib.lastPracticed(quiz.id);
    final started = last != null;
    final mastered = progress >= 0.9;
    final label = !started ? 'Bắt đầu' : (mastered ? 'Ôn lại' : 'Luyện tập');
    final time = quiz.timeLimit == null ? 'Không giới hạn' : '${quiz.timeLimit!.inMinutes} phút';

    return AppCard(
      key: Key('quiz_card_${quiz.id}'),
      onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => QuizDetailScreen(quizId: quiz.id))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: 8, runSpacing: 6, children: [
          Pill(quiz.category, color: cs.secondary),
          Pill(time, icon: Icons.schedule, color: cs.outline),
        ]),
        const SizedBox(height: 10),
        Text(quiz.title, style: AppTheme.head(size: 17)),
        Text('${quiz.length} câu hỏi',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
        const SizedBox(height: 12),
        Row(children: [
          Text('Tiến độ', style: Theme.of(context).textTheme.bodySmall),
          const Spacer(),
          Text('${(progress * 100).round()}% ($best/${quiz.length})',
              style: AppTheme.head(size: 12, color: cs.primary)),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(value: progress, minHeight: 8),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: Text(last != null ? 'Luyện gần nhất: ${timeAgo(last)}' : 'Chưa làm lần nào',
                style: Theme.of(context).textTheme.bodySmall),
          ),
          FilledButton.icon(
            key: Key('start_${quiz.id}'),
            style: FilledButton.styleFrom(minimumSize: const Size(110, 42)),
            onPressed: () => startQuiz(context, quiz),
            icon: Icon(mastered ? Icons.replay : Icons.play_arrow, size: 18),
            label: Text(label),
          ),
        ]),
      ]),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final LibraryProvider lib;
  const _EmptyState({required this.lib});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (lib.state == LoadState.loading || lib.state == LoadState.idle) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Column(children: [
          CircularProgressIndicator(),
          SizedBox(height: 12),
          Text('Đang tải bộ đề...\n(lần đầu máy chủ có thể mất khoảng 1 phút để khởi động)',
              textAlign: TextAlign.center),
        ]),
      );
    }
    if (lib.state == LoadState.error) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          Icon(Icons.cloud_off, size: 40, color: cs.error),
          const SizedBox(height: 8),
          Text(lib.error ?? 'Không tải được dữ liệu', textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const Key('retry_load'),
            style: FilledButton.styleFrom(minimumSize: const Size(160, 44)),
            onPressed: lib.load,
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
          ),
        ]),
      );
    }
    return const Padding(
      padding: EdgeInsets.all(32),
      child: Center(child: Text('Không tìm thấy bộ đề nào')),
    );
  }
}
