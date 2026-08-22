import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import 'config/api_config.dart';

class ApiClient {
  static String get baseUrl => ApiConfig.baseUrl;

  static final StreamController<void> _maintenanceController =
      StreamController<void>.broadcast();

  static Stream<void> get maintenanceStream =>
      _maintenanceController.stream;

  static void triggerMaintenance() {
    _maintenanceController.add(null);
  }

  static Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    final response = await http.get(url, headers: headers);
    _checkResponse(response);
    return response;
  }

  static Future<http.Response> post(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    final response = await http.post(url, headers: headers, body: body, encoding: encoding);
    _checkResponse(response);
    return response;
  }

  static Future<http.Response> put(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    final response = await http.put(url, headers: headers, body: body, encoding: encoding);
    _checkResponse(response);
    return response;
  }

  static Future<http.Response> delete(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    final response = await http.delete(url, headers: headers, body: body, encoding: encoding);
    _checkResponse(response);
    return response;
  }

  static void _checkResponse(http.Response response) {
    if (response.statusCode == 401 || response.statusCode == 403) {
      AuthService.triggerUnauthorized();
    } else if (response.statusCode == 503) {
      _maintenanceController.add(null);
    }
  }
}