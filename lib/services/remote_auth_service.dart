import 'api_client.dart';
import 'auth_service.dart';

/// Đăng nhập/đăng ký qua backend: /api/auth/register, /api/auth/login, /api/auth/profile/{userId}.
class RemoteAuthService implements AuthService {
  RemoteAuthService(this._api);
  final ApiClient _api;

  Future<T> _guard<T>(Future<T> Function() f) async {
    try {
      return await f();
    } on ApiException catch (e) {
      throw AuthException(e.message);
    }
  }

  AppUser _user(Object? data) {
    final d = Map<String, dynamic>.from(data as Map);
    final token = d['token'] as String?;
    if (token != null) {
      _api.token = token; // các request sau tự gắn "Authorization: Bearer ..."
    }
    return AppUser(
      id: d['id'] as String,
      name: (d['fullName'] as String?) ?? '',
      email: (d['email'] as String?) ?? '',
      streak: (d['currentStreak'] as num?)?.toInt() ?? 0,
      token: token ?? _api.token,
    );
  }

  @override
  Future<AppUser> signIn({required String email, required String password}) =>
      _guard(() async => _user(await _api.post('/api/auth/login',
          body: {'email': email.trim(), 'password': password})));

  @override
  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
    String confirmPassword = '',
  }) =>
      _guard(() async => _user(await _api.post('/api/auth/register', body: {
            'fullName': name.trim(),
            'email': email.trim(),
            'password': password,
            'confirmPassword': confirmPassword,
          })));

  @override
  Future<AppUser> fetchProfile(String userId) => _guard(() async {
        final data = await _api.get('/api/auth/profile/$userId');
        final d = Map<String, dynamic>.from(data as Map);
        return AppUser(
          id: (d['id'] as String?) ?? userId,
          name: (d['fullName'] as String?) ?? '',
          email: (d['email'] as String?) ?? '',
          streak: (d['currentStreak'] as num?)?.toInt() ?? 0,
          token: _api.token,
        );
      });

  @override
  Future<void> signOut() async => _api.token = null;
}
