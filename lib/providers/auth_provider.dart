import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

/// State management (Provider): UI chỉ "nghe" provider, không gọi service trực tiếp.
class AuthProvider extends ChangeNotifier {
  final AuthService _service;
  AuthProvider(this._service);

  AppUser? user;
  bool isLoading = false;
  String? error;

  bool get requiresOtp => _service.requiresOtp;

  Future<bool> sendOtp(String email) => _run(() => _service.sendOtp(email: email));

  Future<bool> signIn(String email, String password) =>
      _run(() async => user = await _service.signIn(email: email, password: password));

  Future<bool> register(String name, String email, String password, {String otp = ''}) =>
      _run(() async => user = await _service.register(
          name: name, email: email, password: password, otp: otp));

  Future<void> signOut() async {
    await _service.signOut();
    user = null;
    notifyListeners();
  }

  /// Cập nhật chuỗi ngày sau khi server chấm bài.
  void updateStreak(int streak) {
    if (user == null) return;
    user = user!.copyWith(streak: streak);
    notifyListeners();
  }

  Future<bool> _run(Future<void> Function() action) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await action();
      return true;
    } on AuthException catch (e) {
      error = e.message;
      return false;
    } catch (_) {
      error = 'Đã có lỗi xảy ra, vui lòng thử lại';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
