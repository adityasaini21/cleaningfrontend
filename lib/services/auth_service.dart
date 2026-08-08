import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_client.dart';

class AuthService {
  static String? token;

  final String baseUrl = ApiClient.baseUrl;

  Future<bool> login(
      String phoneNumber,
      String password,
      ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/auth/login"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "phoneNumber": phoneNumber,
        "password": password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      token = data["token"];

      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(
        "jwt_token",
        token!,
      );

      print("LOGIN TOKEN: $token");

      await saveFcmToken();

      return true;
    } else {
      return false;
    }
  }

  static Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();

    token = prefs.getString("jwt_token");

    print("LOADED TOKEN: $token");
  }

  Future<void> logout() async {
    token = null;

    final prefs = await SharedPreferences.getInstance();

    await prefs.remove("jwt_token");
  }

  bool get isLoggedIn => token != null;

  String? getUsernameFromToken() {
    if (token == null) return null;

    try {
      final parts = token!.split('.');

      if (parts.length != 3) return null;

      final payload = parts[1];

      final normalized = base64Url.normalize(payload);

      final decodedBytes = base64Url.decode(normalized);

      final decodedString = utf8.decode(decodedBytes);

      final Map<String, dynamic> data = jsonDecode(decodedString);

      return data["sub"];
    } catch (e) {
      return null;
    }
  }

  String? getRoleFromToken() {
    if (token == null) return null;

    try {
      final parts = token!.split('.');

      if (parts.length != 3) return null;

      final payload = parts[1];

      final normalized = base64Url.normalize(payload);

      final decodedBytes = base64Url.decode(normalized);

      final decodedString = utf8.decode(decodedBytes);

      final Map<String, dynamic> data = jsonDecode(decodedString);

      return data["role"];
    } catch (e) {
      return null;
    }
  }

  bool isAdmin() {
    final role = getRoleFromToken();

    return role == "ROLE_ADMIN" || role == "ADMIN";
  }

  static Future<void> saveFcmToken() async {
    try {
      if (token == null) {
        print("JWT TOKEN NULL");
        return;
      }

      String? fcmToken = await FirebaseMessaging.instance.getToken();

      if (fcmToken == null) {
        print("FCM TOKEN NULL");
        return;
      }

      print("FCM TOKEN: $fcmToken");

      final response = await http.post(
        Uri.parse("${ApiClient.baseUrl}/auth/save-fcm-token"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "fcmToken": fcmToken,
        }),
      );

      print("SAVE FCM STATUS: ${response.statusCode}");
      print("SAVE FCM BODY: ${response.body}");
    } catch (e) {
      print("FCM SAVE ERROR: $e");
    }
  }
}