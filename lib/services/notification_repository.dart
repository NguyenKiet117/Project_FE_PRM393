import '../models/app_notification.dart';
import 'api_client.dart';

abstract class NotificationRepository {
  Future<List<AppNotification>> fetch(String userId);
  Future<void> markRead(String id);
}

class FakeNotificationRepository implements NotificationRepository {
  @override
  Future<List<AppNotification>> fetch(String userId) async => [
        AppNotification(
            id: 'n1',
            title: 'Daily Study Streak Reminder 🔥',
            message: 'Keep your streak alive! Practice 10 quick questions today.',
            userId: userId,
            timestamp: DateTime.now().subtract(const Duration(minutes: 10))),
        AppNotification(
            id: 'n2',
            title: 'Quiz Completed: Flutter Basics',
            message: 'You scored 80% (4/5).',
            userId: userId,
            timestamp: DateTime.now().subtract(const Duration(hours: 5)),
            isRead: true),
      ];

  @override
  Future<void> markRead(String id) async {}
}

class RemoteNotificationRepository implements NotificationRepository {
  RemoteNotificationRepository(this._api);
  final ApiClient _api;

  @override
  Future<List<AppNotification>> fetch(String userId) async {
    final data = await _api.get('/api/notifications/$userId') as List? ?? const [];
    return [
      for (final j in data) AppNotification.fromJson(Map<String, dynamic>.from(j as Map))
    ];
  }

  @override
  Future<void> markRead(String id) async {
    await _api.put('/api/notifications/$id/read');
  }
}
