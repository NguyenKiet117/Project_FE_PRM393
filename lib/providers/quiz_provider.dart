import 'dart:async';
import 'package:flutter/foundation.dart';
import '../engine/quiz_session.dart';
import '../models/quiz_result.dart';
import '../models/quiz_set.dart';

/// Cầu nối giữa QuizSession (logic thuần) và UI: giữ Timer + notifyListeners.
class QuizProvider extends ChangeNotifier {
  QuizSession? session;
  Timer? _timer;

  bool get isActive => session != null && !session!.isFinished;
  QuizResult? get result => session?.result;

  void start(QuizSet quiz, {bool shuffleQuestions = false, bool shuffleOptions = false}) {
    _timer?.cancel();
    session = QuizSession(quiz,
        shuffleQuestions: shuffleQuestions, shuffleOptions: shuffleOptions);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => tick());
    notifyListeners();
  }

  @visibleForTesting
  void tick() {
    final s = session;
    if (s == null) return;
    s.tick();
    if (s.isFinished) _timer?.cancel(); // hết giờ -> UI chuyển sang màn Kết quả
    notifyListeners();
  }

  void select(int option) => _act((s) => s.select(option));
  void next() => _act((s) => s.next());
  void previous() => _act((s) => s.previous());
  void goTo(int i) => _act((s) => s.goTo(i));
  void toggleBookmark() => _act((s) => s.toggleBookmark());

  QuizResult? submit() {
    final r = session?.finish();
    _timer?.cancel();
    notifyListeners();
    return r;
  }

  void exit() {
    _timer?.cancel();
    session = null;
    notifyListeners();
  }

  void _act(void Function(QuizSession s) f) {
    final s = session;
    if (s == null) return;
    f(s);
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
