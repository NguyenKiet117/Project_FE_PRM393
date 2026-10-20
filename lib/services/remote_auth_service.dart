import 'api_client.dart';
import 'auth_service.dart';

/// Đăng nhập/đăng ký qua backend: /api/auth/send-otp, /register, /login.
class RemoteAuthService implements AuthService {
  RemoteAuthService(this._api);
  final ApiClient _api;

  @override
  bool get requiresOtp => true;

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
    _api.token = token; // các request sau tự gắn "Authorization: Bearer ..."
    return AppUser(
      id: d['id'] as String,
      name: (d['fullName'] as String?) ?? '',
      email: (d['email'] as String?) ?? '',
      streak: (d['currentStreak'] as num?)?.toInt() ?? 0,
      token: token,
    );
  }

  @override
  Future<void> sendOtp({required String email}) =>
      _guard(() => _api.post('/api/auth/send-otp', body: {'email': email.trim()}));

  @override
  Future<AppUser> signIn({required String email, required String password}) =>
      _guard(() async => _user(await _api.post('/api/auth/login',
          body: {'email': email.trim(), 'password': password})));

  @override
  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
    String otp = '',
  }) =>
      _guard(() async => _user(await _api.post('/api/auth/register', body: {
            'fullName': name.trim(),
            'email': email.trim(),
            'password': password,
            'otp': otp.trim(),
          })));

  @override
  Future<void> signOut() async => _api.token = null;
}
