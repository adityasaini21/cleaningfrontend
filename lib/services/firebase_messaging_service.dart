import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FirebaseMessagingService {
  static final FlutterLocalNotificationsPlugin
  localNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel channel =
  AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description:
    'This channel is used for important notifications.',
    importance: Importance.max,
  );

  static Future<void> initialize() async {
    // =========================================
    // REQUEST NOTIFICATION PERMISSION
    // =========================================

    final NotificationSettings settings =
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint(
      "NOTIFICATION PERMISSION: ${settings.authorizationStatus}",
    );

    // =========================================
    // IOS FOREGROUND SETTINGS
    // =========================================

    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // =========================================
    // LOCAL NOTIFICATION INIT
    // =========================================

    const AndroidInitializationSettings
    androidInitializationSettings =
    AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const InitializationSettings initializationSettings =
    InitializationSettings(
      android: androidInitializationSettings,
    );

    await localNotificationsPlugin.initialize(
      settings: initializationSettings,
    );

    // =========================================
    // CREATE ANDROID CHANNEL
    // =========================================

    final AndroidFlutterLocalNotificationsPlugin?
    androidPlugin =
    localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(
      channel,
    );

    // =========================================
    // FOREGROUND MESSAGE
    // =========================================

    FirebaseMessaging.onMessage.listen(
          (RemoteMessage message) async {
        debugPrint("🔥 ON MESSAGE FIRED");

        debugPrint(
          "MESSAGE DATA: ${message.data}",
        );

        debugPrint(
          "TITLE: ${message.notification?.title}",
        );

        debugPrint(
          "BODY: ${message.notification?.body}",
        );

        final String title =
            message.notification?.title ??
                message.data['title']?.toString() ??
                'Notification';

        final String body =
            message.notification?.body ??
                message.data['body']?.toString() ??
                '';

        await localNotificationsPlugin.show(
          id: DateTime.now()
              .millisecondsSinceEpoch
              .remainder(2147483647),
          title: title,
          body: body,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel',
              'High Importance Notifications',
              channelDescription:
              'This channel is used for important notifications.',
              importance: Importance.max,
              priority: Priority.high,
              playSound: true,
              enableVibration: true,
              icon: '@mipmap/ic_launcher',
            ),
          ),
        );

        debugPrint(
          "✅ LOCAL NOTIFICATION DISPLAYED",
        );
      },
    );

    // =========================================
    // NOTIFICATION CLICK
    // =========================================

    FirebaseMessaging.onMessageOpenedApp.listen(
          (RemoteMessage message) {
        debugPrint(
          "NOTIFICATION CLICKED",
        );
      },
    );

    // =========================================
    // DEBUG TOKEN
    // =========================================

    if (kDebugMode) {
      final String? token =
      await FirebaseMessaging.instance.getToken();

      debugPrint(
        "FCM TOKEN FOR TESTING: $token",
      );
    }
  }
}