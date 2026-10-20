import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/library_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/quiz_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/common.dart';

/// Hồ sơ người dùng (thiết kế Stitch không có màn này nên bố cục do nhóm tự làm).
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Đăng xuất?'),
        actions: [
          TextButton(
              key: const Key('logout_cancel'),
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy')),
          FilledButton(
              key: const Key('logout_confirm'),
              style: FilledButton.styleFrom(minimumSize: const Size(100, 40)),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Đăng xuất')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    // Lấy provider trước khi đóng màn (context sẽ mất hiệu lực sau pop).
    final auth = context.read<AuthProvider>();
    final lib = context.read<LibraryProvider>();
    final notifs = context.read<NotificationProvider>();
    final quiz = context.read<QuizProvider>();
    Navigator.of(context).popUntil((r) => r.isFirst);
    quiz.exit();
    lib.clearProgress();
    notifs.clear();
    await auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final user = context.watch<AuthProvider>().user;
    final lib = context.watch<LibraryProvider>();
    final theme = context.watch<ThemeProvider>();
    final initial = (user?.name.trim().isNotEmpty ?? false) ? user!.name.trim()[0].toUpperCase() : '?';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget stat(IconData i, String v, String l) => Expanded(
          child: AppCard(
            padding: const EdgeInsets.all(14),
            child: Column(children: [
              Icon(i, color: cs.primary),
              const SizedBox(height: 6),
              Text(v, style: AppTheme.head(size: 20, w: FontWeight.w800)),
              Text(l, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
            ]),
          ),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Hồ sơ')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Center(
          child: CircleAvatar(
            radius: 44,
            backgroundColor: cs.primary,
            child: Text(initial,
                style: AppTheme.head(size: 36, w: FontWeight.w800, color: cs.onPrimary)),
          ),
        ),
        const SizedBox(height: 12),
        Text(user?.name ?? '',
            key: const Key('profile_name'),
            textAlign: TextAlign.center,
            style: AppTheme.head(size: 22, w: FontWeight.w800)),
        Text(user?.email ?? '',
            textAlign: TextAlign.center, style: TextStyle(color: cs.onSurfaceVariant)),
        const SizedBox(height: 20),
        Row(children: [
          stat(Icons.local_fire_department, '${user?.streak ?? 0}', 'Chuỗi ngày'),
          const SizedBox(width: 12),
          stat(Icons.history, '${lib.history.length}', 'Bộ đã luyện'),
          const SizedBox(width: 12),
          stat(Icons.check_circle_outline, '${lib.totalSolved}', 'Câu đúng'),
        ]),
        const SizedBox(height: 16),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: SwitchListTile(
            key: const Key('dark_switch'),
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text('Chế độ tối'),
            value: isDark,
            onChanged: theme.setDark,
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          key: const Key('btn_logout'),
          style: OutlinedButton.styleFrom(foregroundColor: cs.error),
          onPressed: () => _logout(context),
          icon: const Icon(Icons.logout),
          label: const Text('Đăng xuất'),
        ),
        const SizedBox(height: 16),
        Text('SmartQuiz • PRM393',
            textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
      ]),
    );
  }
}
