import 'dart:math';
import '../models/question.dart';
import '../models/quiz_result.dart';
import '../models/quiz_set.dart';

/// Một lượt làm bài. THUẦN Dart (không Timer, không Flutter):
/// thời gian trôi qua do bên ngoài gọi tick() -> test được mà không cần chờ.
class QuizSession {
  final QuizSet quiz;
  final List<Question> questions; // đã (hoặc chưa) trộn
  late final List<int?> _answers;
  final Set<int> _bookmarks = {};

  int currentIndex = 0;
  Duration elapsed = Duration.zero;
  Duration? remaining; // null nếu bộ đề không giới hạn thời gian
  bool timedOut = false;
  QuizResult? result; // != null nghĩa là đã nộp bài

  QuizSession(
    this.quiz, {
    Random? random,
    bool shuffleQuestions = false,
    bool shuffleOptions = false,
  }) : questions = _prepare(quiz.questions, random ?? Random(), shuffleQuestions, shuffleOptions) {
    assert(quiz.questions.isNotEmpty, 'Bộ đề rỗng');
    assert(quiz.questions.every((q) => q.isValid), 'Có câu hỏi không hợp lệ');
    _answers = List<int?>.filled(questions.length, null);
    remaining = quiz.timeLimit;
  }

  static List<Question> _prepare(
      List<Question> src, Random rnd, bool shuffleQ, bool shuffleO) {
    var list = List<Question>.of(src);
    if (shuffleQ) list.shuffle(rnd);
    if (shuffleO) list = [for (final q in list) q.withShuffledOptions(rnd)];
    return list;
  }

  // ---------- Trạng thái ----------
  bool get isFinished => result != null;
  int get length => questions.length;
  Question get current => questions[currentIndex];
  bool get isFirst => currentIndex == 0;
  bool get isLast => currentIndex == length - 1;
  double get progress => (currentIndex + 1) / length; // thanh tiến độ
  int get answeredCount => _answers.where((a) => a != null).length;
  int get unansweredCount => length - answeredCount;

  int? selectedAt(int index) => _answers[index];
  int? get selected => _answers[currentIndex];
  bool isAnswered(int index) => _answers[index] != null;

  // ---------- Hành động ----------
  void select(int optionIndex) {
    if (isFinished) return;
    if (optionIndex < 0 || optionIndex >= current.options.length) {
      throw RangeError.index(optionIndex, current.options, 'option');
    }
    _answers[currentIndex] = optionIndex;
  }

  void goTo(int index) {
    if (isFinished) return;
    if (index < 0 || index >= length) throw RangeError.index(index, questions);
    currentIndex = index;
  }

  void next() {
    if (!isLast) goTo(currentIndex + 1);
  }

  void previous() {
    if (!isFirst) goTo(currentIndex - 1);
  }

  bool isBookmarked(int index) => _bookmarks.contains(index);
  void toggleBookmark([int? index]) {
    final i = index ?? currentIndex;
    if (!_bookmarks.remove(i)) _bookmarks.add(i);
  }

  /// Gọi mỗi giây từ Timer (provider). Hết giờ -> tự nộp bài.
  void tick([Duration step = const Duration(seconds: 1)]) {
    if (isFinished) return;
    elapsed += step;
    final r = remaining;
    if (r == null) return;
    final left = r - step;
    if (left <= Duration.zero) {
      remaining = Duration.zero;
      timedOut = true;
      finish();
    } else {
      remaining = left;
    }
  }

  /// Nộp bài & chấm điểm. Gọi nhiều lần vẫn an toàn (idempotent).
  QuizResult finish() {
    return result ??= QuizResult(
      quizTitle: quiz.title,
      elapsed: elapsed,
      timedOut: timedOut,
      items: [
        for (var i = 0; i < length; i++)
          QuestionResult(question: questions[i], selectedIndex: _answers[i])
      ],
    );
  }
}
