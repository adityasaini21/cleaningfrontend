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

    ScaffoldMessenger.of(context).clearSnackBars();

    Timer? dismissTimer;
    final snackBarController = ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          "Alert deleted successfully",
          style: TextStyle(color: Colors.white),
        ),
        duration: const Duration(seconds: 5),
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
            dismissTimer?.cancel();
            setState(() {
              _notifications.insert(index, notification);
            });
          },
        ),
      ),
    );

    // Guaranteed auto-dismiss after exactly 5 seconds even if platform accessibility delays it
    dismissTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        try {
          snackBarController.close();
        } catch (_) {}
      }
    });

    // Wait for the SnackBar to close
    snackBarController.closed.then((reason) async {
      dismissTimer?.cancel();
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
            ScaffoldMessenger.of(context).clearSnackBars();
            final errorController = ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Failed to delete alert from server. Reverted."),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 5),
              ),
            );
            Timer(const Duration(seconds: 5), () {
              if (mounted) {
                try {
                  errorController.close();
                } catch (_) {}
              }
            });
          }
        }
      }
    });
  }

  void _showClearAllConfirmationDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF2C2C2E), width: 0.5),
        ),
        title: const Text(
          "Clear All Alerts",
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Are you sure you want to delete all notifications? This cannot be undone.",
          style: TextStyle(color: Color(0xFF8E8E93), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF453A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _clearAllNotifications();
            },
            child: const Text(
              "Clear All",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllNotifications() async {
    final previousList = List<NotificationModel>.from(_notifications);
    setState(() {
      _notifications.clear();
    });

    try {
      final success = await _notificationService.clearAllNotifications();
      if (!success) throw Exception();

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        final successController = ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              "All alerts cleared successfully",
              style: TextStyle(color: Colors.white),
            ),
            duration: const Duration(seconds: 5),
            backgroundColor: const Color(0xFF1C1C1E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: Color(0xFF2C2C2E), width: 0.5),
            ),
          ),
        );
        Timer(const Duration(seconds: 5), () {
          if (mounted) {
            try {
              successController.close();
            } catch (_) {}
          }
        });
      }
    } catch (e) {
      debugPrint("Clear all notifications error: $e");
      if (mounted) {
        setState(() {
          _notifications = previousList;
        });
        ScaffoldMessenger.of(context).clearSnackBars();
        final errorController = ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to clear alerts from server. Reverted."),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
        Timer(const Duration(seconds: 5), () {
          if (mounted) {
            try {
              errorController.close();
            } catch (_) {}
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Notifications"),
        actions: [
          if (_notifications.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: _showClearAllConfirmationDialog,
                icon: const Icon(
                  Icons.delete_sweep_outlined,
                  size: 18,
                  color: Color(0xFFFF453A),
                ),
                label: const Text(
                  "Clear All",
                  style: TextStyle(
                    color: Color(0xFFFF453A),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),

      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _notifications.isEmpty
              ? const Center(
                  child: Text("No notifications"),
                )
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 850),
                    child: Column(
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
                                            color: n.isRead ? const Color(0x338E8E93) : const Color(0xFFFF453A),
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
              ),
            ),
    );
  }
}