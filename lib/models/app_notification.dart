enum NotifKind { reminder, achievement, importDone, system }

class AppNotification {
  final String id;
  final String title;
  final String message;
  final String userId;
  final DateTime timestamp;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.userId,
    required this.timestamp,
    this.isRead = false,
  });

  /// Backend chưa có trường "loại" nên đoán theo tiêu đề.
  NotifKind get kind {
    final t = title.toLowerCase();
    if (t.contains('streak') || t.contains('reminder') || t.contains('daily') || t.contains('goal')) {
      return NotifKind.reminder;
    }
    if (t.contains('import')) return NotifKind.importDone;
    if (t.contains('quiz completed') || t.contains('score')) return NotifKind.achievement;
    return NotifKind.system;
  }

  /// Tab "Nhắc học" = nhắc nhở + kết quả; còn lại thuộc tab "Hệ thống".
  bool get isStudy => kind == NotifKind.reminder || kind == NotifKind.achievement;

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        title: title,
        message: message,
        userId: userId,
        timestamp: timestamp,
        isRead: isRead ?? this.isRead,
      );

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: j['id'] as String,
        title: (j['title'] as String?) ?? '',
        message: (j['message'] as String?) ?? '',
        userId: (j['userId'] as String?) ?? '',
        timestamp: parseServerTime(j['timestamp']),
        isRead: (j['isRead'] as bool?) ?? false,
      );
}

/// Server trả LocalDateTime (UTC, không có múi giờ) dạng chuỗi ISO hoặc mảng số.
DateTime parseServerTime(Object? v) {
  if (v is String) {
    var s = v;
    if (!s.endsWith('Z') && !RegExp(r'[+-]\d\d:?\d\d$').hasMatch(s)) s = '${s}Z';
    return DateTime.tryParse(s)?.toLocal() ?? DateTime.now();
  }
  if (v is List && v.length >= 5) {
    final n = [for (final e in v) (e as num).toInt()];
    return DateTime.utc(n[0], n[1], n[2], n[3], n[4], n.length > 5 ? n[5] : 0).toLocal();
  }
  return DateTime.now();
}
