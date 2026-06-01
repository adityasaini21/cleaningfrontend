import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

import '../services/auth_service.dart';
import '../services/notification_service.dart';

import 'product_list_screen.dart';
import 'cart_screen.dart';
import 'order_history_screen.dart';
import 'profile_screen.dart';
import 'admin_orders_screen.dart';
import 'notification_screen.dart';

class MainNavigationScreen extends StatefulWidget {

  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState
    extends State<MainNavigationScreen> {

  int _currentIndex = 0;

  bool _isAdmin = false;

  int _unreadCount = 0;

  final NotificationService
  _notificationService =
  NotificationService();

  StreamSubscription?
  _notificationSubscription;

  @override
  void initState() {

    super.initState();

    _checkAdmin();

    _loadUnreadCount();

    // =========================================
    // REALTIME LISTENER
    // =========================================

    _notificationSubscription =
        NotificationService
            .notificationStream
            .listen((_) {

          _loadUnreadCount();
        });
  }

  @override
  void dispose() {

    _notificationSubscription?.cancel();

    super.dispose();
  }

  // =========================================
  // LOAD UNREAD COUNT
  // =========================================

  Future<void> _loadUnreadCount() async {

    try {

      final count =
      await _notificationService
          .getUnreadCount();

      if (!mounted) return;

      setState(() {

        _unreadCount = count;
      });

    } catch (e) {

      debugPrint(
        "Unread count error: $e",
      );
    }
  }

  // =========================================
  // CHECK ADMIN ROLE
  // =========================================

  void _checkAdmin() {

    final token = AuthService.token;

    if (token == null) return;

    try {

      final parts = token.split('.');

      if (parts.length != 3) return;

      final payload =
      utf8.decode(
        base64Url.decode(
          base64Url.normalize(parts[1]),
        ),
      );

      final data = jsonDecode(payload);

      final role = data['role'];

      if (role == "ADMIN" ||
          role == "ROLE_ADMIN") {

        setState(() {

          _isAdmin = true;
        });
      }

    } catch (e) {

      debugPrint(
        "JWT parse error: $e",
      );
    }
  }

  // =========================================
  // CHANGE TAB
  // =========================================

  void _changeTab(int index) {

    setState(() {

      _currentIndex = index;
    });

    final notificationTabIndex =
    _isAdmin ? 2 : 3;

    if (index == notificationTabIndex) {

      _loadUnreadCount();
    }
  }

  // =========================================
  // NOTIFICATION ICON WITH BADGE
  // =========================================

  Widget _notificationIcon() {

    return Stack(

      clipBehavior: Clip.none,

      children: [

        const Icon(Icons.notifications),

        if (_unreadCount > 0)

          Positioned(

            right: -6,
            top: -6,

            child: Container(

              padding:
              const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 3,
              ),

              decoration: BoxDecoration(

                gradient: const LinearGradient(

                  colors: [

                    Color(0xFFFF5F6D),
                    Color(0xFFFFC371),
                  ],
                ),

                borderRadius:
                BorderRadius.circular(20),

                boxShadow: [

                  BoxShadow(

                    color: Colors.red
                        .withOpacity(0.35),

                    blurRadius: 10,

                    offset:
                    const Offset(0, 4),
                  ),
                ],
              ),

              constraints:
              const BoxConstraints(

                minWidth: 20,
                minHeight: 20,
              ),

              child: Text(

                _unreadCount > 99
                    ? "99+"
                    : _unreadCount.toString(),

                textAlign: TextAlign.center,

                style: const TextStyle(

                  color: Colors.white,

                  fontSize: 10,

                  fontWeight:
                  FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {

    final userScreens = [

      ProductListScreen(
        onCartTap: () => _changeTab(1),
      ),

      const CartScreen(),

      const OrderHistoryScreen(),

      const NotificationScreen(),

      ProfileScreen(
        onOrdersTap: () => _changeTab(2),
      ),
    ];

    final adminScreens = [

      ProductListScreen(
        onCartTap: () {},
      ),

      const AdminOrdersScreen(),

      const NotificationScreen(),

      ProfileScreen(
        onOrdersTap: () {},
      ),
    ];

    final userItems = [

      SalomonBottomBarItem(

        icon: const Icon(Icons.storefront),

        title: const Text("Products"),

        selectedColor:
        const Color(0xFF4F46E5),
      ),

      SalomonBottomBarItem(

        icon: const Icon(Icons.shopping_bag),

        title: const Text("Cart"),

        selectedColor:
        const Color(0xFF10B981),
      ),

      SalomonBottomBarItem(

        icon:
        const Icon(Icons.receipt_long),

        title: const Text("Orders"),

        selectedColor:
        const Color(0xFFF59E0B),
      ),

      SalomonBottomBarItem(

        icon: _notificationIcon(),

        title: const Text("Alerts"),

        selectedColor:
        const Color(0xFFEF4444),
      ),

      SalomonBottomBarItem(

        icon: const Icon(Icons.person),

        title: const Text("Profile"),

        selectedColor:
        const Color(0xFF8B5CF6),
      ),
    ];

    final adminItems = [

      SalomonBottomBarItem(

        icon: const Icon(Icons.storefront),

        title: const Text("Products"),

        selectedColor:
        const Color(0xFF4F46E5),
      ),

      SalomonBottomBarItem(

        icon: const Icon(
          Icons.admin_panel_settings,
        ),

        title: const Text("Orders"),

        selectedColor:
        const Color(0xFFF59E0B),
      ),

      SalomonBottomBarItem(

        icon: _notificationIcon(),

        title: const Text("Alerts"),

        selectedColor:
        const Color(0xFFEF4444),
      ),

      SalomonBottomBarItem(

        icon: const Icon(Icons.person),

        title: const Text("Profile"),

        selectedColor:
        const Color(0xFF8B5CF6),
      ),
    ];

    return Scaffold(

      extendBody: true,

      body: AnimatedSwitcher(

        duration:
        const Duration(milliseconds: 350),

        child: _isAdmin
            ? adminScreens[_currentIndex]
            : userScreens[_currentIndex],
      ),

      // =========================================
      // PREMIUM FLOATING NAVBAR
      // =========================================

      bottomNavigationBar: SafeArea(

        child: Padding(

          padding: const EdgeInsets.only(

            left: 18,
            right: 18,
            bottom: 14,
          ),

          child: ClipRRect(

            borderRadius:
            BorderRadius.circular(30),

            child: BackdropFilter(

              filter: ImageFilter.blur(

                sigmaX: 30,
                sigmaY: 30,
              ),

              child: Container(

                height: 78,

                decoration: BoxDecoration(

                  gradient: LinearGradient(

                    colors: [

                      Colors.white.withOpacity(0.12),

                      Colors.white.withOpacity(0.06),
                    ],

                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),

                  borderRadius:
                  BorderRadius.circular(30),

                  border: Border.all(

                    color:
                    Colors.white.withOpacity(0.10),

                    width: 1,
                  ),

                  boxShadow: [

                    BoxShadow(

                      color: Colors.black
                          .withOpacity(0.25),

                      blurRadius: 30,

                      offset:
                      const Offset(0, 15),
                    ),

                    BoxShadow(

                      color: Colors.blue
                          .withOpacity(0.08),

                      blurRadius: 40,
                    ),
                  ],
                ),

                child: Theme(

                  data: Theme.of(context).copyWith(

                    splashColor:
                    Colors.transparent,

                    highlightColor:
                    Colors.transparent,
                  ),

                  child: SalomonBottomBar(

                    currentIndex:
                    _currentIndex,

                    onTap: _changeTab,

                    margin:
                    const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 10,
                    ),

                    itemPadding:
                    const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),

                    duration:
                    const Duration(
                      milliseconds: 300,
                    ),

                    curve:
                    Curves.easeInOut,

                    items:
                    _isAdmin
                        ? adminItems
                        : userItems,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}