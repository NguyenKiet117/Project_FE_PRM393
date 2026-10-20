import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../models/app_notification.dart';
import '../providers/auth_provider.dart';
import '../providers/library_provider.dart' show LoadState;
import '../providers/notification_provider.dart';
import '../widgets/common.dart';

IconData _iconOf(NotifKind k) => switch (k) {
      NotifKind.reminder => Icons.alarm,
      NotifKind.achievement => Icons.emoji_events_outlined,
      NotifKind.importDone => Icons.table_chart_outlined,
      NotifKind.system => Icons.notifications_none,
    };

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final np = context.watch<NotificationProvider>();
    final userId = context.read<AuthProvider>().user?.id;
    final items = np.visible;

    Widget chip(String label, NotifFilter f, Key key) => ChoiceChip(
          key: key,
          label: Text(label),
          selected: np.filter == f,
          onSelected: (_) => np.setFilter(f),
        );

    return RefreshIndicator(
      onRefresh: () async {
        if (userId != null) await np.load(userId);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Row(children: [
            Expanded(
              child: Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('Thông báo', style: AppTheme.head(size: 22, w: FontWeight.w800)),
                  if (np.unread > 0) Pill('${np.unread} mới', color: cs.primary),
                ],
              ),
            ),
            TextButton.icon(
              key: const Key('mark_all_read'),
              onPressed: np.unread == 0 ? null : np.markAllRead,
              icon: const Icon(Icons.done_all, size: 18),
              label: const Text('Đọc hết'),
            ),
          ]),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 4, children: [
            chip('Tất cả (${np.countOf(NotifFilter.all)})', NotifFilter.all, const Key('nf_all')),
            chip('Nhắc học', NotifFilter.study, const Key('nf_study')),
            chip('Hệ thống', NotifFilter.system, const Key('nf_system')),
          ]),
          const SizedBox(height: 12),
          if (items.isEmpty) _State(np: np, userId: userId),
          for (final n in items) ...[
            _NotifCard(n: n, onTap: () => np.markRead(n.id)),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _State extends StatelessWidget {
  final NotificationProvider np;
  final String? userId;
  const _State({required this.np, required this.userId});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (np.state == LoadState.loading) {
      return const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()));
    }
    if (np.state == LoadState.error) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          Icon(Icons.cloud_off, size: 40, color: cs.error),
          const SizedBox(height: 8),
          Text(np.error ?? 'Không tải được thông báo', textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size(160, 44)),
            onPressed: userId == null ? null : () => np.load(userId!),
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
          ),
        ]),
      );
    }
    return const Padding(
      padding: EdgeInsets.all(32),
      child: Center(child: Text('Chưa có thông báo nào')),
    );
  }
}

class _NotifCard extends StatelessWidget {
  final AppNotification n;
  final VoidCallback onTap;
  const _NotifCard({required this.n, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AppCard(
      key: Key('notif_${n.id}'),
      onTap: onTap,
      color: n.isRead ? null : cs.primary.withValues(alpha: 0.08),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CircleAvatar(
          backgroundColor: cs.primary.withValues(alpha: 0.14),
          child: Icon(_iconOf(n.kind), color: cs.primary, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text(n.title,
                    style: AppTheme.head(
                        size: 15, w: n.isRead ? FontWeight.w600 : FontWeight.w800)),
              ),
              if (!n.isRead)
                Container(
                  key: Key('unread_dot_${n.id}'),
                  width: 9,
                  height: 9,
                  margin: const EdgeInsets.only(left: 8),
                  decoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle),
                ),
            ]),
            const SizedBox(height: 2),
            Text(timeAgo(n.timestamp), style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 6),
            Text(n.message, style: TextStyle(color: cs.onSurfaceVariant, height: 1.35)),
          ]),
        ),
      ]),
    );
  }
}
