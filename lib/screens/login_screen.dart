import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'main_navigation_screen.dart';
import 'register_screen.dart';
import 'admin_dashboard_screen.dart';
import '../theme/app_theme.dart';
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_client.dart';
import 'package:url_launcher/url_launcher.dart';

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

  bool _otpSent = false;
  bool _isNewUser = false;
  bool _sendingOtp = false;
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();

  Timer? _resendTimer;
  int _resendCountdown = 60;
  bool _canResend = false;

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

    if (_adminLoginMode) {
      // Standard password login ONLY for admins
      final phone = _phoneController.text.trim();
      final password = _passwordController.text;

      if (phone.isEmpty || password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter phone number and password")),
        );
        return;
      }

      setState(() => _loading = true);

      final success = await _authService.login(phone, password);

      if (!mounted) return;
      setState(() => _loading = false);

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid phone number or password")),
        );
        return;
      }

      if (_authService.isAdmin()) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Access Denied: Not an admin")),
        );
        _authService.logout();
      }
      return;
    }

    // Normal customer:
    if (!_otpSent) {
      // Step 1: Send OTP
      _checkAndSendOtp();
    } else {
      // Step 2: Verify and login/register
      _loginOrRegisterWithOtp();
    }
  }

  Future<void> _checkAndSendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || !RegExp(r'^[6-9]\d{9}$').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid 10-digit mobile number")),
      );
      return;
    }

    setState(() {
      _sendingOtp = true;
    });

    try {
      // 1. Check if user exists
      final checkRes = await ApiClient.get(
        Uri.parse("${ApiClient.baseUrl}/auth/check-phone?phoneNumber=$phone"),
      );

      if (checkRes.statusCode == 200) {
        final checkData = jsonDecode(checkRes.body);
        final bool exists = checkData["exists"] ?? false;

        setState(() {
          _isNewUser = !exists;
        });

        if (!exists && _fullNameController.text.trim().isEmpty) {
          // New user and name is empty: prompt name input
          setState(() {
            _sendingOtp = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("It looks like you're new! Please enter your name first, then click Send OTP.")),
          );
          return;
        }
      }

      // 2. Send OTP
      final response = await ApiClient.post(
        Uri.parse("${ApiClient.baseUrl}/auth/otp/send?phoneNumber=$phone"),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        setState(() {
          _otpSent = true;
        });
        _startResendTimer();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("OTP sent successfully! Check SMS or server logs.")),
        );
      } else {
        final err = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err["error"] ?? "Failed to send OTP")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error connecting to server")),
      );
    } finally {
      if (mounted) {
        setState(() {
          _sendingOtp = false;
        });
      }
    }
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() {
      _resendCountdown = 60;
      _canResend = false;
    });
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_resendCountdown <= 1) {
          _canResend = true;
          _resendTimer?.cancel();
        } else {
          _resendCountdown--;
        }
      });
    });
  }

  Future<void> _loginOrRegisterWithOtp() async {
    final phone = _phoneController.text.trim();
    final otp = _otpController.text.trim();
    final name = _fullNameController.text.trim();

    if (phone.isEmpty || otp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter phone number and OTP")),
      );
      return;
    }

    if (_isNewUser && name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your name to complete registration")),
      );
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final response = await ApiClient.post(
        Uri.parse("${ApiClient.baseUrl}/auth/otp/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "phoneNumber": phone,
          "otp": otp,
          "fullName": _isNewUser ? name : null,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String token = data["token"];

        AuthService.token = token;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("jwt_token", token);
        await AuthService.saveFcmToken();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const MainNavigationScreen(),
          ),
        );
      } else {
        final err = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err["error"] ?? "OTP verification failed")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error connecting to server")),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    _fullNameController.dispose();
    _resendTimer?.cancel();
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
                        'assets/images/lll.png',
                        width: 118,
                        height: 19,
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

                    const SizedBox(height: 24),

                    // iOS Grouped List Form Panel
                    Container(
                      constraints: const BoxConstraints(maxWidth: 360),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1C1E), // iOS System Gray 6
                        borderRadius: BorderRadius.circular(20), // Softer, more premium curve
                        border: Border.all(
                          color: const Color(0xFF2C2C2E),
                          width: 0.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // 1. DYNAMIC NAME FIELD FOR NEW USERS
                          if (!_adminLoginMode && _isNewUser) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                              child: TextField(
                                controller: _fullNameController,
                                textCapitalization: TextCapitalization.words,
                                style: const TextStyle(fontSize: 15, color: Colors.white),
                                decoration: const InputDecoration(
                                  labelText: "Full Name",
                                  labelStyle: TextStyle(color: Color(0xFF8E8E93), fontSize: 14),
                                  floatingLabelStyle: TextStyle(color: Color(0xFF0A84FF), fontSize: 12),
                                  hintText: "Enter your full name",
                                  hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                                  prefixIcon: Icon(Icons.person, color: Color(0xFF8E8E93), size: 20),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  errorBorder: InputBorder.none,
                                  disabledBorder: InputBorder.none,
                                  filled: false,
                                ),
                              ),
                            ),
                            const Divider(
                              height: 1,
                              thickness: 0.5,
                              color: Color(0xFF38383A),
                              indent: 12,
                              endIndent: 12,
                            ),
                          ],

                          // 2. PHONE NUMBER FIELD
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                            child: TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              maxLength: 10,
                              readOnly: _otpSent,
                              style: TextStyle(
                                fontSize: 15,
                                color: _otpSent ? const Color(0xFF8E8E93) : Colors.white,
                              ),
                              decoration: const InputDecoration(
                                labelText: "Phone Number",
                                labelStyle: TextStyle(color: Color(0xFF8E8E93), fontSize: 14),
                                floatingLabelStyle: TextStyle(color: Color(0xFF0A84FF), fontSize: 12),
                                prefixIcon: Icon(Icons.phone, color: Color(0xFF8E8E93), size: 20),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                                filled: false,
                                counterText: "",
                                suffixIcon: null,
                              ),
                            ),
                          ),

                          // 3. DYNAMIC OTP FIELD FOR CUSTOMERS
                          if (!_adminLoginMode && _otpSent) ...[
                            const Divider(
                              height: 1,
                              thickness: 0.5,
                              color: Color(0xFF38383A),
                              indent: 12,
                              endIndent: 12,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                              child: TextField(
                                controller: _otpController,
                                keyboardType: TextInputType.number,
                                maxLength: 6,
                                style: const TextStyle(fontSize: 15, color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: "Verification OTP",
                                  labelStyle: const TextStyle(color: Color(0xFF8E8E93), fontSize: 14),
                                  floatingLabelStyle: const TextStyle(color: Color(0xFF0A84FF), fontSize: 12),
                                  hintText: "Enter 6-digit OTP",
                                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                                  prefixIcon: const Icon(Icons.security_outlined, color: Color(0xFF8E8E93), size: 20),
                                  counterText: "",
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  errorBorder: InputBorder.none,
                                  disabledBorder: InputBorder.none,
                                  filled: false,
                                  suffixIconConstraints: const BoxConstraints(
                                    minWidth: 120,
                                    minHeight: 0,
                                  ),
                                  suffixIcon: _sendingOtp
                                      ? const Padding(
                                          padding: EdgeInsets.all(12),
                                          child: SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0A84FF)),
                                          ),
                                        )
                                      : TextButton(
                                          onPressed: _canResend ? _checkAndSendOtp : null,
                                          style: TextButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            minimumSize: const Size(0, 0),
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.only(left: 12, right: 16),
                                            child: Text(
                                              _canResend ? "Resend" : "Resend in ${_resendCountdown}s",
                                              style: TextStyle(
                                                color: _canResend ? const Color(0xFF0A84FF) : const Color(0xFF8E8E93),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                            ),
                            const Divider(
                              height: 1,
                              thickness: 0.5,
                              color: Color(0xFF38383A),
                              indent: 12,
                              endIndent: 12,
                            ),
                            // Back / Change Phone Number Link
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Entered wrong number?",
                                    style: TextStyle(color: Color(0xFF8E8E93), fontSize: 12),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _otpSent = false;
                                        _otpController.clear();
                                        _resendTimer?.cancel();
                                        _canResend = false;
                                      });
                                    },
                                    child: const Text(
                                      "Change Number",
                                      style: TextStyle(
                                        color: Color(0xFF0A84FF),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // 4. PASSWORD FIELD FOR ADMINS ONLY
                          if (_adminLoginMode) ...[
                            const Divider(
                              height: 1,
                              thickness: 0.5,
                              color: Color(0xFF38383A),
                              indent: 12,
                              endIndent: 12,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                              child: TextField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                onSubmitted: (_) => _login(),
                                style: const TextStyle(fontSize: 15, color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: "Password",
                                  labelStyle: const TextStyle(color: Color(0xFF8E8E93), fontSize: 14),
                                  floatingLabelStyle: const TextStyle(color: Color(0xFF0A84FF), fontSize: 12),
                                  prefixIcon: const Icon(Icons.lock, color: Color(0xFF8E8E93), size: 20),
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
                                      size: 18,
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
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    _loading
                        ? const CircularProgressIndicator()
                        : Container(
                            constraints: const BoxConstraints(maxWidth: 360),
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0A84FF), // iOS System Blue
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                _adminLoginMode
                                    ? "Admin Login"
                                    : (!_otpSent
                                        ? "Get OTP"
                                        : (_isNewUser ? "Verify & Register" : "Verify & Sign In")),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

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