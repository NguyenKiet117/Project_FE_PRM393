import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../engine/quiz_session.dart';
import '../models/question.dart';
import '../models/quiz_set.dart';
import '../providers/auth_provider.dart';
import '../providers/library_provider.dart';
import '../providers/quiz_provider.dart';
import '../widgets/common.dart';
import 'result_screen.dart';

/// Bắt đầu 1 lượt làm bài (dùng chung cho Home & Detail).
/// Danh sách từ server chưa có câu hỏi -> tải chi tiết trước khi vào làm bài.
Future<void> startQuiz(BuildContext context, QuizSet quiz, {bool shuffle = false}) async {
  final lib = context.read<LibraryProvider>();
  final qp = context.read<QuizProvider>();
  final nav = Navigator.of(context);
  final messenger = ScaffoldMessenger.of(context);

  final needFetch = !quiz.hasQuestions;
  if (needFetch) {
    unawaited(showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(child: CircularProgressIndicator()),
      ),
    ));
  }
  QuizSet full;
  try {
    full = await lib.loadFull(quiz);
  } catch (e) {
    if (needFetch) nav.pop();
    messenger.showSnackBar(SnackBar(
        content: Text(e is Exception ? e.toString() : 'Không tải được bộ đề')));
    return;
  }
  if (needFetch) nav.pop();
  if (!full.hasQuestions) {
    messenger.showSnackBar(const SnackBar(content: Text('Bộ đề này chưa có câu hỏi')));
    return;
  }
  qp.start(full, shuffleQuestions: shuffle, shuffleOptions: shuffle);
  unawaited(nav.push(MaterialPageRoute(builder: (_) => const QuizScreen())));
}

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});
  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  bool _navigated = false;

  void _goResult() {
    if (_navigated || !mounted) return;
    _navigated = true;
    final qp = context.read<QuizProvider>();
    final s = qp.session!;
    final result = s.finish();
    final lib = context.read<LibraryProvider>();
    final auth = context.read<AuthProvider>();
    lib.recordResult(s.quiz.id, result);
    final userId = auth.user?.id;
    if (userId != null) {
      // Gửi lên server (lưu lịch sử, tăng streak) mà không chặn việc xem kết quả.
      unawaited(lib.syncResult(s.quiz.id, userId, result).then((ack) {
        final streak = ack?.updatedStreak;
        if (streak != null) auth.updateStreak(streak);
      }));
    }
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (_) => const ResultScreen()));
  }

  Future<void> _submit() async {
    final qp = context.read<QuizProvider>();
    final left = qp.session!.unansweredCount;
    if (left > 0) {
      final ok = await _confirm('Nộp bài?', 'Bạn còn $left câu chưa trả lời.', 'Nộp bài');
      if (!ok) return;
    }
    qp.submit();
    _goResult();
  }

  Future<void> _exit() async {
    final ok = await _confirm('Thoát bài làm?', 'Kết quả lần làm này sẽ không được lưu.', 'Thoát');
    if (!ok || !mounted) return;
    context.read<QuizProvider>().exit();
    Navigator.of(context).pop();
  }

  Future<bool> _confirm(String title, String msg, String action) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(msg),
        actions: [
          TextButton(
              key: const Key('dialog_cancel'),
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Tiếp tục làm')),
          FilledButton(
              key: const Key('dialog_ok'),
              style: FilledButton.styleFrom(minimumSize: const Size(90, 40)),
              onPressed: () => Navigator.pop(context, true),
              child: Text(action)),
        ],
      ),
    );
    return r == true;
  }

  @override
  Widget build(BuildContext context) {
    final qp = context.watch<QuizProvider>();
    final s = qp.session;
    if (s == null) return const Scaffold();
    if (s.isFinished) {
      // Hết giờ (hoặc đã nộp) -> sang màn Kết quả.
      WidgetsBinding.instance.addPostFrameCallback((_) => _goResult());
    }
    final cs = Theme.of(context).colorScheme;
    final q = s.current;

    return PopScope(
      canPop: s.isFinished,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _exit();
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(children: [
            _Header(session: s, onClose: _exit),
            Expanded(
              child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 16), children: [
                _QuestionCard(
                  question: q,
                  bookmarked: s.isBookmarked(s.currentIndex),
                  onBookmark: qp.toggleBookmark,
                ),
                const SizedBox(height: 16),
                for (var i = 0; i < q.options.length; i++) ...[
                  _OptionTile(
                    key: Key('option_$i'),
                    letter: Question.letter(i),
                    text: q.options[i],
                    selected: s.selected == i,
                    onTap: () => qp.select(i),
                  ),
                  const SizedBox(height: 10),
                ],
              ]),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              color: AppTheme.card(cs),
              child: Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('btn_prev'),
                    onPressed: s.isFirst ? null : qp.previous,
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: const Text('Trước'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    key: Key(s.isLast ? 'btn_submit' : 'btn_next'),
                    onPressed: s.isLast ? _submit : qp.next,
                    icon: Icon(s.isLast ? Icons.check : Icons.arrow_forward, size: 18),
                    label: Text(s.isLast ? 'Nộp bài' : 'Câu tiếp'),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final QuizSession session;
  final VoidCallback onClose;
  const _Header({required this.session, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = session;
    final t = s.remaining ?? s.elapsed;
    final low = s.remaining != null && s.remaining! < const Duration(seconds: 60);
    final timerColor = low ? cs.error : cs.primary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(children: [
        Row(children: [
          IconButton.filledTonal(
              key: const Key('btn_close'), onPressed: onClose, icon: const Icon(Icons.close)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('BÀI KIỂM TRA',
                  style: AppTheme.head(size: 11, color: cs.onSurfaceVariant)),
              Text(s.quiz.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.head(size: 17)),
            ]),
          ),
          Container(
            key: const Key('timer_chip'),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
                color: timerColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(20)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.timer_outlined, size: 18, color: timerColor),
              const SizedBox(width: 6),
              Text(formatDuration(t),
                  style: TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      color: timerColor)),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Text('Câu ${s.currentIndex + 1}',
              key: const Key('question_counter'),
              style: AppTheme.head(size: 15, color: cs.primary)),
          Text(' / ${s.length}', style: TextStyle(color: cs.onSurfaceVariant)),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: s.current.category != null
                  ? Pill(s.current.category!, color: cs.secondary)
                  : const SizedBox.shrink(),
            ),
          ),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(value: s.progress, minHeight: 8),
        ),
      ]),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final Question question;
  final bool bookmarked;
  final VoidCallback onBookmark;
  const _QuestionCard(
      {required this.question, required this.bookmarked, required this.onBookmark});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Pill('Một đáp án • ${question.points} điểm', color: cs.primary),
            ),
          ),
          IconButton(
            key: const Key('btn_bookmark'),
            visualDensity: VisualDensity.compact,
            icon: Icon(bookmarked ? Icons.bookmark : Icons.bookmark_border,
                color: bookmarked ? cs.primary : cs.outline),
            onPressed: onBookmark,
          ),
        ]),
        const SizedBox(height: 8),
        Text(question.text,
            key: const Key('question_text'),
            style: AppTheme.head(size: 20, w: FontWeight.w700).copyWith(height: 1.35)),
        if (question.hint != null) ...[
          const SizedBox(height: 12),
          Row(children: [
            Icon(Icons.lightbulb_outline, size: 18, color: cs.tertiary),
            const SizedBox(width: 8),
            Expanded(
                child: Text(question.hint!,
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13))),
          ]),
        ],
      ]),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String letter, text;
  final bool selected;
  final VoidCallback onTap;
  const _OptionTile(
      {super.key,
      required this.letter,
      required this.text,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: selected ? cs.primary.withValues(alpha: 0.14) : AppTheme.card(cs),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? cs.primary : cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(letter,
                  style: AppTheme.head(
                      size: 16, color: selected ? cs.onPrimary : cs.onSurfaceVariant)),
            ),
            const SizedBox(width: 14),
            Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
            Icon(selected ? Icons.check_circle : Icons.circle_outlined,
                color: selected ? cs.primary : cs.outlineVariant),
          ]),
        ),
      ),
    );
  }
}
