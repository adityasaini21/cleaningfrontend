import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;

import '../models/notification_model.dart';
import 'auth_service.dart';

class NotificationService {
  final String baseUrl = "http://10.0.2.2:8080";

  // =========================================
  // REAL-TIME NOTIFICATION STREAM
  // =========================================

  static final StreamController<void>
  _notificationStreamController =
  StreamController<void>.broadcast();

  static Stream<void> get notificationStream =>
      _notificationStreamController.stream;

  static void notifyNotificationReceived() {
    _notificationStreamController.add(null);
  }

  // =========================================
  // INIT FCM LISTENERS
  // =========================================

  static void initializeRealtimeListeners() {
    FirebaseMessaging.onMessage.listen(
          (RemoteMessage message) {
        print("REALTIME NOTIFICATION RECEIVED");

        print("TITLE: ${message.data['title']}");
        print("BODY: ${message.data['body']}");

        notifyNotificationReceived();
      },
    );

    FirebaseMessaging.onMessageOpenedApp.listen(
          (RemoteMessage message) {
        print("NOTIFICATION CLICKED");

        notifyNotificationReceived();
      },
    );

    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage? message) {
      if (message != null) {
        print("APP OPENED FROM TERMINATED STATE");

        notifyNotificationReceived();
      }
    });
  }

  // =========================================
  // GET MY NOTIFICATIONS
  // =========================================

  Future<List<NotificationModel>>
  getMyNotifications() async {
    final response = await http.get(
      Uri.parse(
        "$baseUrl/api/notifications",
      ),
      headers: {
        "Authorization":
        "Bearer ${AuthService.token}",
      },
    );

    if (response.statusCode == 200) {
      final data =
      jsonDecode(response.body);

      return List<NotificationModel>.from(
        data.map(
              (x) =>
              NotificationModel.fromJson(x),
        ),
      );
    }

    return [];
  }

  // =========================================
  // MARK AS READ
  // =========================================

  Future<void> markAsRead(
      int notificationId) async {
    await http.put(
      Uri.parse(
        "$baseUrl/api/notifications/$notificationId/read",
      ),
      headers: {
        "Authorization":
        "Bearer ${AuthService.token}",
      },
    );

    notifyNotificationReceived();
  }

  // =========================================
  // GET UNREAD COUNT
  // =========================================

  Future<int> getUnreadCount() async {
    final response = await http.get(
      Uri.parse(
        "$baseUrl/api/notifications/unread-count",
      ),
      headers: {
        "Authorization":
        "Bearer ${AuthService.token}",
      },
    );

    if (response.statusCode == 200) {
      final data =
      jsonDecode(response.body);

      return data["count"] ?? 0;
    }

    return 0;
  }

  // =========================================
  // SAVE FCM TOKEN
  // =========================================

  Future<void> saveFcmToken(
      String fcmToken) async {
    final response = await http.post(
      Uri.parse(
        "$baseUrl/auth/save-fcm-token",
      ),
      headers: {
        "Content-Type":
        "application/json",
        "Authorization":
        "Bearer ${AuthService.token}",
      },
      body: jsonEncode({
        "fcmToken": fcmToken,
      }),
    );

    print(
      "SAVE FCM STATUS: ${response.statusCode}",
    );

    print(
      "SAVE FCM BODY: ${response.body}",
    );
  }
}