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

  // =========================================
  // FIREBASE INIT
  // =========================================

  await Firebase.initializeApp();

  // =========================================
  // LOCAL + FOREGROUND NOTIFICATIONS
  // =========================================

  await FirebaseMessagingService.initialize();
  NotificationService.initializeRealtimeListeners();

  // =========================================
  // BACKGROUND HANDLER
  // =========================================

  FirebaseMessaging.onBackgroundMessage(
    _firebaseMessagingBackgroundHandler,
  );

  // =========================================
  // LOAD JWT TOKEN
  // =========================================

  await AuthService.loadToken();

  print(
    "APP START TOKEN: ${AuthService.token}",
  );

  // =========================================
  // GET FCM TOKEN
  // =========================================

  String? fcmToken =
  await FirebaseMessaging.instance.getToken();

  print("FCM TOKEN: $fcmToken");

  // =========================================
  // SAVE TOKEN TO BACKEND
  // =========================================

  if (fcmToken != null &&
      AuthService.token != null) {

    await NotificationService()
        .saveFcmToken(fcmToken);
  }

  // =========================================
  // TOKEN REFRESH
  // =========================================

  FirebaseMessaging.instance.onTokenRefresh
      .listen((newToken) async {

    print("NEW FCM TOKEN: $newToken");

    if (AuthService.token != null) {

      await NotificationService()
          .saveFcmToken(newToken);
    }
  });

  // =========================================
  // FOREGROUND LOGS
  // =========================================

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

  // =========================================
  // OPEN APP FROM NOTIFICATION
  // =========================================

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