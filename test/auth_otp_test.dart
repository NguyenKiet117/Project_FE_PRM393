import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smartquiz/providers/auth_provider.dart';
import 'package:smartquiz/screens/auth_screen.dart';
import 'package:smartquiz/services/auth_service.dart';

class _OtpService extends MockAuthService {
  final sent = <String>[];
  String? usedOtp;
  String? usedConfirm;

  @override
  bool get requiresOtp => true;

  @override
  Future<void> sendOtp({required String email}) async => sent.add(email);

  @override
  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
    String otp = '',
    String confirmPassword = '',
  }) {
    usedOtp = otp;
    usedConfirm = confirmPassword;
    return super.register(
        name: name,
        email: email,
        password: password,
        otp: otp,
        confirmPassword: confirmPassword);
  }
}

Future<void> _open(WidgetTester t, _OtpService svc) async {
  t.view.physicalSize = const Size(1080, 3600);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  await t.pumpWidget(ChangeNotifierProvider(
    create: (_) => AuthProvider(svc),
    child: const MaterialApp(home: AuthScreen()),
  ));
  await t.tap(find.byKey(const Key('tab_signup')));
  await t.pumpAndSettle();
}

void main() {
  testWidgets('đăng ký có OTP: hiện ô mã OTP', (t) async {
    await _open(t, _OtpService());
    expect(find.byKey(const Key('auth_otp')), findsOneWidget);
    expect(find.byKey(const Key('auth_send_otp')), findsOneWidget);
  });

  testWidgets('bấm Gửi mã khi chưa nhập email -> báo lỗi, không gọi server', (t) async {
    final svc = _OtpService();
    await _open(t, svc);
    await t.tap(find.byKey(const Key('auth_send_otp')));
    await t.pump();
    expect(find.text('Vui lòng nhập email'), findsWidgets);
    expect(svc.sent, isEmpty);
  });

  testWidgets('nhập email rồi Gửi mã -> gọi sendOtp', (t) async {
    final svc = _OtpService();
    await _open(t, svc);
    await t.enterText(find.byKey(const Key('auth_email')), 'a@b.com');
    await t.tap(find.byKey(const Key('auth_send_otp')));
    await t.pump();
    await t.pump(const Duration(milliseconds: 50));
    expect(svc.sent, ['a@b.com']);
  });

  testWidgets('đăng ký truyền đúng OTP', (t) async {
    final svc = _OtpService();
    await _open(t, svc);
    await t.enterText(find.byKey(const Key('auth_name')), 'Nguyen Van A');
    await t.enterText(find.byKey(const Key('auth_email')), 'a@b.com');
    await t.enterText(find.byKey(const Key('auth_password')), '123456');
    await t.enterText(find.byKey(const Key('auth_confirm')), '123456');
    await t.enterText(find.byKey(const Key('auth_otp')), '654321');
    await t.tap(find.byKey(const Key('auth_submit')));
    await t.pump();
    await t.pump(const Duration(seconds: 1));
    expect(svc.usedOtp, '654321');
    expect(svc.usedConfirm, '123456');
  });

  testWidgets('OTP thiếu số -> báo lỗi', (t) async {
    final svc = _OtpService();
    await _open(t, svc);
    await t.enterText(find.byKey(const Key('auth_name')), 'Nguyen Van A');
    await t.enterText(find.byKey(const Key('auth_email')), 'a@b.com');
    await t.enterText(find.byKey(const Key('auth_password')), '123456');
    await t.enterText(find.byKey(const Key('auth_confirm')), '123456');
    await t.enterText(find.byKey(const Key('auth_otp')), '123');
    await t.tap(find.byKey(const Key('auth_submit')));
    await t.pump();
    expect(find.text('Nhập đủ 6 chữ số'), findsOneWidget);
    expect(svc.usedOtp, isNull);
  });
}
