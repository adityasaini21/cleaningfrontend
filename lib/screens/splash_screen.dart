import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'admin_dashboard_screen.dart';
import 'login_screen.dart';
import 'main_navigation_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  late AnimationController _timelineController;

  // Phase 1 Animations (0.0s - 1.0s) -> [0.0 - 0.33]
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  // Phase 2 Animations (1.0s - 2.0s) -> [0.33 - 0.66]
  late Animation<double> _pulseAnimation;
  late Animation<double> _shiftAnimation;
  late Animation<double> _rippleScale;
  late Animation<double> _rippleOpacity;

  // Phase 3 Animations (2.0s - 2.8s) -> [0.66 - 0.93]
  late Animation<double> _zoomScaleAnimation;
  late Animation<double> _zoomFadeAnimation;

  bool _hasTransitioned = false;

  @override
  void initState() {
    super.initState();

    // 3.0 Seconds Total Timeline Duration
    _timelineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    // ==========================================
    // PHASE 1: The Materialization (0.0s – 1.0s)
    // ==========================================
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _timelineController,
        curve: const Interval(0.0, 0.33, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _timelineController,
        curve: const Interval(0.0, 0.33, curve: Curves.easeOutCubic),
      ),
    );

    // ==========================================
    // PHASE 2: Core Interaction (1.0s – 2.0s)
    // ==========================================
    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.04).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.04, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _timelineController,
        curve: const Interval(0.33, 0.66),
      ),
    );

    // Parallax depth shift to emphasize three-dimensionality of layers
    _shiftAnimation = Tween<double>(begin: 0.0, end: 5.0).animate(
      CurvedAnimation(
        parent: _timelineController,
        curve: const Interval(0.33, 0.50, curve: Curves.easeOut),
      ),
    );

    // Central circular ripple wave
    _rippleScale = Tween<double>(begin: 1.0, end: 1.65).animate(
      CurvedAnimation(
        parent: _timelineController,
        curve: const Interval(0.33, 0.55, curve: Curves.easeOut),
      ),
    );

    _rippleOpacity = Tween<double>(begin: 0.75, end: 0.0).animate(
      CurvedAnimation(
        parent: _timelineController,
        curve: const Interval(0.33, 0.55, curve: Curves.easeOut),
      ),
    );

    // ==========================================
    // PHASE 3: Portal Shift (2.0s – 2.8s)
    // ==========================================
    _zoomScaleAnimation = Tween<double>(begin: 1.0, end: 20.0).animate(
      CurvedAnimation(
        parent: _timelineController,
        curve: const Interval(0.66, 0.93, curve: Cubic(0.2, 0.8, 0.2, 1.0)), // iOS-smooth acceleration
      ),
    );

    _zoomFadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _timelineController,
        curve: const Interval(0.66, 0.93, curve: Curves.easeOutCubic),
      ),
    );

    // Timeline Listener to trigger Handoff at exactly 2.8 seconds (progress 0.93)
    _timelineController.addListener(() {
      if (_timelineController.value >= 0.93 && !_hasTransitioned) {
        _triggerHandoff();
      }
    });

    _timelineController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pre-cache logo image before build passes to prevent blank frames on start
    precacheImage(const AssetImage('assets/images/logoclean.png'), context);
  }

  @override
  void dispose() {
    _timelineController.dispose();
    super.dispose();
  }

  // ==========================================
  // PHASE 4: Handoff (2.8s – 3.0s)
  // ==========================================
  void _triggerHandoff() {
    if (_hasTransitioned) return;
    _hasTransitioned = true;

    // Transition with absolute zero white flash
    final PageRouteBuilder routeBuilder = PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) {
        if (!_authService.isLoggedIn) return const LoginScreen();
        if (_authService.isAdmin()) return const AdminDashboardScreen();
        return const MainNavigationScreen();
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 200),
    );

    Navigator.pushReplacement(context, routeBuilder);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Deep jet-black (#000000)
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Phase 2: Rhythmic Central Ripple
          AnimatedBuilder(
            animation: _timelineController,
            builder: (context, child) {
              final double progressVal = _timelineController.value;
              if (progressVal < 0.33 || progressVal > 0.55) return const SizedBox.shrink();

              return Opacity(
                opacity: _rippleOpacity.value,
                child: Transform.scale(
                  scale: _rippleScale.value,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF0A84FF).withOpacity(0.75),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Perfectly Centered Logo with dynamic scale, opacity, and offset shifts
          Center(
            child: AnimatedBuilder(
              animation: _timelineController,
              builder: (context, child) {
                final double progress = _timelineController.value;

                double currentScale = 1.0;
                double currentOpacity = 1.0;
                double currentShift = 0.0;

                if (progress < 0.33) {
                  // Phase 1: Materialization scale & fade-in
                  currentScale = _scaleAnimation.value;
                  currentOpacity = _fadeAnimation.value;
                  currentShift = 0.0;
                } else if (progress < 0.66) {
                  // Phase 2: Pulsate & 3D Parallax shift
                  currentScale = _pulseAnimation.value;
                  currentOpacity = 1.0;
                  currentShift = _shiftAnimation.value;
                } else {
                  // Phase 3 & 4: Zoom-through & Zoom-fade
                  currentScale = _zoomScaleAnimation.value;
                  currentOpacity = _zoomFadeAnimation.value;
                  currentShift = _shiftAnimation.value;
                }

                if (currentOpacity <= 0.0) {
                  return const SizedBox.shrink();
                }

                return Opacity(
                  opacity: currentOpacity,
                  child: Transform.scale(
                    scale: currentScale,
                    child: RepaintBoundary(
                      child: progress < 0.66
                          ? Stack(
                              alignment: Alignment.center,
                              children: [
                                // Parallax Background Layer (simulates depth underneath white frame)
                                Transform.translate(
                                  offset: Offset(currentShift, currentShift),
                                  child: ShaderMask(
                                    shaderCallback: (bounds) => const LinearGradient(
                                      colors: [Color(0xFF0A84FF), Color(0xFF00E676)],
                                    ).createShader(bounds),
                                    blendMode: BlendMode.srcIn,
                                    child: Image.asset(
                                      'assets/images/logoclean.png',
                                      width: 155,
                                      height: 155,
                                      fit: BoxFit.contain,
                                      filterQuality: FilterQuality.low, // Performance optimization
                                    ),
                                  ),
                                ),

                                // Main Foreground Layer
                                Transform.translate(
                                  offset: Offset(-currentShift, -currentShift),
                                  child: Image.asset(
                                    'assets/images/logoclean.png',
                                    width: 155,
                                    height: 155,
                                    fit: BoxFit.contain,
                                    filterQuality: FilterQuality.low, // Performance optimization
                                  ),
                                ),
                              ],
                            )
                          : Image.asset(
                              'assets/images/logoclean.png',
                              width: 155,
                              height: 155,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.low, // Performance optimization
                            ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}