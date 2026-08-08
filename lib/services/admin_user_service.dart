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
    final response = await http.get(
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

  Future<void> resetPassword(
      int userId,
      String newPassword,
      ) async {
    final response = await http.put(
      Uri.parse(
        "$baseUrl/admin/users/$userId/reset-password",
      ),
      headers: headers,
      body: jsonEncode({
        "newPassword": newPassword,
      }),
    );

    print("RESET PASSWORD STATUS: ${response.statusCode}");
    print("RESET PASSWORD BODY: ${response.body}");

    if (response.statusCode != 200) {
      throw Exception(
        response.body.isNotEmpty
            ? response.body
            : "Failed to reset password",
      );
    }
  }
}