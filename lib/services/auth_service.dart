import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:http/http.dart' as http;

import 'package:shared_preferences/shared_preferences.dart';

class AuthService {

  static String? token;

  final String baseUrl = "http://10.0.2.2:8080";

  // =========================================
  // LOGIN
  // =========================================

  Future<bool> login(
      String username,
      String password,
      ) async {

    final response = await http.post(

      Uri.parse("$baseUrl/auth/login"),

      headers: {

        "Content-Type": "application/json"
      },

      body: jsonEncode({

        "username": username,

        "password": password,
      }),
    );

    if (response.statusCode == 200) {

      final data = jsonDecode(response.body);

      token = data["token"];

      final prefs =
      await SharedPreferences.getInstance();

      await prefs.setString(
        "jwt_token",
        token!,
      );

      print("LOGIN TOKEN: $token");

      // =========================================
      // 🔥 SAVE FCM TOKEN
      // =========================================

      await saveFcmToken();

      return true;

    } else {

      return false;
    }
  }

  // =========================================
  // LOAD TOKEN
  // =========================================

  static Future<void> loadToken() async {

    final prefs =
    await SharedPreferences.getInstance();

    token = prefs.getString("jwt_token");

    print("LOADED TOKEN: $token");
  }

  // =========================================
  // LOGOUT
  // =========================================

  Future<void> logout() async {

    token = null;

    final prefs =
    await SharedPreferences.getInstance();

    await prefs.remove("jwt_token");
  }

  // =========================================
  // CHECK LOGIN
  // =========================================

  bool get isLoggedIn => token != null;

  // =========================================
  // GET USERNAME
  // =========================================

  String? getUsernameFromToken() {

    if (token == null) return null;

    try {

      final parts = token!.split('.');

      if (parts.length != 3) return null;

      final payload = parts[1];

      final normalized =
      base64Url.normalize(payload);

      final decodedBytes =
      base64Url.decode(normalized);

      final decodedString =
      utf8.decode(decodedBytes);

      final Map<String, dynamic> data =
      jsonDecode(decodedString);

      return data["sub"];

    } catch (e) {

      return null;
    }
  }

  // =========================================
  // GET ROLE
  // =========================================

  String? getRoleFromToken() {

    if (token == null) return null;

    try {

      final parts = token!.split('.');

      if (parts.length != 3) return null;

      final payload = parts[1];

      final normalized =
      base64Url.normalize(payload);

      final decodedBytes =
      base64Url.decode(normalized);

      final decodedString =
      utf8.decode(decodedBytes);

      final Map<String, dynamic> data =
      jsonDecode(decodedString);

      return data["role"];

    } catch (e) {

      return null;
    }
  }

  // =========================================
  // ADMIN CHECK
  // =========================================

  bool isAdmin() {

    final role = getRoleFromToken();

    return role == "ROLE_ADMIN"
        || role == "ADMIN";
  }

  // =========================================
  // 🔥 SAVE FCM TOKEN
  // =========================================

  static Future<void> saveFcmToken() async {

    try {

      if (token == null) {
        print("JWT TOKEN NULL");
        return;
      }

      String? fcmToken =
      await FirebaseMessaging.instance.getToken();

      if (fcmToken == null) {
        print("FCM TOKEN NULL");
        return;
      }

      print("FCM TOKEN: $fcmToken");

      final response = await http.post(

        Uri.parse(
          "http://10.0.2.2:8080/auth/save-fcm-token",
        ),

        headers: {

          "Content-Type": "application/json",

          "Authorization":
          "Bearer $token",
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

    } catch (e) {

      print("FCM SAVE ERROR: $e");
    }
  }
}