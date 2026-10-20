import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smartquiz/core/format.dart';
import 'package:smartquiz/models/question.dart';
import 'package:smartquiz/models/quiz_set.dart';
import 'package:smartquiz/providers/auth_provider.dart';
import 'package:smartquiz/providers/library_provider.dart';
import 'package:smartquiz/providers/quiz_provider.dart';
import 'package:smartquiz/screens/quiz_screen.dart';
import 'package:smartquiz/services/auth_service.dart';
import 'package:smartquiz/services/quiz_repository.dart';

QuizSet _quiz({Duration? limit}) => QuizSet(
      id: 't',
      title: 'Test Quiz',
      timeLimit: limit,
      questions: [
        for (var i = 1; i <= 3; i++)
          Question(
              id: 'q$i',
              text: 'Câu hỏi số $i?',
              options: const ['A1', 'B1', 'C1', 'D1'],
              correctIndex: 1),
      ],
    );

Future<QuizProvider> _open(WidgetTester tester, QuizSet quiz) async {
  tester.view.physicalSize = const Size(1080, 2600);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final qp = QuizProvider()..start(quiz);
  await tester.pumpWidget(MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: qp),
      ChangeNotifierProvider(
          create: (_) => LibraryProvider(repository: FakeQuizRepository(), initial: [quiz])),
      ChangeNotifierProvider(create: (_) => AuthProvider(MockAuthService())),
    ],
    child: const MaterialApp(home: QuizScreen()),
  ));
  return qp;
}

void main() {
  testWidgets('hiện câu hỏi, 4 đáp án A-D, bộ đếm câu', (tester) async {
    final qp = await _open(tester, _quiz());
    expect(find.text('Câu hỏi số 1?'), findsOneWidget);
    for (final l in ['A', 'B', 'C', 'D']) {
      expect(find.text(l), findsOneWidget);
    }
    expect(find.text('Câu 1'), findsOneWidget);
    qp.exit();
  });

  testWidgets('chọn đáp án -> lưu vào session, đi sang câu sau rồi quay lại vẫn nhớ',
      (tester) async {
    final qp = await _open(tester, _quiz());
    await tester.tap(find.byKey(const Key('option_2')));
    await tester.pump();
    expect(qp.session!.selected, 2);

    await tester.tap(find.byKey(const Key('btn_next')));
    await tester.pump();
    expect(find.text('Câu 2'), findsOneWidget);
    expect(qp.session!.selected, isNull);

    await tester.tap(find.byKey(const Key('btn_prev')));
    await tester.pump();
    expect(qp.session!.selected, 2);
    qp.exit();
  });

  testWidgets('nút Trước bị vô hiệu ở câu đầu', (tester) async {
    final qp = await _open(tester, _quiz());
    final btn = tester.widget<OutlinedButton>(find.byKey(const Key('btn_prev')));
    expect(btn.onPressed, isNull);
    qp.exit();
  });

  testWidgets('nộp bài khi còn câu trống -> hỏi xác nhận -> sang màn Kết quả',
      (tester) async {
    final qp = await _open(tester, _quiz());
    await tester.tap(find.byKey(const Key('option_1'))); // câu 1 đúng
    await tester.pump();
    qp.goTo(2);
    await tester.pump();

    await tester.tap(find.byKey(const Key('btn_submit')));
    await tester.pumpAndSettle();
    expect(find.text('Bạn còn 2 câu chưa trả lời.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('dialog_ok')));
    await tester.pumpAndSettle();
    expect(find.text('Kết quả'), findsOneWidget);
    expect(find.byKey(const Key('score_correct')), findsOneWidget);
    expect(qp.result!.correct, 1);
  });

  testWidgets('hết giờ -> tự chuyển sang màn Kết quả', (tester) async {
    final qp = await _open(tester, _quiz(limit: const Duration(seconds: 2)));
    qp.tick();
    qp.tick();
    await tester.pumpAndSettle();
    expect(find.text('Kết quả'), findsOneWidget);
    expect(qp.result!.timedOut, isTrue);
  });

  test('timeAgo', () {
    final now = DateTime(2026, 10, 16, 12);
    expect(timeAgo(now.subtract(const Duration(hours: 2)), now: now), '2 giờ trước');
    expect(timeAgo(now.subtract(const Duration(days: 1)), now: now), 'hôm qua');
    expect(timeAgo(now.subtract(const Duration(days: 4)), now: now), '4 ngày trước');
  });
}
