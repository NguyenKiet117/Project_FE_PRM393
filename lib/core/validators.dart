/// Hàm thuần (pure function) -> dễ viết Unit Test.
/// Trả về null nếu hợp lệ, trả về chuỗi lỗi nếu không hợp lệ.
class Validators {
  static String? email(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Vui lòng nhập email';
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s);
    return ok ? null : 'Email không hợp lệ';
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu';
    if (v.length < 6) return 'Mật khẩu tối thiểu 6 ký tự';
    return null;
  }

  static String? name(String? v) {
    if ((v?.trim() ?? '').isEmpty) return 'Vui lòng nhập họ tên';
    return null;
  }

  static String? Function(String?) confirm(String Function() original) =>
      (v) => v == original() ? null : 'Mật khẩu xác nhận không khớp';
}
