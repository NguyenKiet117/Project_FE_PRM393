import 'package:flutter/material.dart';

/// Màu & font lấy từ DESIGN.md của Stitch (SmartQuiz Mobile + Midnight Study).
/// Font: Plus Jakarta Sans (tiêu đề/nút) + Inter (nội dung).
/// Nếu chưa thêm file font vào assets, Flutter tự dùng font mặc định (không lỗi).
class AppTheme {
  static const _headFont = 'PlusJakartaSans';
  static const _bodyFont = 'Inter';

  static const _light = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF2563EB),
    onPrimary: Colors.white,
    secondary: Color(0xFF4F46E5),
    onSecondary: Colors.white,
    tertiary: Color(0xFF06B6D4),
    error: Color(0xFFEF4444),
    onError: Colors.white,
    primaryContainer: Color(0xFFDBE7FF),
    onPrimaryContainer: Color(0xFF001A42),
    secondaryContainer: Color(0xFFE0E0FF),
    onSecondaryContainer: Color(0xFF1B1464),
    surface: Color(0xFFF8F9FF),
    onSurface: Color(0xFF0B1C30),
    onSurfaceVariant: Color(0xFF434655),
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: Color(0xFFEFF4FF),
    surfaceContainer: Color(0xFFE5EEFF),
    outline: Color(0xFF737686),
    outlineVariant: Color(0xFFC3C6D7),
  );

  static const _dark = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF4D8EFF),
    onPrimary: Color(0xFF00285D),
    secondary: Color(0xFFC0C1FF),
    onSecondary: Color(0xFF1000A9),
    tertiary: Color(0xFFA4C9FF),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    primaryContainer: Color(0xFF1B3A73),
    onPrimaryContainer: Color(0xFFD8E2FF),
    secondaryContainer: Color(0xFF3C3C9E),
    onSecondaryContainer: Color(0xFFE1E0FF),
    surface: Color(0xFF0F131C),
    onSurface: Color(0xFFDFE2EF),
    onSurfaceVariant: Color(0xFFC2C6D6),
    surfaceContainerLowest: Color(0xFF0A0E17),
    surfaceContainerLow: Color(0xFF181B25),
    surfaceContainer: Color(0xFF1E293B),
    outline: Color(0xFF8C909F),
    outlineVariant: Color(0xFF334155),
  );

  static ThemeData light() => _build(_light);
  static ThemeData dark() => _build(_dark);

  static ThemeData _build(ColorScheme cs) {
    final base = ThemeData(
        useMaterial3: true, colorScheme: cs, scaffoldBackgroundColor: cs.surface);
    return base.copyWith(
      textTheme: base.textTheme.apply(
          fontFamily: _bodyFont,
          bodyColor: cs.onSurface,
          displayColor: cs.onSurface),
      // Thanh tiến độ: nền xám nhạt (mặc định lấy secondaryContainer nên bị tô kín).
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: cs.primary,
        linearTrackColor: cs.surfaceContainer,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cs.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: cs.primary, width: 2)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: cs.error, width: 1.5)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: cs.error, width: 2)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          textStyle: const TextStyle(
              fontFamily: _headFont, fontWeight: FontWeight.w700, fontSize: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          backgroundColor: cs.surfaceContainerLow,
          foregroundColor: cs.onSurface,
          side: BorderSide.none,
          textStyle: const TextStyle(
              fontFamily: _headFont, fontWeight: FontWeight.w600, fontSize: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  /// Màu nền thẻ: trắng ở bản sáng, hơi sáng hơn nền ở bản tối (đúng Stitch).
  static Color card(ColorScheme cs) => cs.brightness == Brightness.light
      ? cs.surfaceContainerLowest
      : cs.surfaceContainerLow;

  /// Style cho tiêu đề (Plus Jakarta Sans).
  static TextStyle head({double size = 18, FontWeight w = FontWeight.w700, Color? color}) =>
      TextStyle(fontFamily: _headFont, fontSize: size, fontWeight: w, color: color);
}
