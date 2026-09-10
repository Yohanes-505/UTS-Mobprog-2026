/// Sumber report dibuat dari mana.
enum ReportSource {
  chat,
  profile;

  String get value => name;
}

class ReportModel {
  final String reporterId;
  final String reportedUserId;
  final String reason;
  final ReportSource source;
  final String? chatRoomId;

  ReportModel({
    required this.reporterId,
    required this.reportedUserId,
    required this.reason,
    required this.source,
    this.chatRoomId,
  });

  Map<String, dynamic> toJson() {
    return {
      'reporter_id': reporterId,
      'reported_user_id': reportedUserId,
      'reason': reason,
      'source': source.value,
      'chat_room_id': chatRoomId,
      'status': 'pending',
    };
  }
}