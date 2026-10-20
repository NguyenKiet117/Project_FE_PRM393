import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smartquiz/core/validators.dart';
import 'package:smartquiz/providers/auth_provider.dart';
import 'package:smartquiz/screens/auth_screen.dart';
import 'package:smartquiz/services/auth_service.dart';

Future<AuthProvider> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2600); // màn hình điện thoại dài
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final provider = AuthProvider(MockAuthService());
  await tester.pumpWidget(ChangeNotifierProvider.value(
    value: provider,
    child: const MaterialApp(home: AuthScreen()),
  ));
  return provider;
}

void main() {
  group('Validators', () {
    test('email sai', () => expect(Validators.email('abc'), isNotNull));
    test('email đúng', () => expect(Validators.email('a@b.com'), isNull));
    test('mật khẩu ngắn', () => expect(Validators.password('123'), isNotNull));
  });

  group('AuthScreen', () {
    testWidgets('để trống -> hiện lỗi', (tester) async {
      await _pump(tester);
      await tester.tap(find.byKey(const Key('auth_submit')));
      await tester.pump();
      expect(find.text('Vui lòng nhập email'), findsOneWidget);
      expect(find.text('Vui lòng nhập mật khẩu'), findsOneWidget);
    });

    testWidgets('chuyển tab Tạo tài khoản -> hiện ô Họ tên', (tester) async {
      await _pump(tester);
      expect(find.byKey(const Key('auth_name')), findsNothing);
      await tester.tap(find.byKey(const Key('tab_signup')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('auth_name')), findsOneWidget);
    });

    testWidgets('sai mật khẩu -> SnackBar', (tester) async {
      await _pump(tester);
      await tester.enterText(find.byKey(const Key('auth_email')), 'test@quiz.com');
      await tester.enterText(find.byKey(const Key('auth_password')), 'wrongpass');
      await tester.tap(find.byKey(const Key('auth_submit')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Email hoặc mật khẩu không đúng'), findsOneWidget);
    });

    testWidgets('đăng ký thành công -> provider có user', (tester) async {
      final p = await _pump(tester);
      await tester.tap(find.byKey(const Key('tab_signup')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('auth_name')), 'Nguyen Van A');
      await tester.enterText(find.byKey(const Key('auth_email')), 'a@b.com');
      await tester.enterText(find.byKey(const Key('auth_password')), '123456');
      await tester.tap(find.byKey(const Key('auth_submit')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(p.user?.name, 'Nguyen Van A');
    });
  });
}
