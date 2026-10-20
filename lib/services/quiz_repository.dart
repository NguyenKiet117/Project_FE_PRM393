import '../data/dto_mappers.dart';
import '../data/sample_quizzes.dart';
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
  Future<List<QuizSet>> fetchQuizzes();
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
  });

  /// Xóa bộ đề (xóa trên server, ảnh hưởng mọi người dùng).
  Future<void> deleteQuiz(String id);
}

/// Dữ liệu giả: chạy offline / dùng trong test.
class FakeQuizRepository implements QuizRepository {
  @override
  Future<List<QuizSet>> fetchQuizzes() async => sampleQuizzes();

  @override
  Future<QuizSet> fetchQuiz(String id) async =>
      sampleQuizzes().firstWhere((q) => q.id == id);

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
  }) async =>
      throw const ApiException('Chế độ offline không hỗ trợ import file.');

  @override
  Future<void> deleteQuiz(String id) async {}
}

/// Gọi backend Spring Boot.
class RemoteQuizRepository implements QuizRepository {
  RemoteQuizRepository(this._api);
  final ApiClient _api;

  @override
  Future<List<QuizSet>> fetchQuizzes() async {
    final data = await _api.get('/api/quizzes') as List? ?? const [];
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
  }) async {
    final data = await _api.postMultipart(
      '/api/quizzes/import',
      fileField: 'file',
      bytes: bytes,
      filename: filename,
      fields: {
        if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
        if (category != null && category.trim().isNotEmpty) 'category': category.trim(),
      },
    );
    return quizSetFromDto(Map<String, dynamic>.from(data as Map));
  }

  @override
  Future<void> deleteQuiz(String id) async {
    await _api.delete('/api/quizzes/$id');
  }
}
