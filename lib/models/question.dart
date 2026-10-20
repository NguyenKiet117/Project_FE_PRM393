import 'dart:math';

/// Một câu hỏi trắc nghiệm 1 đáp án đúng (Single Choice).
/// Model THUẦN Dart: không import Flutter -> test cực nhanh.
class Question {
  final String id;
  final String text;
  final List<String> options; // 2..4 lựa chọn (A-D)
  final int correctIndex;
  final String? hint;
  final String? explanation;
  final String? category;
  final int points;

  /// optionOrder[i] = vị trí GỐC (trên server) của đáp án đang hiện ở vị trí i.
  /// null = chưa trộn. Cần để gửi đúng chữ cái A-D lên server khi đã trộn đáp án.
  final List<int>? optionOrder;

  const Question({
    required this.id,
    required this.text,
    required this.options,
    required this.correctIndex,
    this.hint,
    this.explanation,
    this.category,
    this.points = 10,
    this.optionOrder,
  });

  bool get isValid =>
      options.length >= 2 && correctIndex >= 0 && correctIndex < options.length;

  String get correctAnswer => options[correctIndex];

  /// 0 -> 'A', 1 -> 'B' ...
  static String letter(int index) => String.fromCharCode(65 + index);

  /// 'B' -> 1. null nếu không hợp lệ.
  static int? indexOfLetter(String? s) {
    final t = s?.trim().toUpperCase() ?? '';
    if (t.length != 1) return null;
    final i = t.codeUnitAt(0) - 65;
    return i >= 0 && i < 26 ? i : null;
  }

  bool isCorrect(int? selected) => selected != null && selected == correctIndex;

  /// Chữ cái đáp án theo thứ tự GỐC của server (đã tính cả khi trộn đáp án).
  String originalLetter(int selectedIndex) =>
      letter(optionOrder?[selectedIndex] ?? selectedIndex);

  /// Trộn thứ tự đáp án nhưng vẫn giữ đúng đáp án đúng.
  Question withShuffledOptions(Random random) {
    final order = List<int>.generate(options.length, (i) => i)..shuffle(random);
    return Question(
      id: id,
      text: text,
      options: [for (final i in order) options[i]],
      correctIndex: order.indexOf(correctIndex),
      hint: hint,
      explanation: explanation,
      category: category,
      points: points,
      optionOrder: [for (final i in order) optionOrder?[i] ?? i],
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'text': text,
        'options': options,
        'correctIndex': correctIndex,
        'hint': hint,
        'explanation': explanation,
        'category': category,
        'points': points,
      };

  factory Question.fromMap(Map<String, dynamic> m) => Question(
        id: m['id'] as String,
        text: m['text'] as String,
        options: List<String>.from(m['options'] as List),
        correctIndex: (m['correctIndex'] as num).toInt(),
        hint: m['hint'] as String?,
        explanation: m['explanation'] as String?,
        category: m['category'] as String?,
        points: (m['points'] as num?)?.toInt() ?? 10,
      );
}
