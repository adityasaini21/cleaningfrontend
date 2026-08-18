import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:device_info_plus/device_info_plus.dart';

class ApiConfig {
  static String _baseUrl = "";

  static String get baseUrl {
    if (_baseUrl.isEmpty) {
      final url = dotenv.env['BASE_URL'];
      if (url == null || url.isEmpty) {
        throw Exception("BASE_URL not found");
      }
      return url;
    }
    return _baseUrl;
  }

  static Future<void> init() async {
    String url = dotenv.env['BASE_URL'] ?? "";
    if (url.isEmpty) {
      throw Exception("BASE_URL not found");
    }

    try {
      if (Platform.isAndroid) {
        final uri = Uri.parse(url);
        final host = uri.host;
        
        final isLocal = host == "localhost" || 
                        host == "127.0.0.1" || 
                        host.startsWith("192.168.") || 
                        host.startsWith("10.0.2.");

        if (isLocal) {
          final deviceInfo = DeviceInfoPlugin();
          final androidInfo = await deviceInfo.androidInfo;
          
          if (!androidInfo.isPhysicalDevice) {
            final newUri = uri.replace(host: "10.0.2.2");
            url = newUri.toString();
            if (url.endsWith("/") && !dotenv.env['BASE_URL']!.endsWith("/")) {
              url = url.substring(0, url.length - 1);
            }
          }
        }
      }
    } catch (e) {
      print("ApiConfig init warning: $e");
    }

    _baseUrl = url;
    print("RESOLVED BASE_URL: $_baseUrl");
  }
}