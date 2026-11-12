import '../data/dto_mappers.dart';
import '../data/sample_quizzes.dart';
import '../models/question.dart';
import '../models/quiz_set.dart';
import 'api_client.dart';

/// Kết quả server trả về sau khi nộp bài.
class SubmissionAck {
  final int? updatedStreak;
  final double? scorePercentage;
  const SubmissionAck({this.updatedStreak, this.scorePercentage});
}

/// Hợp đồng truy cập dữ liệu bộ đề. UI/Provider chỉ biết interface này.
abstract class QuizRepository {
  Future<List<QuizSet>> fetchQuizzes({
    String? category,
    String? difficulty,
    String? search,
  });
  Future<QuizSet> fetchQuiz(String id);
  Future<SubmissionAck?> submit({
    required String quizId,
    required String userId,
    required Map<String, String> answers,
  });

  /// Upload file Excel/CSV, server tự tạo bộ đề (POST /api/quizzes/import).
  Future<QuizSet> importQuiz({
    required List<int> bytes,
    required String filename,
    String? title,
    String? category,
    String? description,
    int? timeLimitMinutes,
    String? difficulty,
  });

  /// Tạo bộ đề thủ công qua JSON (POST /api/quizzes).
  Future<QuizSet> createQuiz({
    required String title,
    required String category,
    String description = '',
    int timeLimitMinutes = 15,
    String difficulty = 'MEDIUM',
    required List<Map<String, dynamic>> questions,
  });

  /// Xóa bộ đề (xóa trên server, ảnh hưởng mọi người dùng).
  Future<void> deleteQuiz(String id);
}

/// Dữ liệu giả: chạy offline / dùng trong test.
class FakeQuizRepository implements QuizRepository {
  final List<QuizSet> _mockList = sampleQuizzes();

  @override
  Future<List<QuizSet>> fetchQuizzes({
    String? category,
    String? difficulty,
    String? search,
  }) async =>
      _mockList;

  @override
  Future<QuizSet> fetchQuiz(String id) async =>
      _mockList.firstWhere((q) => q.id == id);

  @override
  Future<SubmissionAck?> submit({
    required String quizId,
    required String userId,
    required Map<String, String> answers,
  }) async =>
      null;

  @override
  Future<QuizSet> importQuiz({
    required List<int> bytes,
    required String filename,
    String? title,
    String? category,
    String? description,
    int? timeLimitMinutes,
    String? difficulty,
  }) async =>
      throw const ApiException('Chế độ offline không hỗ trợ import file.');

  @override
  Future<QuizSet> createQuiz({
    required String title,
    required String category,
    String description = '',
    int timeLimitMinutes = 15,
    String difficulty = 'MEDIUM',
    required List<Map<String, dynamic>> questions,
  }) async {
    final qList = <Question>[];
    for (var i = 0; i < questions.length; i++) {
      final q = questions[i];
      final opts = <String>[
        q['optionA'] as String? ?? '',
        q['optionB'] as String? ?? '',
        if (q['optionC'] != null && (q['optionC'] as String).isNotEmpty) q['optionC'] as String,
        if (q['optionD'] != null && (q['optionD'] as String).isNotEmpty) q['optionD'] as String,
      ];
      final letter = (q['correctAnswer'] as String? ?? 'A').toUpperCase();
      final correctIdx = Question.indexOfLetter(letter) ?? 0;
      qList.add(Question(
        id: 'q_${DateTime.now().millisecondsSinceEpoch}_$i',
        text: (q['questionText'] as String? ?? '').trim(),
        options: opts,
        correctIndex: correctIdx,
        explanation: q['explanation'] as String?,
        category: category,
      ));
    }
    final created = QuizSet(
      id: 'quiz_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      category: category,
      description: description,
      timeLimit: Duration(minutes: timeLimitMinutes),
      difficulty: difficulty,
      questions: qList,
      totalQuestions: qList.length,
    );
    _mockList.insert(0, created);
    return created;
  }

  @override
  Future<void> deleteQuiz(String id) async {
    _mockList.removeWhere((q) => q.id == id);
  }
}

/// Gọi backend Spring Boot.
class RemoteQuizRepository implements QuizRepository {
  RemoteQuizRepository(this._api);
  final ApiClient _api;

  @override
  Future<List<QuizSet>> fetchQuizzes({
    String? category,
    String? difficulty,
    String? search,
  }) async {
    final query = <String, String>{
      if (category != null && category.trim().isNotEmpty) 'category': category.trim(),
      if (difficulty != null && difficulty.trim().isNotEmpty) 'difficulty': difficulty.trim(),
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
    };
    final data = await _api.get('/api/quizzes', query: query.isEmpty ? null : query) as List? ?? const [];
    return [
      for (final j in data) quizSetFromDto(Map<String, dynamic>.from(j as Map))
    ];
  }

  @override
  Future<QuizSet> fetchQuiz(String id) async {
    final data = await _api.get('/api/quizzes/$id');
    return quizSetFromDto(Map<String, dynamic>.from(data as Map));
  }

  @override
  Future<SubmissionAck?> submit({
    required String quizId,
    required String userId,
    required Map<String, String> answers,
  }) async {
    final data = await _api.post('/api/quizzes/$quizId/submit',
        body: {'userId': userId, 'answers': answers});
    if (data is! Map) return null;
    return SubmissionAck(
      updatedStreak: (data['updatedStreak'] as num?)?.toInt(),
      scorePercentage: (data['scorePercentage'] as num?)?.toDouble(),
    );
  }

  @override
  Future<QuizSet> importQuiz({
    required List<int> bytes,
    required String filename,
    String? title,
    String? category,
    String? description,
    int? timeLimitMinutes,
    String? difficulty,
  }) async {
    final data = await _api.postMultipart(
      '/api/quizzes/import',
      fileField: 'file',
      bytes: bytes,
      filename: filename,
      fields: {
        if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
        if (category != null && category.trim().isNotEmpty) 'category': category.trim(),
        if (description != null && description.trim().isNotEmpty) 'description': description.trim(),
        if (timeLimitMinutes != null) 'timeLimitMinutes': timeLimitMinutes.toString(),
        if (difficulty != null && difficulty.trim().isNotEmpty) 'difficulty': difficulty.trim(),
      },
    );
    return quizSetFromDto(Map<String, dynamic>.from(data as Map));
  }

  @override
  Future<QuizSet> createQuiz({
    required String title,
    required String category,
    String description = '',
    int timeLimitMinutes = 15,
    String difficulty = 'MEDIUM',
    required List<Map<String, dynamic>> questions,
  }) async {
    final data = await _api.post('/api/quizzes', body: {
      'title': title.trim(),
      'category': category.trim(),
      'description': description.trim(),
      'timeLimitMinutes': timeLimitMinutes,
      'difficulty': difficulty,
      'questions': questions,
    });
    return quizSetFromDto(Map<String, dynamic>.from(data as Map));
  }

  @override
  Future<void> deleteQuiz(String id) async {
    await _api.delete('/api/quizzes/$id');
  }
}
