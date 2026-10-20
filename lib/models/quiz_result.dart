import 'question.dart';

/// Kết quả của 1 câu (dòng trong "Question Breakdown").
class QuestionResult {
  final Question question;
  final int? selectedIndex; // null = bỏ qua

  const QuestionResult({required this.question, required this.selectedIndex});

  bool get isSkipped => selectedIndex == null;
  bool get isCorrect => question.isCorrect(selectedIndex);
  int get pointsEarned => isCorrect ? question.points : 0;
}

/// Kết quả cả bài (màn hình Quiz Results).
class QuizResult {
  final String quizTitle;
  final List<QuestionResult> items;
  final Duration elapsed;
  final bool timedOut;

  /// Điểm đạt (%) để tính "Passed".
  static const passPercent = 60.0;

  const QuizResult({
    required this.quizTitle,
    required this.items,
    required this.elapsed,
    this.timedOut = false,
  });

  int get total => items.length;
  int get correct => items.where((i) => i.isCorrect).length;
  int get skipped => items.where((i) => i.isSkipped).length;
  int get wrong => total - correct - skipped;
  int get earnedPoints => items.fold(0, (s, i) => s + i.pointsEarned);
  int get totalPoints => items.fold(0, (s, i) => s + i.question.points);

  double get percent => total == 0 ? 0 : correct * 100 / total;
  bool get passed => percent >= passPercent;

  /// "49s/q" trong Stitch.
  int get secondsPerQuestion => total == 0 ? 0 : (elapsed.inSeconds / total).round();

  List<QuestionResult> get wrongItems => items.where((i) => !i.isCorrect).toList();

  /// Body gửi lên POST /api/quizzes/{id}/submit: {questionId: "A".."D"}.
  /// Câu bỏ qua thì không gửi. Dùng chữ cái GỐC của server (kể cả khi đã trộn đáp án).
  Map<String, String> toSubmissionAnswers() => {
        for (final i in items)
          if (i.selectedIndex != null)
            i.question.id: i.question.originalLetter(i.selectedIndex!)
      };
}
