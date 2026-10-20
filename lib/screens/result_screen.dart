import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../models/question.dart';
import '../models/quiz_result.dart';
import '../providers/library_provider.dart';
import '../providers/quiz_provider.dart';
import '../widgets/common.dart';
import 'quiz_screen.dart';

/// Đã bỏ thẻ "Streak/XP" của Stitch vì app chưa có tính năng này.
class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final qp = context.read<QuizProvider>();
    final syncError = context.watch<LibraryProvider>().syncError;
    final session = qp.session;
    final r = session?.result;
    if (session == null || r == null) return const Scaffold(body: Center(child: Text('Chưa có kết quả')));

    final good = r.passed ? cs.tertiary : cs.error;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Kết quả'),
        actions: [
          IconButton(
            key: const Key('result_close'),
            icon: const Icon(Icons.close),
            onPressed: () => _home(context),
          ),
        ],
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        AppCard(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            Pill(r.quizTitle, color: cs.secondary),
            const SizedBox(height: 16),
            Icon(r.passed ? Icons.emoji_events : Icons.menu_book, size: 56, color: good),
            const SizedBox(height: 8),
            Pill(
              '${r.percent.round()}% • ${r.passed ? 'Làm tốt lắm, bạn đã đạt!' : 'Cố gắng thêm nhé!'}',
              icon: r.passed ? Icons.check_circle : Icons.info_outline,
              color: good,
            ),
            const SizedBox(height: 12),
            KeyedSubtree(
              key: const Key('score_correct'),
              child: Text.rich(
                TextSpan(children: [
                  TextSpan(
                      text: '${r.correct}',
                      style: AppTheme.head(size: 56, w: FontWeight.w800)),
                  TextSpan(
                      text: '/${r.total}',
                      style: AppTheme.head(size: 24, color: cs.onSurfaceVariant)),
                ]),
              ),
            ),
            Text(r.timedOut ? 'câu đúng • đã hết giờ' : 'câu đúng',
                style: TextStyle(color: cs.onSurfaceVariant)),
            const SizedBox(height: 16),
            Row(children: [
              _Metric(Icons.timer_outlined, 'THỜI GIAN', formatDuration(r.elapsed)),
              const SizedBox(width: 8),
              _Metric(Icons.track_changes, 'CHÍNH XÁC', '${r.percent.round()}%'),
              const SizedBox(width: 8),
              _Metric(Icons.speed, 'TỐC ĐỘ', '${r.secondsPerQuestion}s/câu'),
            ]),
            if (r.skipped > 0) ...[
              const SizedBox(height: 12),
              Text('Bỏ qua ${r.skipped} câu • Sai ${r.wrong} câu',
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
            ],
          ]),
        ),
        if (syncError != null) ...[
          const SizedBox(height: 12),
          Text(syncError, style: TextStyle(color: cs.error, fontSize: 13)),
        ],
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: Text('Chi tiết từng câu', style: AppTheme.head(size: 18))),
          Text('${r.total} câu', style: TextStyle(color: cs.onSurfaceVariant)),
        ]),
        const SizedBox(height: 12),
        for (var i = 0; i < r.items.length; i++) ...[
          _BreakdownTile(index: i + 1, item: r.items[i]),
          const SizedBox(height: 10),
        ],
      ]),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              key: const Key('btn_retry'),
              onPressed: () {
                final quiz = session.quiz;
                qp.start(quiz, shuffleQuestions: true, shuffleOptions: true);
                Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const QuizScreen()));
              },
              icon: const Icon(Icons.replay),
              label: const Text('Làm lại'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              key: const Key('btn_home'),
              onPressed: () => _home(context),
              icon: const Icon(Icons.home),
              label: const Text('Trang chủ'),
            ),
          ),
        ]),
      ),
    );
  }

  void _home(BuildContext context) {
    context.read<QuizProvider>().exit();
    Navigator.of(context).popUntil((r) => r.isFirst);
  }
}

class _Metric extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _Metric(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
            color: cs.surfaceContainerLow, borderRadius: BorderRadius.circular(16)),
        child: Column(children: [
          Icon(icon, size: 18, color: cs.primary),
          const SizedBox(height: 4),
          Text(label, style: AppTheme.head(size: 10, color: cs.onSurfaceVariant)),
          Text(value, style: AppTheme.head(size: 15, w: FontWeight.w800)),
        ]),
      ),
    );
  }
}

class _BreakdownTile extends StatelessWidget {
  final int index;
  final QuestionResult item;
  const _BreakdownTile({required this.index, required this.item});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ok = item.isCorrect;
    final q = item.question;
    final color = ok ? cs.tertiary : cs.error;

    return AppCard(
      key: Key('breakdown_$index'),
      color: ok ? null : cs.error.withValues(alpha: 0.10),
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          CircleAvatar(
              radius: 13,
              backgroundColor: cs.surfaceContainer,
              child: Text('$index', style: const TextStyle(fontSize: 12))),
          const SizedBox(width: 10),
          Expanded(child: Text(q.text, style: AppTheme.head(size: 14, w: FontWeight.w600))),
          const SizedBox(width: 8),
          Pill(ok ? '+${q.points} điểm' : '0 điểm',
              icon: ok ? Icons.check_circle : Icons.cancel, color: color),
        ]),
        if (!ok) ...[
          const SizedBox(height: 10),
          Text(
            item.isSkipped
                ? 'Bạn đã bỏ qua câu này'
                : 'Bạn chọn: ${Question.letter(item.selectedIndex!)}. ${q.options[item.selectedIndex!]}',
            style: TextStyle(color: cs.error, fontSize: 13),
          ),
          Text('Đáp án đúng: ${Question.letter(q.correctIndex)}. ${q.correctAnswer}',
              style: TextStyle(color: cs.tertiary, fontSize: 13, fontWeight: FontWeight.w600)),
          if (q.explanation != null) ...[
            const SizedBox(height: 6),
            Text(q.explanation!,
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
          ],
        ],
      ]),
    );
  }
}
