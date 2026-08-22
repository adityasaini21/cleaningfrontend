import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/api_client.dart';
import '../services/auth_service.dart';
import 'admin_dashboard_screen.dart';
import 'login_screen.dart';
import 'main_navigation_screen.dart';
import 'maintenance_screen.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  late AnimationController _animationController;
  bool _serviceSuspended = false;
  late Future<void> _statusCheckFuture;

  Future<void> _checkServiceStatus() async {
    try {
      final response = await http.get(Uri.parse("${ApiClient.baseUrl}/api/service-status"));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _serviceSuspended = data["suspended"] ?? false;
      }
    } catch (e) {
      debugPrint("Error checking service status: $e");
    }
  }

  // Premium iOS Transitions
  late Animation<double> _textOpacity;
  late Animation<double> _textScale;
  late Animation<double> _loaderOpacity;
  late Animation<double> _progressValue;

  @override
  void initState() {
    super.initState();
    _statusCheckFuture = _checkServiceStatus();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // Text Fade-In (0.0s to 0.9s) using natural 5th-degree deceleration
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutQuint),
      ),
    );

    // Text Scale-In (0.0s to 0.9s) from 93% to 100% size for a smooth iOS springboard feel
    _textScale = Tween<double>(begin: 0.93, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutQuint),
      ),
    );

    // Spinner Fade-In (0.3s to 0.8s) for staggered entrance
    _loaderOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
      ),
    );

    // Custom horizontal progress line expansion (0.3s to 1.7s) with smooth iOS cubic curves
    _progressValue = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 0.95, curve: const Cubic(0.2, 0.8, 0.2, 1.0)),
      ),
    );

    // Timeline Listener to trigger Page Transition at completion
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateToNext();
      }
    });

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _navigateToNext() async {
    if (!mounted) return;

    // Await status check completion before navigating
    await _statusCheckFuture;

    if (!mounted) return;

    final PageRouteBuilder routeBuilder = PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) {
        if (!_authService.isLoggedIn) return const LoginScreen();
        if (_authService.isAdmin()) return const AdminDashboardScreen();
        if (_serviceSuspended) return const MaintenanceScreen();
        return const MainNavigationScreen();
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );

    Navigator.pushReplacement(context, routeBuilder);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark theme matching the app aesthetic
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Animated Text Tagline (Fade + Scale)
                Opacity(
                  opacity: _textOpacity.value,
                  child: Transform.scale(
                    scale: _textScale.value,
                    child: Column(
                      children: [
                        Text(
                          "KEEP IT NU.",
                          style: TextStyle(
                            fontFamily: '.SF Pro Display', // Force iOS native system font rendering
                            fontSize: 18, // Balanced size for uppercase letter spacing
                            fontWeight: FontWeight.w500, // Medium weight
                            letterSpacing: 6.0, // Luxury tracking width
                            color: const Color(0xFFE5E5EA), // Apple Silver-white for smooth contrast
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.25),
                                offset: const Offset(0, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "KEEP IT KLEAN.",
                          style: TextStyle(
                            fontFamily: '.SF Pro Display', // Force iOS native system font rendering
                            fontSize: 18,
                            fontWeight: FontWeight.w800, // Extra bold weight to create high-end design contrast
                            letterSpacing: 6.0, // Matching luxury tracking
                            color: const Color(0xFF0A84FF), // iOS Brand Blue color
                            shadows: [
                              Shadow(
                                color: const Color(0xFF0A84FF).withOpacity(0.15),
                                offset: const Offset(0, 1),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Animated Horizontal Progress Line
                Opacity(
                  opacity: _loaderOpacity.value,
                  child: Container(
                    width: 130, // Proportional scaled width
                    height: 2.0, // Thinner, refined line weight
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2E), // Apple System Gray 4 for premium track depth
                      borderRadius: BorderRadius.circular(1.0),
                    ),
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 130 * _progressValue.value,
                      height: 2.0,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF007AFF), // Deeper luxury blue
                            Color(0xFF0A84FF), // Vivid neon blue
                          ],
                        ),
                        borderRadius: BorderRadius.circular(1.0),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0A84FF).withOpacity(0.35),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
