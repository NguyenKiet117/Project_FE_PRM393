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

  AppUser copyWith({int? streak, String? name, String? email}) => AppUser(
        id: id,
        name: name ?? this.name,
        email: email ?? this.email,
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

/// HỢP ĐỒNG giữa UI và backend.
abstract class AuthService {
  Future<AppUser> signIn({required String email, required String password});
  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
    String confirmPassword = '',
  });
  Future<AppUser> fetchProfile(String userId);
  Future<void> signOut();
}

/// Bản giả lập trong bộ nhớ để chạy & demo UI khi không có mạng.
class MockAuthService implements AuthService {
  final Map<String, Map<String, dynamic>> _db = {
    'test@quiz.com': {'name': 'Demo User', 'password': '123456', 'streak': 0},
  };

  @override
  Future<AppUser> signIn({required String email, required String password}) async {
    await Future.delayed(const Duration(milliseconds: 800));
    final key = email.trim().toLowerCase();
    final u = _db[key];
    if (u == null || u['password'] != password) {
      throw const AuthException('Email hoặc mật khẩu không đúng');
    }
    return AppUser(
      id: key,
      name: u['name'] as String,
      email: key,
      streak: (u['streak'] as int?) ?? 0,
    );
  }

  @override
  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
    String confirmPassword = '',
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    final key = email.trim().toLowerCase();
    if (_db.containsKey(key)) throw const AuthException('Email đã được đăng ký');
    _db[key] = {'name': name.trim(), 'password': password, 'streak': 0};
    return AppUser(id: key, name: name.trim(), email: key);
  }

  @override
  Future<AppUser> fetchProfile(String userId) async {
    final u = _db[userId];
    if (u == null) {
      return AppUser(id: userId, name: 'User', email: userId);
    }
    return AppUser(
      id: userId,
      name: u['name'] as String,
      email: userId,
      streak: (u['streak'] as int?) ?? 0,
    );
  }

  @override
  Future<void> signOut() async {}
}
