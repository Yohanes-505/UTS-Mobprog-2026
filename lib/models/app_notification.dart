enum AppNotificationType { match, message, unknown }

class AppNotification {
  final AppNotificationType type;
  final String title;
  final String body;
  final String? relatedId; // id match ato chat_id buat routing pas ditap

  AppNotification({
    required this.type,
    required this.title,
    required this.body,
    this.relatedId,
  });

  // Ini format data yg dikirim dari backend pas ada notif masuk
  // Kalo backend ngirim datanya beda format nanti pas dibaca
  // di sini jadi kacau. Jdi usahain formatnya tetep kayak gini ajaaa:
  // {
  //   "type": "match", // atau "message"
  //   "title": "It's a Match!",
  //   "body": "Kamu punya match baru!",
  //   "related_id": "abc123", // id match / chat_id, buat tau notif ini soal apa
  // }

  factory AppNotification.fromData(Map<String, dynamic> data) {
    final rawType = data['type']?.toString() ?? '';
    final type = AppNotificationType.values.firstWhere(
      (t) => t.name == rawType,
      orElse: () => AppNotificationType.unknown,
    );

    return AppNotification(
      type: type,
      title: data['title']?.toString() ?? 'Notifikasi Baru',
      body: data['body']?.toString() ?? '',
      relatedId: data['related_id']?.toString(),
    );
  }
}