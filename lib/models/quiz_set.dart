import 'question.dart';

/// Một bộ đề. API danh sách chỉ trả metadata (questions rỗng + totalQuestions);
/// câu hỏi được tải khi bắt đầu làm bài (GET /api/quizzes/{id}).
class QuizSet {
  final String id;
  final String title;
  final String description;
  final String category;
  final Duration? timeLimit; // null = không giới hạn
  final List<Question> questions;
  final bool isFavorite;
  final int? totalQuestions;
  final String? difficulty;
  final double? avgScore;

  const QuizSet({
    required this.id,
    required this.title,
    required this.questions,
    this.description = '',
    this.category = 'General',
    this.timeLimit,
    this.isFavorite = false,
    this.totalQuestions,
    this.difficulty,
    this.avgScore,
  });

  bool get hasQuestions => questions.isNotEmpty;
  int get length => hasQuestions ? questions.length : (totalQuestions ?? 0);
  int get totalPoints =>
      hasQuestions ? questions.fold(0, (s, q) => s + q.points) : length * 10;

  QuizSet copyWith({bool? isFavorite, List<Question>? questions}) => QuizSet(
        id: id,
        title: title,
        description: description,
        category: category,
        timeLimit: timeLimit,
        questions: questions ?? this.questions,
        isFavorite: isFavorite ?? this.isFavorite,
        totalQuestions: totalQuestions,
        difficulty: difficulty,
        avgScore: avgScore,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'category': category,
        'timeLimitSeconds': timeLimit?.inSeconds,
        'isFavorite': isFavorite,
        'totalQuestions': totalQuestions,
        'difficulty': difficulty,
        'avgScore': avgScore,
        'questions': [for (final q in questions) q.toMap()],
      };

  factory QuizSet.fromMap(Map<String, dynamic> m) => QuizSet(
        id: m['id'] as String,
        title: m['title'] as String,
        description: (m['description'] as String?) ?? '',
        category: (m['category'] as String?) ?? 'General',
        timeLimit: m['timeLimitSeconds'] == null
            ? null
            : Duration(seconds: (m['timeLimitSeconds'] as num).toInt()),
        isFavorite: (m['isFavorite'] as bool?) ?? false,
        totalQuestions: (m['totalQuestions'] as num?)?.toInt(),
        difficulty: m['difficulty'] as String?,
        avgScore: (m['avgScore'] as num?)?.toDouble(),
        questions: [
          for (final q in (m['questions'] as List))
            Question.fromMap(Map<String, dynamic>.from(q as Map))
        ],
      );
}
