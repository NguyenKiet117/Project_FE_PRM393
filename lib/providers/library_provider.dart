import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/quiz_result.dart';
import '../models/quiz_set.dart';
import '../services/api_client.dart';
import '../services/file_picker_service.dart';
import '../services/quiz_repository.dart';

enum LoadState { idle, loading, loaded, error }

/// Danh sách bộ đề (từ server) + tiến độ cục bộ cho Trang chủ.
/// Tiến độ (best/last) hiện giữ trong RAM vì backend chưa có API lịch sử theo user.
class LibraryProvider extends ChangeNotifier {
  LibraryProvider({required QuizRepository repository, List<QuizSet>? initial})
      : _repo = repository,
        _quizzes = List<QuizSet>.of(initial ?? const <QuizSet>[]),
        state = initial == null ? LoadState.idle : LoadState.loaded;

  final QuizRepository _repo;
  final List<QuizSet> _quizzes;
  final Map<String, int> _best = {};
  final Map<String, DateTime> _last = {};

  LoadState state;
  String? error;
  String? syncError;
  String query = '';
  bool recentOnly = true;

  int get totalQuizzes => _quizzes.length;
  int get totalSolved => _best.values.fold(0, (a, b) => a + b);
  int bestCorrect(String id) => _best[id] ?? 0;
  DateTime? lastPracticed(String id) => _last[id];
  double progress(QuizSet q) => q.length == 0 ? 0 : bestCorrect(q.id) / q.length;

  Future<void> load() async {
    state = LoadState.loading;
    error = null;
    notifyListeners();
    try {
      final list = await _repo.fetchQuizzes();
      final fav = {for (final q in _quizzes) if (q.isFavorite) q.id};
      _quizzes
        ..clear()
        ..addAll([for (final q in list) fav.contains(q.id) ? q.copyWith(isFavorite: true) : q]);
      state = LoadState.loaded;
    } catch (e) {
      error = e is ApiException ? e.message : 'Không tải được danh sách bộ đề';
      state = LoadState.error;
    }
    notifyListeners();
  }

  /// Tải đủ câu hỏi (GET /api/quizzes/{id}) nếu bộ đề mới có metadata.
  Future<QuizSet> loadFull(QuizSet q) async {
    if (q.hasQuestions) return q;
    final full = await _repo.fetchQuiz(q.id);
    final i = _quizzes.indexWhere((e) => e.id == q.id);
    final merged = full.copyWith(isFavorite: i >= 0 ? _quizzes[i].isFavorite : false);
    if (i >= 0) {
      _quizzes[i] = merged;
      notifyListeners();
    }
    return merged;
  }

  /// Tab "Đã lưu" của Thư viện.
  List<QuizSet> get favorites => _quizzes.where((q) => q.isFavorite).toList();

  /// Tab "Lịch sử": bộ đã làm, mới nhất trước.
  List<QuizSet> get history {
    final list = _quizzes.where((q) => _last.containsKey(q.id)).toList();
    list.sort((a, b) => _last[b.id]!.compareTo(_last[a.id]!));
    return list;
  }

  List<QuizSet> get visible {
    final q = query.trim().toLowerCase();
    final list = _quizzes
        .where((e) =>
            q.isEmpty ||
            e.title.toLowerCase().contains(q) ||
            e.category.toLowerCase().contains(q))
        .toList();
    if (recentOnly) {
      list.sort((a, b) {
        final la = _last[a.id], lb = _last[b.id];
        if (la == null && lb == null) return 0;
        if (la == null) return 1;
        if (lb == null) return -1;
        return lb.compareTo(la);
      });
    }
    return list;
  }

  void setQuery(String v) {
    query = v;
    notifyListeners();
  }

  void setRecentOnly(bool v) {
    recentOnly = v;
    notifyListeners();
  }

  void toggleFavorite(String id) {
    final i = _quizzes.indexWhere((e) => e.id == id);
    if (i < 0) return;
    _quizzes[i] = _quizzes[i].copyWith(isFavorite: !_quizzes[i].isFavorite);
    notifyListeners();
  }

  QuizSet? byId(String id) {
    final i = _quizzes.indexWhere((e) => e.id == id);
    return i < 0 ? null : _quizzes[i];
  }

  void recordResult(String quizId, QuizResult r, {DateTime? now}) {
    _best[quizId] = max(_best[quizId] ?? 0, r.correct);
    _last[quizId] = now ?? DateTime.now();
    notifyListeners();
  }

  /// Gửi bài làm lên server (server lưu lịch sử, tăng streak, tạo thông báo).
  /// Thất bại thì chỉ báo nhẹ, không chặn người dùng xem kết quả.
  Future<SubmissionAck?> syncResult(String quizId, String userId, QuizResult r) async {
    try {
      syncError = null;
      return await _repo.submit(
          quizId: quizId, userId: userId, answers: r.toSubmissionAnswers());
    } catch (_) {
      syncError = 'Chưa đồng bộ được kết quả lên máy chủ';
      notifyListeners();
      return null;
    }
  }

  /// Tạo bộ đề mới từ file Excel/CSV (server phân tích).
  Future<QuizSet> importQuiz(PickedFile file, {String? title, String? category}) async {
    final created = await _repo.importQuiz(
        bytes: file.bytes, filename: file.name, title: title, category: category);
    _quizzes.insert(0, created);
    notifyListeners();
    return created;
  }

  Future<void> deleteQuiz(String id) async {
    await _repo.deleteQuiz(id);
    _quizzes.removeWhere((q) => q.id == id);
    _best.remove(id);
    _last.remove(id);
    notifyListeners();
  }

  void clearProgress() {
    _best.clear();
    _last.clear();
    syncError = null;
    notifyListeners();
  }
}
