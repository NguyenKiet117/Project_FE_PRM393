import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/validators.dart';
import '../providers/auth_provider.dart';

/// Một màn hình, hai chế độ (Sign In / Create Account) – đúng thiết kế Stitch.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _otp = TextEditingController();
  bool _isLogin = true;
  bool _obscure = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _otp.dispose();
    super.dispose();
  }

  void _setMode(bool login) {
    if (_isLogin == login) return;
    setState(() => _isLogin = login);
    _formKey.currentState?.reset();
  }

  void _toast(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _sendOtp() async {
    final err = Validators.email(_email.text);
    if (err != null) {
      _toast(err);
      return;
    }
    final auth = context.read<AuthProvider>();
    final ok = await auth.sendOtp(_email.text.trim());
    if (!mounted) return;
    _toast(ok
        ? 'Đã gửi mã OTP tới ${_email.text.trim()}'
        : (auth.error ?? 'Không gửi được mã OTP'));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = _isLogin
        ? await auth.signIn(_email.text, _password.text)
        : await auth.register(_name.text, _email.text, _password.text, otp: _otp.text);
    if (!ok && mounted) _toast(auth.error ?? 'Lỗi');
    // Thành công: main.dart tự chuyển sang Home vì user != null.
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final authState = context.watch<AuthProvider>();
    final loading = authState.isLoading;
    final requiresOtp = authState.requiresOtp;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                children: [
                  _Logo(cs: cs),
                  const SizedBox(height: 16),
                  Text('SmartQuiz', style: AppTheme.head(size: 30, w: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text('Ôn thi nhanh hơn, hiệu quả hơn',
                      style: TextStyle(color: cs.onSurfaceVariant)),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                            color: cs.primary.withValues(alpha: 0.08),
                            blurRadius: 24,
                            offset: const Offset(0, 8)),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _Tabs(isLogin: _isLogin, onChanged: _setMode),
                          const SizedBox(height: 20),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 200),
                            alignment: Alignment.topCenter,
                            child: _isLogin
                                ? const SizedBox(width: double.infinity)
                                : _Labeled(
                                    label: 'Họ tên',
                                    child: TextFormField(
                                      key: const Key('auth_name'),
                                      controller: _name,
                                      textInputAction: TextInputAction.next,
                                      decoration: const InputDecoration(
                                          prefixIcon: Icon(Icons.badge_outlined),
                                          hintText: 'Nguyễn Văn A'),
                                      validator: Validators.name,
                                    ),
                                  ),
                          ),
                          _Labeled(
                            label: 'Email trường / công việc',
                            child: TextFormField(
                              key: const Key('auth_email'),
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                  prefixIcon: Icon(Icons.mail_outline),
                                  hintText: 'ten@fpt.edu.vn'),
                              validator: Validators.email,
                            ),
                          ),
                          _Labeled(
                            label: 'Mật khẩu',
                            trailing: _isLogin
                                ? GestureDetector(
                                    onTap: () => _toast('Chưa hỗ trợ khôi phục mật khẩu trong phiên bản này'),
                                    child: Text('Quên mật khẩu?',
                                        style: AppTheme.head(
                                            size: 13, w: FontWeight.w600, color: cs.primary)),
                                  )
                                : null,
                            child: TextFormField(
                              key: const Key('auth_password'),
                              controller: _password,
                              obscureText: _obscure,
                              onFieldSubmitted: (_) => _submit(),
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.lock_outline),
                                hintText: '••••••••',
                                suffixIcon: IconButton(
                                  icon: Icon(_obscure
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined),
                                  onPressed: () => setState(() => _obscure = !_obscure),
                                ),
                              ),
                              validator: Validators.password,
                            ),
                          ),
                          if (!_isLogin && requiresOtp)
                            _Labeled(
                              label: 'Mã OTP (gửi qua email)',
                              child: TextFormField(
                                key: const Key('auth_otp'),
                                controller: _otp,
                                keyboardType: TextInputType.number,
                                maxLength: 6,
                                decoration: InputDecoration(
                                  counterText: '',
                                  prefixIcon: const Icon(Icons.pin_outlined),
                                  hintText: '6 chữ số',
                                  suffixIcon: TextButton(
                                    key: const Key('auth_send_otp'),
                                    onPressed: loading ? null : _sendOtp,
                                    child: const Text('Gửi mã'),
                                  ),
                                ),
                                validator: (v) => (v ?? '').trim().length == 6
                                    ? null
                                    : 'Nhập đủ 6 chữ số',
                              ),
                            ),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                                color: cs.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(16)),
                            child: Row(children: [
                              CircleAvatar(
                                  radius: 16,
                                  backgroundColor: cs.tertiary.withValues(alpha: 0.2),
                                  child: Icon(Icons.school_outlined,
                                      size: 18, color: cs.tertiary)),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: Text(
                                      'Đăng nhập một chạm với email trường đã xác minh.',
                                      style: TextStyle(
                                          fontSize: 13, color: cs.onSurfaceVariant))),
                            ]),
                          ),
                          const SizedBox(height: 20),
                          FilledButton(
                            key: const Key('auth_submit'),
                            onPressed: loading ? null : _submit,
                            child: loading
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2.5))
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(_isLogin ? 'Đăng nhập' : 'Tạo tài khoản'),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.arrow_forward, size: 20),
                                    ],
                                  ),
                          ),
                          const SizedBox(height: 20),
                          Row(children: [
                            Expanded(child: Divider(color: cs.outlineVariant)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text('HOẶC TIẾP TỤC VỚI',
                                  style: AppTheme.head(
                                      size: 11, color: cs.outline, w: FontWeight.w700)),
                            ),
                            Expanded(child: Divider(color: cs.outlineVariant)),
                          ]),
                          const SizedBox(height: 16),
                          Row(children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _toast('Chưa hỗ trợ đăng nhập bằng Google'),
                                icon: const Icon(Icons.g_mobiledata, size: 30),
                                label: const Text('Google'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _toast('Chưa hỗ trợ đăng nhập bằng Apple'),
                                icon: const Icon(Icons.apple, size: 22),
                                label: const Text('Apple'),
                              ),
                            ),
                          ]),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.center, children: [
                    Text(_isLogin ? 'Chưa có tài khoản?' : 'Đã có tài khoản?',
                        style: TextStyle(color: cs.onSurfaceVariant)),
                    TextButton(
                      key: const Key('auth_switch'),
                      onPressed: () => _setMode(!_isLogin),
                      child: Text(_isLogin ? 'Đăng ký' : 'Đăng nhập',
                          style: AppTheme.head(size: 15, color: cs.primary)),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  final ColorScheme cs;
  const _Logo({required this.cs});
  @override
  Widget build(BuildContext context) => Stack(clipBehavior: Clip.none, children: [
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            color: cs.primary,
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                  color: cs.primary.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8)),
            ],
          ),
          child: Icon(Icons.school_rounded, size: 44, color: cs.onPrimary),
        ),
        Positioned(
          right: -6,
          bottom: -6,
          child: CircleAvatar(
              radius: 15,
              backgroundColor: cs.surfaceContainerLowest,
              child: Icon(Icons.bolt, size: 20, color: cs.primary)),
        ),
      ]);
}

class _Tabs extends StatelessWidget {
  final bool isLogin;
  final ValueChanged<bool> onChanged;
  const _Tabs({required this.isLogin, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Widget tab(Key k, bool login, IconData icon, String text) {
      final selected = isLogin == login;
      return Expanded(
        child: GestureDetector(
          key: k,
          behavior: HitTestBehavior.opaque,
          onTap: () => onChanged(login),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: selected ? cs.surfaceContainerLowest : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, size: 20, color: selected ? cs.primary : cs.onSurfaceVariant),
              const SizedBox(width: 6),
              Flexible(
                child: Text(text,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.head(
                        size: 15,
                        color: selected ? cs.primary : cs.onSurfaceVariant)),
              ),
            ]),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
          color: cs.surfaceContainerLow, borderRadius: BorderRadius.circular(18)),
      child: Row(children: [
        tab(const Key('tab_signin'), true, Icons.login, 'Đăng nhập'),
        tab(const Key('tab_signup'), false, Icons.person_add_alt, 'Tạo tài khoản'),
      ]),
    );
  }
}

class _Labeled extends StatelessWidget {
  final String label;
  final Widget? trailing;
  final Widget child;
  const _Labeled({required this.label, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(label,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.head(size: 14, w: FontWeight.w600)),
                ),
                ?trailing,
              ],
            ),
          ),
          child,
        ]),
      );
}
