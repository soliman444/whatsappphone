import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  NotificationService({this.onOpenChat});

  final void Function(int chatId)? onOpenChat;
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    if (_ready || kIsWeb) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      const InitializationSettings(android: android),
      onDidReceiveNotificationResponse: (response) {
        final chatId = int.tryParse(response.payload ?? '');
        if (chatId != null) onOpenChat?.call(chatId);
      },
    );
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        'wa_messages',
        'الرسائل',
        description: 'إشعارات الرسائل الجديدة',
        importance: Importance.high,
      ),
    );
    _ready = true;
  }

  Future<void> requestPermission() async {
    try {
      await Permission.notification.request();
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    } catch (_) {}
  }

  Future<void> showIncoming({
    required int chatId,
    required String title,
    required String body,
  }) async {
    if (!_ready) return;
    await _plugin.show(
      chatId,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'wa_messages',
          'الرسائل',
          channelDescription: 'إشعارات الرسائل الجديدة',
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.message,
        ),
      ),
      payload: '$chatId',
    );
  }
}
