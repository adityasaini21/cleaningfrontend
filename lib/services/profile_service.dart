import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_client.dart';
import '../models/user_profile.dart';
import 'auth_service.dart';

class ProfileService {
  final String baseUrl = ApiClient.baseUrl;

  Map<String, String> get _headers => {
        "Content-Type": "application/json",
        "Authorization": "Bearer ${AuthService.token}",
      };

  Future<UserProfile?> fetchProfile() async {
    try {
      final response = await ApiClient.get(
        Uri.parse("$baseUrl/auth/profile"),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return UserProfile.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      print("ERROR FETCHING PROFILE: $e");
    }
    return null;
  }

  Future<bool> updateProfile(UserProfile profile) async {
    try {
      final response = await ApiClient.put(
        Uri.parse("$baseUrl/auth/profile"),
        headers: _headers,
        body: jsonEncode(profile.toJson()),
      );

      return response.statusCode == 200;
    } catch (e) {
      print("ERROR UPDATING PROFILE: $e");
      return false;
    }
  }

  Future<String?> changePassword(String oldPassword, String newPassword) async {
    try {
      final response = await ApiClient.put(
        Uri.parse("$baseUrl/auth/change-password"),
        headers: _headers,
        body: jsonEncode({
          "oldPassword": oldPassword,
          "newPassword": newPassword,
        }),
      );

      if (response.statusCode == 200) {
        return null; // success
      } else {
        return response.body.trim().isNotEmpty ? response.body.trim() : "Failed to change password";
      }
    } catch (e) {
      print("ERROR CHANGING PASSWORD: $e");
      return e.toString();
    }
  }

  Future<bool> deleteAccount() async {
    try {
      final response = await ApiClient.delete(
        Uri.parse("$baseUrl/auth/delete-account"),
        headers: _headers,
      );

      return response.statusCode == 200;
    } catch (e) {
      print("ERROR DELETING ACCOUNT: $e");
      return false;
    }
  }
}
