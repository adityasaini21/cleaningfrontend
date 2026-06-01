import 'dart:async';

import 'package:flutter/material.dart';

import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() =>
      _NotificationScreenState();
}

class _NotificationScreenState
    extends State<NotificationScreen> {

  final NotificationService
  _notificationService =
  NotificationService();

  List<NotificationModel>
  _notifications = [];

  bool _loading = true;

  StreamSubscription?
  _notificationSubscription;

  @override
  void initState() {

    super.initState();

    _loadNotifications();

    // =========================================
    // REALTIME LISTENER
    // =========================================

    _notificationSubscription =
        NotificationService
            .notificationStream
            .listen((_) {

          _loadNotifications();
        });
  }

  @override
  void dispose() {

    _notificationSubscription?.cancel();

    super.dispose();
  }

  // =========================================
  // LOAD NOTIFICATIONS
  // =========================================

  Future<void> _loadNotifications()
  async {

    try {

      final data =
      await _notificationService
          .getMyNotifications();

      if (!mounted) return;

      setState(() {

        _notifications = data;

        _loading = false;
      });

    } catch (e) {

      debugPrint(
        "Notification load error: $e",
      );

      if (!mounted) return;

      setState(() {

        _loading = false;
      });
    }
  }

  // =========================================
  // MARK AS READ
  // =========================================

  Future<void> _markAsRead(
      NotificationModel notification)
  async {

    if (!notification.isRead) {

      await _notificationService
          .markAsRead(notification.id);
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(

        title:
        const Text("Notifications"),
      ),

      body: _loading

          ? const Center(
        child:
        CircularProgressIndicator(),
      )

          : _notifications.isEmpty

          ? const Center(
        child:
        Text("No notifications"),
      )

          : RefreshIndicator(

        onRefresh:
        _loadNotifications,

        child: ListView.builder(

          itemCount:
          _notifications.length,

          itemBuilder:
              (context, index) {

            final n =
            _notifications[index];

            return Card(

              margin:
              const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),

              child: ListTile(

                leading: CircleAvatar(

                  backgroundColor:
                  n.isRead
                      ? Colors.grey
                      : Colors.red,

                  child: const Icon(

                    Icons.notifications,

                    color: Colors.white,
                  ),
                ),

                title: Text(

                  n.title,

                  style: TextStyle(

                    fontWeight:
                    n.isRead
                        ? FontWeight.normal
                        : FontWeight.bold,
                  ),
                ),

                subtitle: Column(

                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,

                  children: [

                    const SizedBox(height: 4),

                    Text(n.message),

                    const SizedBox(height: 6),

                    Text(

                      n.createdAt,

                      style: const TextStyle(

                        fontSize: 12,

                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),

                onTap: () =>
                    _markAsRead(n),
              ),
            );
          },
        ),
      ),
    );
  }
}