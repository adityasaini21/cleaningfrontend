import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_client.dart';

import '../services/auth_service.dart';
import '../services/admin_user_service.dart';
import '../services/product_service.dart';
import '../services/order_history_service.dart';
import '../services/notification_service.dart';

import 'login_screen.dart';
import 'admin_users_screen.dart';
import 'admin_orders_screen.dart';
import 'product_list_screen.dart';
import 'notification_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState
    extends State<AdminDashboardScreen> {

  final AuthService _authService = AuthService();

  int _newUsersCount = 0;
  int _newProductsCount = 0;
  int _newOrdersCount = 0;
  int _newNotificationsCount = 0;

  List<String> _currentFetchedUserIds = [];
  List<String> _currentFetchedProductIds = [];

  StreamSubscription? _notificationSubscription;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _fetchDashboardBadges();
    _fetchServiceStatus();

    // Listen to real-time events to update dashboard badges instantly
    _notificationSubscription = NotificationService.notificationStream.listen((_) {
      _fetchDashboardBadges();
      _fetchServiceStatus();
    });

    // Periodic reload every 60 seconds to check for updates (cost optimized for Railway)
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      _fetchDashboardBadges();
      _fetchServiceStatus();
    });
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchDashboardBadges() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 1. Fetch Users
      final users = await AdminUserService().searchUsers("");
      final List<String> fetchedUserIds = users.map((u) => u.id.toString()).toList();
      if (!prefs.containsKey('seen_user_ids')) {
        await prefs.setStringList('seen_user_ids', fetchedUserIds);
      }
      final List<String> seenUserIds = prefs.getStringList('seen_user_ids') ?? [];
      final usersCount = users.where((u) => !seenUserIds.contains(u.id.toString())).length;

      // 2. Fetch Products (Using unpaged fetch for 100% accuracy)
      final products = await ProductService().fetchProductsAll();
      final List<String> fetchedProductIds = products.map((p) => p.id.toString()).toList();
      if (!prefs.containsKey('seen_product_ids')) {
        await prefs.setStringList('seen_product_ids', fetchedProductIds);
      }
      final List<String> seenProductIds = prefs.getStringList('seen_product_ids') ?? [];
      final productsCount = products.where((p) => !seenProductIds.contains(p.id.toString())).length;

      // 3. Fetch Orders - count orders in "CREATED" or "CONFIRMED" status
      final orders = await OrderHistoryService().fetchAllOrders();
      final ordersCount = orders.where((o) => o.orderStatus == "CREATED" || o.orderStatus == "CONFIRMED").length;

      // 4. Fetch Unread Notifications
      final notificationsCount = await NotificationService().getUnreadCount();

      if (!mounted) return;
      setState(() {
        _currentFetchedUserIds = fetchedUserIds;
        _currentFetchedProductIds = fetchedProductIds;

        _newUsersCount = usersCount;
        _newProductsCount = productsCount;
        _newOrdersCount = ordersCount;
        _newNotificationsCount = notificationsCount;
      });
    } catch (e) {
      debugPrint("Error loading dashboard counts: $e");
    }
  }

  Future<void> _logout() async {
    await _authService.logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
          (route) => false,
    );
  }

  bool _serviceSuspended = false;

  Future<void> _fetchServiceStatus() async {
    try {
      final response = await http.get(
        Uri.parse("${ApiClient.baseUrl}/api/service-status"),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _serviceSuspended = data["suspended"] ?? false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching service status: $e");
    }
  }

  Future<void> _toggleServiceStatus(bool suspend) async {
    setState(() {
      _serviceSuspended = suspend;
    });

    try {
      final response = await http.post(
        Uri.parse("${ApiClient.baseUrl}/admin/service-status?suspended=$suspend"),
        headers: {
          "Authorization": "Bearer ${AuthService.token}",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _serviceSuspended = data["suspended"] ?? false;
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(suspend
                ? "Service has been suspended successfully."
                : "Service is now active and accepting orders."),
            backgroundColor: suspend ? Colors.red : Colors.green,
          ),
        );
      } else {
        throw Exception("Failed to update status");
      }
    } catch (e) {
      debugPrint("Error toggling service status: $e");
      if (mounted) {
        setState(() {
          _serviceSuspended = !suspend; // Revert switch state
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to update service status")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Panel"),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              "Welcome, Admin",
              style: TextStyle(
                fontSize: 24, // Matches target screen header proportions
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              "Manage your Prem Chemicals business",
              style: TextStyle(
                fontSize: 14, // Matches target body subtext proportions
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 24),

            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,

              children: [

                _buildAdminCard(
                  icon: Icons.people,
                  title: "Users",
                  badgeCount: _newUsersCount,
                  onTap: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setStringList('seen_user_ids', _currentFetchedUserIds);
                    setState(() {
                      _newUsersCount = 0;
                    });
                    if (!mounted) return;
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminUsersScreen(),
                      ),
                    );
                    _fetchDashboardBadges();
                  },
                ),

                _buildAdminCard(
                  icon: Icons.inventory_2,
                  title: "Products",
                  badgeCount: _newProductsCount,
                  onTap: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setStringList('seen_product_ids', _currentFetchedProductIds);
                    setState(() {
                      _newProductsCount = 0;
                    });
                    if (!mounted) return;
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductListScreen(
                          onCartTap: () {},
                          isOpenedFromAdminDashboard: true,
                        ),
                      ),
                    );
                    _fetchDashboardBadges();
                  },
                ),

                _buildAdminCard(
                  icon: Icons.shopping_cart,
                  title: "Orders",
                  badgeCount: _newOrdersCount,
                  onTap: () async {
                    if (!mounted) return;
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminOrdersScreen(),
                      ),
                    );
                    _fetchDashboardBadges();
                  },
                ),

                _buildAdminCard(
                  icon: Icons.notifications,
                  title: "Notifications",
                  badgeCount: _newNotificationsCount,
                  onTap: () async {
                    if (!mounted) return;
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationScreen(),
                      ),
                    );
                    _fetchDashboardBadges();
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _serviceSuspended
                            ? Colors.red.withOpacity(0.1)
                            : Colors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _serviceSuspended ? Icons.pause_circle_filled : Icons.play_circle_filled,
                        color: _serviceSuspended ? Colors.red : Colors.green,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "App Service Status",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _serviceSuspended
                                ? "Service Suspended (Maintenance)"
                                : "Service Active (Accepting Orders)",
                            style: TextStyle(
                              fontSize: 12,
                              color: _serviceSuspended ? Colors.redAccent : Colors.greenAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: !_serviceSuspended,
                      activeColor: Colors.green,
                      inactiveThumbColor: Colors.red,
                      inactiveTrackColor: Colors.red.withOpacity(0.3),
                      onChanged: (val) {
                        _toggleServiceStatus(!val);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    return Card(
      elevation: 0, // Inherits the premium 0-elevation and 0.5px border styling from AppTheme

      child: InkWell(
        onTap: onTap,

        borderRadius: BorderRadius.circular(14), // Matches CardTheme boundary rounding

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [

            badgeCount > 0
                ? Badge(
                    label: Text(badgeCount.toString()),
                    child: Icon(
                      icon,
                      size: 40,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  )
                : Icon(
                    icon,
                    size: 40,
                    color: Theme.of(context).colorScheme.primary,
                  ),

            const SizedBox(height: 10),

            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}