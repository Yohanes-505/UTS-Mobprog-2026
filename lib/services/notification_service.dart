import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();

Future<void> initLocalNotifications() async {
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidInit);
  await _localNotifications.initialize(initSettings);
  debugPrint('Local notifications initialized');
}

void listenForNotifications(String userId) {
  final supabase = Supabase.instance.client;

  supabase
      .from('matches')
      .stream(primaryKey: ['id'])
      .listen((List<Map<String, dynamic>> data) {
    if (data.isEmpty) return;
    final latest = data.last;

    final isRelevant = latest['user_a_id'] == userId ||
        latest['user_b_id'] == userId;

    if (isRelevant) {
      _showNotification(
        title: "It's a Match!",
        body: 'Kamu punya match baru, yuk mulai ngobrol!',
      );
    }
  });

  supabase
      .from('messages')
      .stream(primaryKey: ['id'])
      .listen((List<Map<String, dynamic>> data) {
    if (data.isEmpty) return;
    final latest = data.last;
    final isForMe = latest['receiver_id'] == userId;
    final isFromMe = latest['sender_id'] == userId;

    if (isForMe && !isFromMe) {
      _showNotification(
        title: 'Pesan Baru',
        body: latest['content']?.toString() ?? 'Kamu dapat pesan baru',
      );
    }
  });

  debugPrint('Listening for matches & messages realtime updates...');
}

Future<void> _showNotification({
  required String title,
  required String body,
}) async {
  await _localNotifications.show(
    // id unik buat tiap notif
    DateTime.now().millisecondsSinceEpoch ~/ 1000,
    title,
    body,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'foreground_channel',
        'App Notifications',
        importance: Importance.high,
        priority: Priority.high,
      ),
    ),
  );
}