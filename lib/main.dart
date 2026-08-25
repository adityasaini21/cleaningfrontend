import 'package:firebase_core/firebase_core.dart';

import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:flutter/material.dart';

import 'package:prem_chemicals_app/services/auth_service.dart';

import 'package:prem_chemicals_app/services/firebase_messaging_service.dart';

import 'package:prem_chemicals_app/services/notification_service.dart';

import 'package:provider/provider.dart';

import 'services/cart_provider.dart';

import 'screens/splash_screen.dart';

import 'theme/app_theme.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/config/api_config.dart';

// =========================================
// BACKGROUND MESSAGE HANDLER
// =========================================

Future<void> _firebaseMessagingBackgroundHandler(
    RemoteMessage message) async {

  await Firebase.initializeApp();

  print(
    "BACKGROUND MESSAGE: ${message.notification?.title}",
  );
}

// =========================================
// MAIN
// =========================================

void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  // Load .env
  await dotenv.load(fileName: ".env");

  // Initialize API config (checks for physical device vs emulator)
  await ApiConfig.init();

  // Firebase
  await Firebase.initializeApp();

  // Local + Foreground Notifications
  await FirebaseMessagingService.initialize();
  NotificationService.initializeRealtimeListeners();

  // Background Handler
  FirebaseMessaging.onBackgroundMessage(
    _firebaseMessagingBackgroundHandler,
  );

  // Load JWT Token
  await AuthService.loadToken();

  debugPrint("JWT Token loaded successfully");

  // Get FCM Token
  String? fcmToken =
  await FirebaseMessaging.instance.getToken();

  debugPrint("FCM token initialized");

  // Save Token To Backend
  if (fcmToken != null &&
      AuthService.token != null) {

    await NotificationService()
        .saveFcmToken(fcmToken);
  }

  FirebaseMessaging.instance.onTokenRefresh
      .listen((newToken) async {

    print("NEW FCM TOKEN: $newToken");

    if (AuthService.token != null) {

      await NotificationService()
          .saveFcmToken(newToken);
    }
  });

  FirebaseMessaging.onMessage.listen(
        (RemoteMessage message) {

      print(
        "FOREGROUND TITLE: ${message.notification?.title}",
      );

      print(
        "FOREGROUND BODY: ${message.notification?.body}",
      );
    },
  );

  FirebaseMessaging.onMessageOpenedApp.listen(
        (RemoteMessage message) {

      print(
        "NOTIFICATION CLICKED: ${message.notification?.title}",
      );
    },
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => CartProvider(),
      child: const PremChemicalsApp(),
    ),
  );
}

// =========================================
// APP
// =========================================

class PremChemicalsApp extends StatelessWidget {

  const PremChemicalsApp({super.key});

  @override
  Widget build(BuildContext context) {

    return MaterialApp(

      debugShowCheckedModeBanner: false,

      title: "Prem Chemicals",

      theme: AppTheme.darkTheme,

      home: const SplashScreen(),
    );
  }
}