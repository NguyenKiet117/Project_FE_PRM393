import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/library_provider.dart';
import '../providers/notification_provider.dart';
import 'home_screen.dart';
import 'import_screen.dart';
import 'library_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';

/// Khung 4 tab: Home / Library / Import / Alerts + ảnh đại diện mở Hồ sơ.
class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> {
  int _index = 0;
  static const _titles = ['SmartQuiz', 'Thư viện', 'Import Excel', 'Thông báo'];

  /// Cho màn con chuyển tab: MainShellState.of(context)?.goTo(2)
  static MainShellState? of(BuildContext context) =>
      context.findAncestorStateOfType<MainShellState>();

  void goTo(int i) {
    setState(() => _index = i);
    if (i == 3) _loadNotifications();
  }

  void _loadNotifications() {
    final uid = context.read<AuthProvider>().user?.id;
    if (uid != null) context.read<NotificationProvider>().load(uid);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<LibraryProvider>().load();
      _loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final user = context.watch<AuthProvider>().user;
    final unread = context.watch<NotificationProvider>().unread;
    final initial = (user?.name.trim().isNotEmpty ?? false) ? user!.name.trim()[0].toUpperCase() : '?';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(_titles[_index], style: AppTheme.head(size: 20, w: FontWeight.w800)),
        actions: [
          IconButton(
            key: const Key('open_profile'),
            tooltip: 'Hồ sơ',
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: cs.primary,
              child: Text(initial, style: TextStyle(color: cs.onPrimary, fontWeight: FontWeight.bold)),
            ),
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: const [
        HomeScreen(),
        LibraryScreen(),
        ImportScreen(),
        NotificationsScreen(),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: goTo,
        destinations: [
          const NavigationDestination(
              icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          const NavigationDestination(
              icon: Icon(Icons.video_library_outlined),
              selectedIcon: Icon(Icons.video_library),
              label: 'Library'),
          const NavigationDestination(
              icon: Icon(Icons.add_circle_outline),
              selectedIcon: Icon(Icons.add_circle),
              label: 'Import'),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              child: const Icon(Icons.notifications_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              child: const Icon(Icons.notifications),
            ),
            label: 'Alerts',
          ),
        ],
      ),
    );
  }
}
