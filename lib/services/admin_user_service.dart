import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/api_client.dart';
import '../models/admin_user.dart';
import 'auth_service.dart';

class AdminUserService {
  final String baseUrl = ApiClient.baseUrl;

  Map<String, String> get headers => {
    "Content-Type": "application/json",
    "Authorization": "Bearer ${AuthService.token}",
  };

  Future<List<AdminUser>> searchUsers(String query) async {
    final response = await ApiClient.get(
      Uri.parse(
        "$baseUrl/admin/users/search?query=${Uri.encodeQueryComponent(query)}",
      ),
      headers: headers,
    );

    print("ADMIN USERS STATUS: ${response.statusCode}");
    print("ADMIN USERS BODY: ${response.body}");

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);

      return data
          .map(
            (json) => AdminUser.fromJson(
          json as Map<String, dynamic>,
        ),
      )
          .toList();
    }

    if (response.statusCode == 401 ||
        response.statusCode == 403) {
      throw Exception("Admin authorization failed");
    }

    throw Exception("Failed to load users");
  }

  Future<AdminUser> toggleUserStatus(int userId) async {
    final response = await ApiClient.put(
      Uri.parse(
        "$baseUrl/admin/users/$userId/toggle-status",
      ),
      headers: headers,
      body: jsonEncode({}),
    );

    print("TOGGLE USER STATUS: ${response.statusCode}");
    print("TOGGLE USER BODY: ${response.body}");

    if (response.statusCode == 200) {
      return AdminUser.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    String errorMsg = "Failed to toggle user status";
    try {
      if (response.body.isNotEmpty) {
        final errJson = jsonDecode(response.body);
        if (errJson is Map && errJson.containsKey("error")) {
          errorMsg = errJson["error"].toString();
        } else if (errJson is Map && errJson.containsKey("message")) {
          errorMsg = errJson["message"].toString();
        } else {
          errorMsg = response.body;
        }
      }
    } catch (_) {
      if (response.body.isNotEmpty) {
        errorMsg = response.body;
      }
    }

    throw Exception(errorMsg);
  }

  Future<void> clearBlockedUsers() async {
    final response = await ApiClient.delete(
      Uri.parse("$baseUrl/admin/users/clear-blocked"),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to clear blocked users");
    }
  }
}