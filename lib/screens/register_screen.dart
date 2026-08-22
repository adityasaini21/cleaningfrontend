import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../core/api_client.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  bool _otpSent = false;
  bool _otpVerified = false;
  bool _sendingOtp = false;
  final _otpController = TextEditingController();

  final String baseUrl = ApiClient.baseUrl;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
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
      final response = await ApiClient.post(
        Uri.parse("$baseUrl/auth/otp/send?phoneNumber=$phone"),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        setState(() {
          _otpSent = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("OTP sent successfully! Check your SMS or terminal logs.")),
        );
      } else {
        String errorMsg = "Failed to send OTP";
        try {
          final data = jsonDecode(response.body);
          if (data is Map && data.containsKey("error")) {
            errorMsg = data["error"].toString();
          }
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg)),
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

  Future<void> registerUser() async {
    if (_loading) return;

    if (!_otpSent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please request and enter the OTP first.")),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
    });

    try {
      final phone = _phoneController.text.trim();
      final otpCode = _otpController.text.trim();

      // 1. Verify OTP first
      if (!_otpVerified) {
        final otpResponse = await ApiClient.post(
          Uri.parse("$baseUrl/auth/otp/verify?phoneNumber=$phone&otp=$otpCode"),
          headers: {"Content-Type": "application/json"},
        );

        if (otpResponse.statusCode != 200) {
          final errData = jsonDecode(otpResponse.body);
          throw Exception(errData["error"] ?? "OTP verification failed");
        }

        _otpVerified = true;
      }

      // 2. Perform actual registration
      final response = await ApiClient.post(
        Uri.parse("$baseUrl/auth/register"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "fullName": _fullNameController.text.trim(),
          "phoneNumber": phone,
          "password": _passwordController.text,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final message = response.body.trim();

        if (message == "User registered successfully") {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Registration successful! Please login."),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const LoginScreen(),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                message.isNotEmpty ? message : "Registration successful",
              ),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const LoginScreen(),
            ),
          );
        }
      } else {
        String errorMessage = "Registration failed";
        try {
          final errorData = jsonDecode(response.body);
          if (errorData is Map && errorData.containsKey("message")) {
            errorMessage = errorData["message"].toString();
          } else {
            errorMessage = response.body.trim().isNotEmpty
                ? response.body.trim()
                : "Registration failed";
          }
        } catch (_) {
          errorMessage = response.body.trim().isNotEmpty
              ? response.body.trim()
              : "Registration failed";
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Unable to connect to server"),
          backgroundColor: Colors.redAccent,
        ),
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        color: const Color(0xFF000000), // OLED True Black
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 16,
            ),
            child: Form(
              key: _formKey,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),

                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        size: 22,
                        color: Color(0xFF0A84FF), // iOS system blue
                      ),
                      onPressed: _loading
                          ? null
                          : () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),

                    const SizedBox(height: 16),

                    Center(
                      child: Image.asset(
                        'assets/images/lll.png',
                        width: 120,
                        height: 21,
                        fit: BoxFit.contain,
                      ),
                    ),

                    const SizedBox(height: 16),

                    Text(
                      "Create Account",
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      "Create your NuKlean customer account",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF8E8E93), // iOS Gray
                      ),
                    ),

                    const SizedBox(height: 28),

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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 16, top: 16, right: 16),
                            child: _buildSectionHeader(
                              "Account Details",
                              Icons.person_outline,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // FULL NAME
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: TextFormField(
                              controller: _fullNameController,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              style: const TextStyle(fontSize: 16),
                              decoration: const InputDecoration(
                                labelText: "Full Name",
                                labelStyle: TextStyle(color: Color(0xFF8E8E93)),
                                hintText: "Enter your full name",
                                prefixIcon: Icon(Icons.person, color: Color(0xFF8E8E93), size: 22),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                                filled: false,
                              ),
                              validator: (value) {
                                final name = value?.trim() ?? "";

                                if (name.isEmpty) {
                                  return "Please enter your full name";
                                }

                                if (name.length < 3) {
                                  return "Name must be at least 3 characters";
                                }

                                if (name.length > 100) {
                                  return "Name is too long";
                                }

                                return null;
                              },
                            ),
                          ),

                          const Divider(
                            height: 1,
                            thickness: 0.5,
                            color: Color(0xFF38383A), // iOS cell divider
                            indent: 16,
                            endIndent: 16,
                          ),

                          // PHONE NUMBER
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              maxLength: 10,
                              style: const TextStyle(fontSize: 16),
                              decoration: InputDecoration(
                                labelText: "Phone Number",
                                labelStyle: const TextStyle(color: Color(0xFF8E8E93)),
                                hintText: "10-digit mobile number",
                                prefixIcon: const Icon(Icons.phone, color: Color(0xFF8E8E93), size: 22),
                                counterText: "",
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                                filled: false,
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
                                        onPressed: _sendOtp,
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          minimumSize: const Size(0, 0),
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.only(right: 16),
                                          child: Text(
                                            _otpSent ? "Resend" : "Send OTP",
                                            style: const TextStyle(
                                              color: Color(0xFF0A84FF),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                              ),
                              validator: (value) {
                                final phone = value?.trim() ?? "";

                                if (phone.isEmpty) {
                                  return "Please enter your phone number";
                                }

                                if (!RegExp(r'^[6-9]\d{9}$').hasMatch(phone)) {
                                  return "Enter a valid 10-digit Indian mobile number";
                                }

                                return null;
                              },
                            ),
                          ),

                          if (_otpSent) ...[
                            const Divider(
                              height: 1,
                              thickness: 0.5,
                              color: Color(0xFF38383A), // iOS cell divider
                              indent: 16,
                              endIndent: 16,
                            ),
                            // OTP VERIFICATION FIELD
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              child: TextFormField(
                                controller: _otpController,
                                keyboardType: TextInputType.number,
                                maxLength: 6,
                                style: const TextStyle(fontSize: 16),
                                decoration: const InputDecoration(
                                  labelText: "Verification OTP",
                                  labelStyle: TextStyle(color: Color(0xFF8E8E93)),
                                  hintText: "Enter 6-digit OTP",
                                  prefixIcon: Icon(Icons.security_outlined, color: Color(0xFF8E8E93), size: 22),
                                  counterText: "",
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  errorBorder: InputBorder.none,
                                  disabledBorder: InputBorder.none,
                                  filled: false,
                                ),
                                validator: (value) {
                                  final code = value?.trim() ?? "";
                                  if (code.isEmpty) {
                                    return "Please enter the verification OTP";
                                  }
                                  if (code.length != 6) {
                                    return "OTP must be 6 digits";
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],

                          const Divider(
                            height: 1,
                            thickness: 0.5,
                            color: Color(0xFF38383A), // iOS cell divider
                            indent: 16,
                            endIndent: 16,
                          ),

                          // NEW PASSWORD
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.next,
                              style: const TextStyle(fontSize: 16),
                              decoration: InputDecoration(
                                labelText: "New Password",
                                labelStyle: const TextStyle(color: Color(0xFF8E8E93)),
                                hintText: "Minimum 8 characters",
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
                              validator: (value) {
                                final password = value ?? "";

                                if (password.isEmpty) {
                                  return "Please enter a password";
                                }

                                if (password.length < 8) {
                                  return "Password must be at least 8 characters";
                                }

                                return null;
                              },
                            ),
                          ),

                          const Divider(
                            height: 1,
                            thickness: 0.5,
                            color: Color(0xFF38383A), // iOS cell divider
                            indent: 16,
                            endIndent: 16,
                          ),

                          // CONFIRM PASSWORD
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirmPassword,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => registerUser(),
                              style: const TextStyle(fontSize: 16),
                              decoration: InputDecoration(
                                labelText: "Confirm Password",
                                labelStyle: const TextStyle(color: Color(0xFF8E8E93)),
                                hintText: "Enter your password again",
                                prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF8E8E93), size: 22),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                                filled: false,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirmPassword
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: const Color(0xFF8E8E93),
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                    });
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Please confirm your password";
                                }

                                if (value != _passwordController.text) {
                                  return "Passwords do not match";
                                }

                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 36),

                    // REGISTER BUTTON (CAPSULE STYLE MATCHING LOGIN SCREEN)
                    _loading
                        ? const Center(child: CircularProgressIndicator())
                        : SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: registerUser,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0A84FF), // iOS System Blue
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                "Create Account",
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Already have an account?",
                          style: TextStyle(
                            color: Color(0xFF8E8E93),
                          ),
                        ),
                        TextButton(
                          onPressed: _loading
                              ? null
                              : () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const LoginScreen(),
                                    ),
                                  );
                                },
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF0A84FF),
                          ),
                          child: const Text("Login"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
      String title,
      IconData icon,
      ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.grey.shade700,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}