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
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _handleLogoTap,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.card,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF2C2C2E),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withOpacity(0.15),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(40),
                      child: Image.asset(
                        'assets/images/tt.png',
                        width: 80,
                        height: 80,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  _adminLoginMode ? "Admin Login" : "Welcome Back",
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  _adminLoginMode
                      ? "Login to access the admin panel"
                      : "Login to continue",
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppTheme.textSecondary,
                  ),
                ),

                const SizedBox(height: 32),

                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  decoration: const InputDecoration(
                    labelText: "Phone Number",
                    counterText: "",
                    prefixIcon: Icon(Icons.phone),
                  ),
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  onSubmitted: (_) => _login(),
                  decoration: InputDecoration(
                    labelText: "Password",
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                _loading
                    ? const CircularProgressIndicator()
                    : Container(
                        width: double.infinity,
                        height: 55,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withOpacity(0.25),
                              blurRadius: 15,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            _adminLoginMode ? "Admin Login" : "Login",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                if (!_adminLoginMode) ...[
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account?",
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                              const RegisterScreen(),
                            ),
                          );
                        },
                        child: const Text("Register"),
                      ),
                    ],
                  ),
                ],

                if (_adminLoginMode) ...[
                  const SizedBox(height: 20),

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
    );
  }
}