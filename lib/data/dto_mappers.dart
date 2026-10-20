import '../models/question.dart';
import '../models/quiz_set.dart';

String? _blankToNull(Object? v) {
  final s = (v as String?)?.trim();
  return (s == null || s.isEmpty) ? null : s;
}

/// QuestionDto của backend: optionA..D + correctAnswer ("A".."D") + correctAnswerText.
Question questionFromDto(Map<String, dynamic> j, {String? category}) {
  final options = <String>[
    for (final k in ['optionA', 'optionB', 'optionC', 'optionD'])
      if (_blankToNull(j[k]) != null) _blankToNull(j[k])!
  ];
  int? correct = Question.indexOfLetter(j['correctAnswer'] as String?);
  if (correct == null || correct >= options.length) {
    final text = _blankToNull(j['correctAnswerText'])?.toLowerCase();
    final i = options.indexWhere((o) => o.toLowerCase() == text);
    correct = i < 0 ? 0 : i;
  }
  return Question(
    id: j['id'] as String,
    text: ((j['questionText'] as String?) ?? '').trim(),
    options: options,
    correctIndex: correct,
    explanation: _blankToNull(j['explanation']),
    category: category,
  );
}

/// QuizSetDto của backend. Danh sách: questions rỗng; chi tiết: có câu hỏi.
QuizSet quizSetFromDto(Map<String, dynamic> j) {
  final category = _blankToNull(j['category']) ?? 'General';
  final questions = [
    for (final q in (j['questions'] as List? ?? const []))
      questionFromDto(Map<String, dynamic>.from(q as Map), category: category)
  ].where((q) => q.isValid).toList();
  final minutes = (j['timeLimitMinutes'] as num?)?.toInt();
  return QuizSet(
    id: j['id'] as String,
    title: (j['title'] as String?) ?? 'Untitled',
    description: _blankToNull(j['description']) ?? '',
    category: category,
    timeLimit: (minutes != null && minutes > 0) ? Duration(minutes: minutes) : null,
    questions: questions,
    totalQuestions: (j['totalQuestions'] as num?)?.toInt(),
    difficulty: _blankToNull(j['difficulty']),
    avgScore: (j['avgScore'] as num?)?.toDouble(),
  );
}
