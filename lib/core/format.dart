/// 583s -> "09:43" (dùng cho đồng hồ & màn Kết quả).
String formatDuration(Duration d) {
  final total = d.isNegative ? 0 : d.inSeconds;
  final m = (total ~/ 60).toString().padLeft(2, '0');
  final s = (total % 60).toString().padLeft(2, '0');
  return '$m:$s';
}

/// "2 giờ trước", "hôm qua"... (màn Home: Last practiced).
String timeAgo(DateTime t, {DateTime? now}) {
  final d = (now ?? DateTime.now()).difference(t);
  if (d.inMinutes < 1) return 'vừa xong';
  if (d.inHours < 1) return '${d.inMinutes} phút trước';
  if (d.inDays < 1) return '${d.inHours} giờ trước';
  if (d.inDays == 1) return 'hôm qua';
  return '${d.inDays} ngày trước';
}
