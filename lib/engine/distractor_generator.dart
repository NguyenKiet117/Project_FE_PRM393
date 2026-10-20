import 'dart:math';
import '../models/question.dart';

/// Dòng thô từ Excel kiểu 2 cột (Question | Correct Answer).
class RawQA {
  final String text;
  final String answer;
  final String? hint;
  final String? explanation;
  final String? category;
  const RawQA(this.text, this.answer, {this.hint, this.explanation, this.category});
}

/// Sinh đáp án nhiễu (distractor) cho file Excel chỉ có câu hỏi + đáp án đúng.
/// Ý tưởng: đáp án sai của câu này = đáp án ĐÚNG của các câu khác trong cùng bộ đề.
/// Hạn chế (nên ghi vào báo cáo): nếu các đáp án khác "loại" nhau (số vs chữ)
/// thì đáp án nhiễu dễ bị loại trừ -> khuyến khích dùng file có đủ cột B-F.
class DistractorGenerator {
  static String _key(String s) => s.trim().toLowerCase();

  static List<Question> generate(
    List<RawQA> items, {
    int optionCount = 4,
    Random? random,
  }) {
    final rnd = random ?? Random();

    // Kho đáp án duy nhất (không phân biệt hoa/thường).
    final pool = <String, String>{};
    for (final it in items) {
      pool.putIfAbsent(_key(it.answer), () => it.answer.trim());
    }
    if (pool.length < 2) {
      throw ArgumentError('Cần ít nhất 2 đáp án khác nhau để tạo lựa chọn');
    }
    final count = min(optionCount, pool.length);

    final out = <Question>[];
    for (var i = 0; i < items.length; i++) {
      final it = items[i];
      final correct = it.answer.trim();
      final key = _key(correct);
      final others = [
        for (final e in pool.entries)
          if (e.key != key) e.value
      ]..shuffle(rnd);
      final options = [...others.take(count - 1), correct]..shuffle(rnd);
      out.add(Question(
        id: 'q${i + 1}',
        text: it.text.trim(),
        options: options,
        correctIndex: options.indexOf(correct),
        hint: it.hint,
        explanation: it.explanation,
        category: it.category,
      ));
    }
    return out;
  }
}
