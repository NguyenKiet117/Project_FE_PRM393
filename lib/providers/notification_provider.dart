import 'package:flutter/foundation.dart';
import '../models/app_notification.dart';
import '../services/api_client.dart';
import '../services/notification_repository.dart';
import 'library_provider.dart' show LoadState;

enum NotifFilter { all, study, system }

class NotificationProvider extends ChangeNotifier {
  NotificationProvider(this._repo);
  final NotificationRepository _repo;

  List<AppNotification> items = [];
  LoadState state = LoadState.idle;
  String? error;
  NotifFilter filter = NotifFilter.all;

  int get unread => items.where((n) => !n.isRead).length;
  int countOf(NotifFilter f) => _filtered(f).length;

  List<AppNotification> get visible => _filtered(filter);

  List<AppNotification> _filtered(NotifFilter f) => switch (f) {
        NotifFilter.all => items,
        NotifFilter.study => items.where((n) => n.isStudy).toList(),
        NotifFilter.system => items.where((n) => !n.isStudy).toList(),
      };

  void setFilter(NotifFilter f) {
    filter = f;
    notifyListeners();
  }

  Future<void> load(String userId) async {
    state = LoadState.loading;
    error = null;
    notifyListeners();
    try {
      final list = await _repo.fetch(userId);
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      items = list;
      state = LoadState.loaded;
    } catch (e) {
      error = e is ApiException ? e.message : 'Không tải được thông báo';
      state = LoadState.error;
    }
    notifyListeners();
  }

  /// Cập nhật ngay trên màn hình, gửi server sau; lỗi mạng thì hoàn lại.
  Future<void> markRead(String id) async {
    final i = items.indexWhere((n) => n.id == id);
    if (i < 0 || items[i].isRead) return;
    items[i] = items[i].copyWith(isRead: true);
    notifyListeners();
    try {
      await _repo.markRead(id);
    } catch (_) {
      items[i] = items[i].copyWith(isRead: false);
      notifyListeners();
    }
  }

  Future<void> markAllRead() async {
    final ids = [for (final n in items) if (!n.isRead) n.id];
    for (final id in ids) {
      await markRead(id);
    }
  }

  void clear() {
    items = [];
    state = LoadState.idle;
    filter = NotifFilter.all;
    notifyListeners();
  }
}
