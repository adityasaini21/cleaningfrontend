import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'main_navigation_screen.dart';
import 'register_screen.dart';
import 'admin_dashboard_screen.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController =
  TextEditingController();

  final TextEditingController _passwordController =
  TextEditingController();

  final AuthService _authService = AuthService();

  bool _loading = false;
  bool _obscurePassword = true;

  int _logoTapCount = 0;
  bool _adminLoginMode = false;

  void _handleLogoTap() {
    if (_adminLoginMode) return;

    setState(() {
      _logoTapCount++;
    });

    if (_logoTapCount >= 7) {
      setState(() {
        _adminLoginMode = true;
        _logoTapCount = 0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Admin login enabled"),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _login() async {
    if (_loading) return;

    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    if (phone.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter phone number and password"),
        ),
      );
      return;
    }

    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Enter a valid 10-digit phone number"),
        ),
      );
      return;
    }

    setState(() {
      _loading = true;
    });

    final success = await _authService.login(
      phone,
      password,
    );

    if (!mounted) return;

    setState(() {
      _loading = false;
    });

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Invalid phone number or password"),
        ),
      );
      return;
    }

    if (_adminLoginMode) {
      if (_authService.isAdmin()) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const AdminDashboardScreen(),
          ),
        );
      } else {
        await _authService.logout();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Admin access required"),
          ),
        );
      }

      return;
    }

    if (_authService.isAdmin()) {
      await _authService.logout();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please use the admin login"),
        ),
      );

      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const MainNavigationScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _adminLoginMode ? "Admin Login" : "Login",
        ),
        centerTitle: true,
      ),
      body: Container(
        color: const Color(0xFF000000), // OLED True Black
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Center(
            child: SingleChildScrollView(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 650),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, (1 - value) * 24),
                      child: child,
                    ),
                  );
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: _handleLogoTap,
                      child: Image.asset(
                        'assets/images/logoclean.png',
                        width: 110,
                        height: 110,
                        fit: BoxFit.contain,
                      ),
                    ),

                    const SizedBox(height: 24),

                    Text(
                      _adminLoginMode ? "Admin Login" : "Welcome Back",
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      _adminLoginMode
                          ? "Login to access the admin panel"
                          : "Login to continue",
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF8E8E93), // iOS System Gray
                      ),
                    ),

                    const SizedBox(height: 36),

                    // iOS Grouped List Form Panel
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1C1E), // iOS System Gray 6
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFF2C2C2E),
                          width: 0.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              maxLength: 10,
                              style: const TextStyle(fontSize: 16),
                              decoration: const InputDecoration(
                                labelText: "Phone Number",
                                labelStyle: TextStyle(color: Color(0xFF8E8E93)),
                                prefixIcon: Icon(Icons.phone, color: Color(0xFF8E8E93), size: 22),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                                filled: false,
                                counterText: "",
                              ),
                            ),
                          ),

                          const Divider(
                            height: 1,
                            thickness: 0.5,
                            color: Color(0xFF38383A), // iOS cell divider
                            indent: 16,
                            endIndent: 16,
                          ),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: TextField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              onSubmitted: (_) => _login(),
                              style: const TextStyle(fontSize: 16),
                              decoration: InputDecoration(
                                labelText: "Password",
                                labelStyle: const TextStyle(color: Color(0xFF8E8E93)),
                                prefixIcon: const Icon(Icons.lock, color: Color(0xFF8E8E93), size: 22),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                                filled: false,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: const Color(0xFF8E8E93),
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 36),

                    _loading
                        ? const CircularProgressIndicator()
                        : SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0A84FF), // iOS System Blue
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                _adminLoginMode ? "Admin Login" : "Sign In",
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                    if (!_adminLoginMode) ...[
                      const SizedBox(height: 24),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Don't have an account?",
                            style: TextStyle(color: Color(0xFF8E8E93)),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const RegisterScreen(),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF0A84FF),
                            ),
                            child: const Text("Register"),
                          ),
                        ],
                      ),
                    ],

                    if (_adminLoginMode) ...[
                      const SizedBox(height: 24),

                      TextButton(
                        onPressed: _loading
                            ? null
                            : () {
                                setState(() {
                                  _adminLoginMode = false;
                                  _logoTapCount = 0;
                                  _phoneController.clear();
                                  _passwordController.clear();
                                });
                              },
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF0A84FF),
                        ),
                        child: const Text(
                          "Back to Customer Login",
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}