import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/app_notification.dart';

final FirebaseMessaging _messaging = FirebaseMessaging.instance;
final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();

void Function(AppNotification notif)? onNotificationTap;

@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Notif diterima saat background/killed: ${message.data}');
}

Future<void> initNotifications() async {
  // buat minta izin notifikasi ke user
  final settings = await _messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  debugPrint('Izin notifikasi: ${settings.authorizationStatus}');

  // ngmbil FCM token, ini yang dikirim ke backend yang dipake buat
  // nentuin HP mana yangg harus dikirimin notif
  final token = await _messaging.getToken();
  debugPrint('FCM Token: $token');
  // TODO: kirim token ini ke backend biar Supabase trigger/edge function tau harus
  // kirim notif ke token mana pas ada match/pesan baru.

  // setup local notification yang buat nampilin notif manual pas app lagi kebuka
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidInit);
  await _localNotifications.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (response) {
      final payload = response.payload;
      if (payload == null || onNotificationTap == null) return;
      onNotificationTap!(_decodePayload(payload));
    },
  );

  // Notif masuk pas app lagi kebuka - FCM gak nampilin
  // otomatis jadi kita tampilin sendiri pakai local notification
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint('Notif masuk (foreground): ${message.data}');
    final notif = AppNotification.fromData(message.data);
    _showLocalNotification(notif);
  });

  // notif ditap pas app bckground
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    debugPrint('Notif di-tap dari background: ${message.data}');
    final notif = AppNotification.fromData(message.data);
    onNotificationTap?.call(notif);
  });

  // notif ditap pas app ketutup total, lalu user buka app dari notif
  final initialMessage = await _messaging.getInitialMessage();
  if (initialMessage != null) {
    debugPrint('App dibuka dari notif (killed state): ${initialMessage.data}');
    final notif = AppNotification.fromData(initialMessage.data);
    // delay dikit biar navigatorKey udah siap dulu
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onNotificationTap?.call(notif);
    });
  }
}

Future<void> _showLocalNotification(AppNotification notif) async {
  await _localNotifications.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000,
    notif.title,
    notif.body,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'foreground_channel',
        'App Notifications',
        importance: Importance.high,
        priority: Priority.high,
      ),
    ),
    payload: '${notif.type.name}|${notif.relatedId ?? ''}',
  );
}

AppNotification _decodePayload(String payload) {
  final parts = payload.split('|');
  final rawType = parts.isNotEmpty ? parts[0] : '';
  final type = AppNotificationType.values.firstWhere(
    (t) => t.name == rawType,
    orElse: () => AppNotificationType.unknown,
  );
  final relatedId = (parts.length > 1 && parts[1].isNotEmpty) ? parts[1] : null;

  return AppNotification(type: type, title: '', body: '', relatedId: relatedId);
}