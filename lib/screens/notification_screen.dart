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

  void _markAsRead(NotificationModel notification) {
    if (notification.isRead) return;

    setState(() {
      notification.isRead = true;
    });

    _notificationService.markAsRead(notification.id).catchError((e) {
      debugPrint("Notification read error: $e");
      setState(() {
        notification.isRead = false;
      });
    });
  }

  Future<void> _deleteNotification(NotificationModel notification, int index) async {
    setState(() {
      _notifications.removeAt(index);
    });

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    final snackBarController = ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          "Alert deleted successfully",
          style: TextStyle(color: Colors.white),
        ),
        duration: const Duration(seconds: 4),
        backgroundColor: const Color(0xFF1C1C1E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Color(0xFF2C2C2E), width: 0.5),
        ),
        action: SnackBarAction(
          label: "Undo",
          textColor: const Color(0xFF0A84FF), // iOS System Blue
          onPressed: () {
            setState(() {
              _notifications.insert(index, notification);
            });
          },
        ),
      ),
    );

    // Wait for the SnackBar to close
    snackBarController.closed.then((reason) async {
      if (reason != SnackBarClosedReason.action) {
        // User did not click Undo - execute database deletion
        try {
          final success = await _notificationService.deleteNotification(notification.id);
          if (!success) throw Exception();
        } catch (e) {
          debugPrint("Delete notification error: $e");
          if (mounted) {
            setState(() {
              if (!_notifications.contains(notification)) {
                _notifications.insert(index, notification);
              }
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Failed to delete alert from server. Reverted."),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    });
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
              child: CircularProgressIndicator(),
            )
          : _notifications.isEmpty
              ? const Center(
                  child: Text("No notifications"),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 14,
                            color: Color(0xFF8E8E93),
                          ),
                          SizedBox(width: 6),
                          Text(
                            "Swipe left on an alert to delete it",
                            style: TextStyle(
                              color: Color(0xFF8E8E93),
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadNotifications,
                        child: ListView.builder(
                          itemCount: _notifications.length,
                          itemBuilder: (context, index) {
                            final n = _notifications[index];

                            return Dismissible(
                              key: Key(n.id.toString()),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF453A), // iOS system red
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              onDismissed: (direction) {
                                _deleteNotification(n, index);
                              },
                              child: GestureDetector(
                                onTap: () => _markAsRead(n),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1C1C1E),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFF2C2C2E), width: 0.5),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Compact circular status icon background (red when unread, grey when read)
                                      Padding(
                                        padding: const EdgeInsets.only(right: 10),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: n.isRead ? Colors.grey.withOpacity(0.2) : const Color(0xFFFF453A),
                                          ),
                                          child: const Icon(
                                            Icons.notifications,
                                            size: 12,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              n.title,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              n.message,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.white70,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              n.createdAt,
                                              style: const TextStyle(
                                                fontSize: 9,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}