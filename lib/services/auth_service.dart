class AppUser {
  final String id;
  final String name;
  final String email;
  final int streak;
  final String? token;
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.streak = 0,
    this.token,
  });

  AppUser copyWith({int? streak}) => AppUser(
        id: id,
        name: name,
        email: email,
        streak: streak ?? this.streak,
        token: token,
      );
}

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
  @override
  String toString() => message;
}

/// HỢP ĐỒNG giữa UI và backend. Có 2 cách cài: Mock (offline) và Remote (REST API).
abstract class AuthService {
  /// true nếu đăng ký cần mã OTP gửi qua email (backend thật).
  bool get requiresOtp;

  Future<void> sendOtp({required String email});
  Future<AppUser> signIn({required String email, required String password});
  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
    String otp = '',
  });
  Future<void> signOut();
}

/// Bản giả lập trong bộ nhớ để chạy & demo UI khi không có mạng.
class MockAuthService implements AuthService {
  final Map<String, Map<String, String>> _db = {
    'test@quiz.com': {'name': 'Demo User', 'password': '123456'},
  };

  @override
  bool get requiresOtp => false;

  @override
  Future<void> sendOtp({required String email}) async {}

  @override
  Future<AppUser> signIn({required String email, required String password}) async {
    await Future.delayed(const Duration(milliseconds: 800));
    final key = email.trim().toLowerCase();
    final u = _db[key];
    if (u == null || u['password'] != password) {
      throw const AuthException('Email hoặc mật khẩu không đúng');
    }
    return AppUser(id: key, name: u['name']!, email: key);
  }

  @override
  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
    String otp = '',
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    final key = email.trim().toLowerCase();
    if (_db.containsKey(key)) throw const AuthException('Email đã được đăng ký');
    _db[key] = {'name': name.trim(), 'password': password};
    return AppUser(id: key, name: name.trim(), email: key);
  }

  @override
  Future<void> signOut() async {}
}
