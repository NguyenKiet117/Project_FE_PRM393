import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartquiz/core/format.dart';
import 'package:smartquiz/engine/distractor_generator.dart';
import 'package:smartquiz/engine/quiz_session.dart';
import 'package:smartquiz/models/question.dart';
import 'package:smartquiz/models/quiz_set.dart';

Question _q(String id, int correct, {int points = 10}) => Question(
      id: id,
      text: 'Question $id?',
      options: const ['a', 'b', 'c', 'd'],
      correctIndex: correct,
      points: points,
    );

QuizSet _quiz({Duration? limit}) => QuizSet(
      id: 's',
      title: 'Test',
      timeLimit: limit,
      questions: [_q('1', 0), _q('2', 1), _q('3', 2), _q('4', 3)],
    );

void main() {
  group('Question', () {
    test('letter <-> index', () {
      expect(Question.letter(0), 'A');
      expect(Question.indexOfLetter(' c '), 2);
      expect(Question.indexOfLetter('AB'), isNull);
      expect(Question.indexOfLetter(null), isNull);
    });

    test('trộn đáp án vẫn giữ đáp án đúng', () {
      final q = _q('1', 2);
      for (var seed = 0; seed < 20; seed++) {
        final s = q.withShuffledOptions(Random(seed));
        expect(s.correctAnswer, q.correctAnswer);
        expect(s.options.toSet(), q.options.toSet());
      }
    });

    test('toMap/fromMap round-trip', () {
      final q = _q('1', 1);
      final back = Question.fromMap(q.toMap());
      expect(back.text, q.text);
      expect(back.correctIndex, 1);
    });
  });

  group('DistractorGenerator', () {
    final raw = const [
      RawQA('Q1', 'Dart'),
      RawQA('Q2', 'Provider'),
      RawQA('Q3', 'SQLite'),
      RawQA('Q4', 'SVG'),
      RawQA('Q5', 'dart'), // trùng Q1 (khác hoa/thường)
    ];

    test('mỗi câu có 4 lựa chọn duy nhất, chứa đáp án đúng', () {
      final qs = DistractorGenerator.generate(raw, random: Random(1));
      expect(qs.length, 5);
      for (var i = 0; i < qs.length; i++) {
        expect(qs[i].options.length, 4);
        expect(qs[i].options.toSet().length, 4);
        expect(qs[i].correctAnswer.toLowerCase(), raw[i].answer.toLowerCase());
      }
    });

    test('ít đáp án khác nhau -> giảm số lựa chọn', () {
      final qs = DistractorGenerator.generate(
          const [RawQA('a', 'X'), RawQA('b', 'Y')], random: Random(1));
      expect(qs.first.options.length, 2);
    });

    test('chỉ có 1 đáp án duy nhất -> báo lỗi', () {
      expect(() => DistractorGenerator.generate(const [RawQA('a', 'X'), RawQA('b', 'x')]),
          throwsArgumentError);
    });
  });

  group('QuizSession', () {
    test('chọn đáp án, đi tới/lui, tiến độ', () {
      final s = QuizSession(_quiz());
      expect(s.isFirst, isTrue);
      s.select(2);
      expect(s.selected, 2);
      s.next();
      expect(s.currentIndex, 1);
      expect(s.selected, isNull);
      s.previous();
      expect(s.selected, 2); // nhớ lại đáp án đã chọn
      expect(s.progress, 0.25);
      expect(s.answeredCount, 1);
      expect(s.unansweredCount, 3);
    });

    test('previous ở câu đầu / next ở câu cuối không lỗi', () {
      final s = QuizSession(_quiz());
      s.previous();
      expect(s.currentIndex, 0);
      s.goTo(3);
      s.next();
      expect(s.currentIndex, 3);
      expect(s.isLast, isTrue);
    });

    test('select sai chỉ số -> RangeError', () {
      final s = QuizSession(_quiz());
      expect(() => s.select(9), throwsRangeError);
      expect(() => s.goTo(-1), throwsRangeError);
    });

    test('chấm điểm: 2 đúng, 1 sai, 1 bỏ qua', () {
      final s = QuizSession(_quiz());
      s.select(0); // đúng (q1 đáp án 0)
      s.next();
      s.select(1); // đúng
      s.next();
      s.select(0); // sai (đáp án đúng là 2)
      final r = s.finish();
      expect(r.correct, 2);
      expect(r.wrong, 1);
      expect(r.skipped, 1);
      expect(r.percent, 50);
      expect(r.passed, isFalse);
      expect(r.earnedPoints, 20);
      expect(r.totalPoints, 40);
    });

    test('đúng hết -> 100% và passed', () {
      final s = QuizSession(_quiz());
      for (var i = 0; i < 4; i++) {
        s.select(i);
        s.next();
      }
      expect(s.finish().percent, 100);
      expect(s.result!.passed, isTrue);
    });

    test('nộp rồi thì không đổi đáp án được; finish idempotent', () {
      final s = QuizSession(_quiz());
      final r1 = s.finish();
      s.select(1);
      expect(s.selectedAt(0), isNull);
      expect(identical(s.finish(), r1), isTrue);
    });

    test('bookmark bật/tắt', () {
      final s = QuizSession(_quiz());
      s.toggleBookmark();
      expect(s.isBookmarked(0), isTrue);
      s.toggleBookmark();
      expect(s.isBookmarked(0), isFalse);
    });

    test('hết giờ tự nộp bài', () {
      final s = QuizSession(_quiz(limit: const Duration(seconds: 3)));
      s.tick();
      s.tick();
      expect(s.isFinished, isFalse);
      expect(s.remaining, const Duration(seconds: 1));
      s.tick();
      expect(s.isFinished, isTrue);
      expect(s.timedOut, isTrue);
      expect(s.result!.timedOut, isTrue);
      expect(s.remaining, Duration.zero);
    });

    test('không giới hạn thời gian thì chỉ đếm elapsed', () {
      final s = QuizSession(_quiz());
      for (var i = 0; i < 10; i++) {
        s.tick();
      }
      expect(s.isFinished, isFalse);
      expect(s.elapsed, const Duration(seconds: 10));
    });

    test('trộn câu/đáp án vẫn chấm đúng', () {
      final s = QuizSession(_quiz(),
          random: Random(7), shuffleQuestions: true, shuffleOptions: true);
      for (var i = 0; i < s.length; i++) {
        s.goTo(i);
        s.select(s.current.correctIndex); // chọn đúng theo đáp án đã trộn
      }
      expect(s.finish().correct, 4);
    });
  });

  group('Gửi đáp án lên server', () {
    test('originalLetter đúng cả khi đã trộn đáp án', () {
      final q = _q('1', 1); // đáp án đúng gốc là B
      for (var seed = 0; seed < 20; seed++) {
        final shuffled = q.withShuffledOptions(Random(seed));
        expect(shuffled.originalLetter(shuffled.correctIndex), 'B');
      }
    });

    test('trộn 2 lần vẫn truy ngược về chữ cái gốc', () {
      final q = _q('1', 2)
          .withShuffledOptions(Random(1))
          .withShuffledOptions(Random(2));
      expect(q.originalLetter(q.correctIndex), 'C');
    });

    test('toSubmissionAnswers bỏ qua câu chưa trả lời', () {
      final s = QuizSession(_quiz());
      s.select(1); // câu 1 chọn B
      s.goTo(2);
      s.select(3); // câu 3 chọn D
      expect(s.finish().toSubmissionAnswers(), {'1': 'B', '3': 'D'});
    });
  });

  test('formatDuration', () {
    expect(formatDuration(const Duration(seconds: 583)), '09:43');
    expect(formatDuration(Duration.zero), '00:00');
    expect(formatDuration(const Duration(seconds: -5)), '00:00');
  });
}
