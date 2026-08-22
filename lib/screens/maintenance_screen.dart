import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/api_client.dart';
import '../theme/app_theme.dart';
import 'splash_screen.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  bool _checking = false;

  Future<void> _checkStatus() async {
    setState(() {
      _checking = true;
    });

    try {
      final response = await http.get(
        Uri.parse("${ApiClient.baseUrl}/api/service-status"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final bool suspended = data["suspended"] ?? false;

        if (!suspended) {
          // Service is back online! Redirect to splash/main screen
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const SplashScreen()),
              (route) => false,
            );
          }
          return;
        }
      }
    } catch (e) {
      debugPrint("Error checking service status: $e");
    } finally {
      if (mounted) {
        setState(() {
          _checking = false;
        });
      }
    }

    // Still suspended, show snackbar
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("We are still undergoing maintenance. Please try again in a bit!"),
          backgroundColor: AppTheme.warning,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              
              // Premium iOS style maintenance icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.engineering_rounded,
                  size: 80,
                  color: AppTheme.warning,
                ),
              ),
              const SizedBox(height: 32),
              
              const Text(
                "System Maintenance",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              
              Text(
                "We are temporarily upgrading our systems to improve your cleaning experience. We'll be back shortly!\n\nThank you for your patience.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AppTheme.textSecondary,
                ),
              ),
              
              const Spacer(),
              
              // Check again button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _checking ? null : _checkStatus,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _checking
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Check Again",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
