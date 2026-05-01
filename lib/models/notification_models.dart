class MyNotificationItem {
  final String id;
  final String title;
  final String? body;
  final String sendStatus;
  final String channel;
  final String createdAt;
  final String? sentAt;

  const MyNotificationItem({
    required this.id,
    required this.title,
    this.body,
    required this.sendStatus,
    required this.channel,
    required this.createdAt,
    this.sentAt,
  });

  factory MyNotificationItem.fromJson(Map<String, dynamic> json) =>
      MyNotificationItem(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        body: json['body']?.toString(),
        sendStatus: json['send_status']?.toString() ?? '',
        channel: json['channel']?.toString() ?? '',
        createdAt: json['created_at']?.toString() ?? '',
        sentAt: json['sent_at']?.toString(),
      );

  String? get displayTime {
    final iso = sentAt ?? createdAt;
    if (iso.isEmpty) return null;
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    final local = d.toLocal();
    final months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    final hour = local.hour > 12
        ? local.hour - 12
        : (local.hour == 0 ? 12 : local.hour);
    final period = local.hour >= 12 ? 'PM' : 'AM';
    final min = local.minute.toString().padLeft(2, '0');
    return '${months[local.month - 1]} ${local.day}, ${local.year} $hour:$min $period';
  }
}
