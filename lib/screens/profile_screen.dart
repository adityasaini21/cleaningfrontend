import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../services/cart_provider.dart';
import '../models/user_profile.dart';
import '../core/constants/india_states_cities.dart';
import 'login_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback onOrdersTap;
  final bool startInEditMode;
  final bool isMandatoryOnboarding;
  final VoidCallback? onProfileSaved;

  const ProfileScreen({
    super.key,
    required this.onOrdersTap,
    this.startInEditMode = false,
    this.isMandatoryOnboarding = false,
    this.onProfileSaved,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final ProfileService _profileService = ProfileService();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false; // Controls forms enablement

  UserProfile? _initialProfile; // Tracks original state to check if user made any edits
  final _formKey = GlobalKey<FormState>();

  // Selection states for Dropdowns
  String? _selectedState;
  String? _selectedCity;

  // Text Controllers
  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _pincodeController;
  late TextEditingController _landmarkController;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.startInEditMode || widget.isMandatoryOnboarding; // Toggle edit mode if redirected from onboarding
    _fullNameController = TextEditingController();
    _emailController = TextEditingController();
    _addressController = TextEditingController();
    _pincodeController = TextEditingController();
    _landmarkController = TextEditingController();

    // Listen to changes on text controllers to enable/disable save button dynamically
    _fullNameController.addListener(_onFieldChanged);
    _emailController.addListener(_onFieldChanged);
    _addressController.addListener(_onFieldChanged);
    _pincodeController.addListener(_onFieldChanged);
    _landmarkController.addListener(_onFieldChanged);

    _loadProfile();
  }

  @override
  void dispose() {
    _fullNameController.removeListener(_onFieldChanged);
    _emailController.removeListener(_onFieldChanged);
    _addressController.removeListener(_onFieldChanged);
    _pincodeController.removeListener(_onFieldChanged);
    _landmarkController.removeListener(_onFieldChanged);

    _fullNameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _pincodeController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  bool _hasChanges() {
    final currentFullName = _fullNameController.text.trim();
    final currentEmail = _emailController.text.trim();
    final currentAddress = _addressController.text.trim();
    final currentLandmark = _landmarkController.text.trim();
    final currentPincode = _pincodeController.text.trim();
    final currentCity = _selectedCity ?? '';
    final currentState = _selectedState ?? '';

    final initialFullName = _initialProfile?.fullName.trim() ?? '';
    final initialEmail = _initialProfile?.email?.trim() ?? '';
    final initialAddress = _initialProfile?.address?.trim() ?? '';
    final initialLandmark = _initialProfile?.landmark?.trim() ?? '';
    final initialPincode = _initialProfile?.pincode?.trim() ?? '';
    final initialCity = _initialProfile?.city?.trim() ?? '';
    final initialState = _initialProfile?.state?.trim() ?? '';

    return currentFullName != initialFullName ||
        currentEmail != initialEmail ||
        currentAddress != initialAddress ||
        currentLandmark != initialLandmark ||
        currentPincode != initialPincode ||
        currentCity != initialCity ||
        currentState != initialState;
  }

  void _revertChanges() {
    if (_initialProfile != null) {
      _fullNameController.text = _initialProfile!.fullName;
      _emailController.text = _initialProfile!.email ?? '';
      _addressController.text = _initialProfile!.address ?? '';
      _pincodeController.text = _initialProfile!.pincode ?? '';
      _landmarkController.text = _initialProfile!.landmark ?? '';
      
      // Re-sync dropdown state
      final dbState = _initialProfile!.state?.trim() ?? '';
      final dbCity = _initialProfile!.city?.trim() ?? '';
      if (indiaStatesAndCities.containsKey(dbState)) {
        _selectedState = dbState;
        if (indiaStatesAndCities[dbState]!.contains(dbCity)) {
          _selectedCity = dbCity;
        } else {
          _selectedCity = null;
        }
      } else {
        _selectedState = null;
        _selectedCity = null;
      }
    }
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    final profile = await _profileService.fetchProfile();
    if (profile != null) {
      _initialProfile = profile;
      _revertChanges();
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all required delivery details!"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_selectedState == null || _selectedState!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select your State"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_selectedCity == null || _selectedCity!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select your City"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final updatedProfile = UserProfile(
      fullName: _fullNameController.text.trim(),
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      city: _selectedCity,
      state: _selectedState,
      pincode: _pincodeController.text.trim().isEmpty ? null : _pincodeController.text.trim(),
      landmark: _landmarkController.text.trim().isEmpty ? null : _landmarkController.text.trim(),
    );

    final success = await _profileService.updateProfile(updatedProfile);
    if (mounted) {
      setState(() {
        _isSaving = false;
        if (success) {
          _initialProfile = updatedProfile;
          _isEditing = false; // Re-lock form and change top-right action button back to "Edit"
          FocusScope.of(context).unfocus(); // Dismiss keyboard automatically
          widget.onProfileSaved?.call(); // Automatically trigger callback to unlock nav and navigate
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? "Profile saved successfully! You can now browse and place orders." : "Failed to update profile"),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  void _showCustomerCareBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Help & Support",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Reach out to us for anything! Whether you have questions about products, delivery timings, pricing, or need help with your orders, we are here to help.",
                  style: TextStyle(
                    color: Color(0xFF8E8E93),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Contact options list
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2C2E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.phone_outlined, color: Color(0xFF0A84FF)),
                        title: const Text("Call Customer Support", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
                        subtitle: const Text("+91 9795611275", style: TextStyle(color: Colors.grey, fontSize: 13)),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
                        onTap: () async {
                          final uri = Uri.parse("tel:+919795611275");
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri);
                          }
                        },
                      ),
                      const Divider(color: Color(0xFF38383A), height: 1, indent: 56),
                      ListTile(
                        leading: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF30D158)),
                        title: const Text("Chat on WhatsApp", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
                        subtitle: const Text("Tap to message admin", style: TextStyle(color: Colors.grey, fontSize: 13)),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
                        onTap: () async {
                          final url = "https://wa.me/919795611275?text=${Uri.encodeComponent('Hello support team, I have a query regarding...')}";
                          final uri = Uri.parse(url);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showReturnPolicyDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade600,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Icon(Icons.assignment_return_outlined, color: Color(0xFFFF9F0A), size: 24),
                      SizedBox(width: 10),
                      Text(
                        "Return & Refund Policy",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9F0A).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFF9F0A).withOpacity(0.3), width: 1),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: Color(0xFFFF9F0A), size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "All products sold on NuKlean / Prem Chemicals are strictly Non-Returnable and Non-Refundable once delivered.",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    "Why Non-Returnable?",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Due to the nature of chemical cleaning agents, hygiene standards, and safety regulations, items once unsealed or delivered cannot be taken back or re-stocked.",
                    style: TextStyle(
                      color: Color(0xFF8E8E93),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Damaged or Incorrect Item Received?",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "If you received a damaged package or an incorrect item, please report it immediately to our Customer Care team with order details and photo proof within 24 hours of delivery. We will gladly inspect and resolve the issue for you.",
                    style: TextStyle(
                      color: Color(0xFF8E8E93),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0A84FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.support_agent, size: 20, color: Colors.white),
                      label: const Text(
                        "Contact Customer Care",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _showCustomerCareBottomSheet();
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showPrivacyPolicyDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade600,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Icon(Icons.privacy_tip_outlined, color: Color(0xFF0A84FF), size: 24),
                      SizedBox(width: 10),
                      Text(
                        "Privacy Policy",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0x200A84FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0x660A84FF), width: 1),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.shield_outlined, color: Color(0xFF0A84FF), size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Prem Chemicals / NuKlean is committed to protecting your personal data and ensuring full privacy compliance.",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    "1. Information We Collect",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "We collect necessary details like your mobile number (for OTP authentication), full name, delivery address, city, pincode, and order history to process and deliver your cleaning chemical supplies.",
                    style: TextStyle(
                      color: Color(0xFF8E8E93),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "2. How We Use Your Data",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Your information is used strictly to fulfill orders, provide doorstep dispatch updates, coordinate customer care requests, and protect against fraudulent activities. We do NOT sell or lease your personal data to third-party advertisers.",
                    style: TextStyle(
                      color: Color(0xFF8E8E93),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "3. Payment Security",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "All payments are processed through RBI-compliant, certified payment gateways (Razorpay / UPI). NuKlean never stores or handles your debit/credit card numbers or banking passwords.",
                    style: TextStyle(
                      color: Color(0xFF8E8E93),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "4. Data Rights & Control",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "You retain full control over your account. You can view or update your name and address directly from the Profile section at any time.",
                    style: TextStyle(
                      color: Color(0xFF8E8E93),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0A84FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.check_circle_outline, size: 20, color: Colors.white),
                      label: const Text(
                        "Understood",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showLogoutConfirmation(BuildContext context, AuthService authService) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1C1C1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF2C2C2E), width: 0.5),
          ),
          title: const Text(
            "Logout",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            "Do you really want to logout?",
            style: TextStyle(color: Color(0xFF8E8E93)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Color(0xFF0A84FF)),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                "Logout",
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await authService.logout();
      if (!context.mounted) return;
      Provider.of<CartProvider>(context, listen: false).clearCart();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
        (route) => false,
      );
    }
  }

  Future<void> _showDeleteAccountConfirmation(BuildContext context, AuthService authService) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1C1C1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF2C2C2E), width: 0.5),
          ),
          title: const Text(
            "Delete Account",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            "Are you absolutely sure you want to delete your account? This action will permanently erase your personal profile data and cannot be undone.",
            style: TextStyle(color: Color(0xFF8E8E93)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Color(0xFF0A84FF)),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                "Delete",
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      final success = await _profileService.deleteAccount();

      setState(() {
        _isLoading = false;
      });

      if (success) {
        await authService.logout();
        if (!context.mounted) return;
        Provider.of<CartProvider>(context, listen: false).clearCart();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Account successfully deleted")),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const LoginScreen(),
          ),
          (route) => false,
        );
      } else {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to delete account. Please try again.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fullName = _fullNameController.text;
    final firstName = fullName.trim().isEmpty ? "User" : fullName.trim().split(' ').first;

    return Scaffold(
      backgroundColor: Colors.black, // Dark theme
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
            child: _isEditing
                ? (widget.isMandatoryOnboarding
                    ? const SizedBox.shrink() // Don't show cancel button during required first-time onboarding
                    : OutlinedButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                setState(() {
                                  _revertChanges();
                                  _isEditing = false;
                                });
                              },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.redAccent, width: 1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                        ),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ))
                : ElevatedButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () {
                            setState(() {
                              _isEditing = true;
                            });
                          },
                    icon: const Icon(Icons.edit, size: 14, color: Colors.white),
                    label: const Text(
                      "Edit Profile",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A84FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      elevation: 2,
                    ),
                  ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 850),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(height: 14),

                      // =========================================
                      // MANDATORY ONBOARDING BANNER & NAVIGATION ARROW GRAPHIC
                      // =========================================
                      if (widget.isMandatoryOnboarding ||
                          (_initialProfile != null &&
                              ((_initialProfile!.address?.trim().isEmpty ?? true) ||
                                  (_initialProfile!.city?.trim().isEmpty ?? true) ||
                                  (_initialProfile!.state?.trim().isEmpty ?? true) ||
                                  (_initialProfile!.pincode?.trim().isEmpty ?? true))))
                        Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF0A84FF).withOpacity(0.18),
                                const Color(0xFF2563EB).withOpacity(0.08),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF0A84FF).withOpacity(0.5),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0A84FF).withOpacity(0.15),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0A84FF).withOpacity(0.25),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.lock_clock_outlined,
                                      color: Color(0xFF0A84FF),
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Action Required: Setup Delivery Profile",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          "Fill required address details below to unlock the app and start ordering. Email is optional.",
                                          style: TextStyle(
                                            color: Color(0xFF8E8E93),
                                            fontSize: 12,
                                            height: 1.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (!_isEditing) ...[
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _isEditing = true;
                                      });
                                    },
                                    icon: const Icon(Icons.arrow_downward, size: 16, color: Colors.white),
                                    label: const Text(
                                      "Tap to Fill Details ➔",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0A84FF),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                      // Avatar & Welcome Text
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.blue.shade600,
                        child: Text(
                          firstName.isNotEmpty ? firstName[0].toUpperCase() : "U",
                          style: const TextStyle(
                            fontSize: 28,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Hello, $firstName 👋",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Welcome to NuKlean",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Section Title: Personal Details
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.only(left: 8, bottom: 8),
                          child: Text(
                            "DELIVERY & PERSONAL DETAILS",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),

                      // Grouped Input Fields Card (iOS Rounded Style)
                      _buildInputGroup([
                        _buildInputField(
                          controller: _fullNameController,
                          label: "Full Name *",
                          icon: Icons.person_outline,
                          readOnly: !_isEditing,
                          validator: (val) => val == null || val.trim().isEmpty ? "Full name is required" : null,
                        ),
                        _buildInputField(
                          controller: _emailController,
                          label: "Email Address (Optional)",
                          icon: Icons.mail_outline,
                          readOnly: !_isEditing,
                          keyboardType: TextInputType.emailAddress,
                          validator: (val) => (val != null && val.trim().isNotEmpty && !RegExp(r'^.+@.+\..+$').hasMatch(val.trim()))
                              ? "Enter a valid email address"
                              : null,
                        ),
                        _buildInputField(
                          controller: _addressController,
                          label: "Shipping Address *",
                          icon: Icons.home_outlined,
                          readOnly: !_isEditing,
                          validator: (val) => val == null || val.trim().isEmpty
                              ? "Shipping address is required"
                              : (val.trim().length < 5 ? "Please enter complete street/house address" : null),
                        ),
                        _buildInputField(
                          controller: _landmarkController,
                          label: "Landmark / Area *",
                          icon: Icons.pin_drop_outlined,
                          readOnly: !_isEditing,
                          validator: (val) => val == null || val.trim().isEmpty ? "Landmark is required" : null,
                        ),
                        _buildInputField(
                          controller: _pincodeController,
                          label: "Pincode *",
                          icon: Icons.map_outlined,
                          readOnly: !_isEditing,
                          keyboardType: TextInputType.number,
                          validator: (val) => val == null || val.trim().length != 6 ? "Valid 6-digit pincode is required" : null,
                        ),
                        _buildDropdownField(
                          label: "State *",
                          icon: Icons.map_outlined,
                          value: _selectedState,
                          items: indiaStatesAndCities.keys.toList(),
                          validator: (val) => (val == null || val.trim().isEmpty) ? "Please select a state" : null,
                          onChanged: !_isEditing ? null : (state) {
                            setState(() {
                              _selectedState = state;
                              _selectedCity = null; // Reset city selection
                            });
                          },
                        ),
                        _buildDropdownField(
                          label: "City *",
                          icon: Icons.location_city_outlined,
                          value: _selectedCity,
                          placeholder: _selectedState == null ? "Choose State first" : "Select City",
                          items: _selectedState != null ? indiaStatesAndCities[_selectedState]! : [],
                          validator: (val) => (val == null || val.trim().isEmpty) ? "Please select a city" : null,
                          onChanged: (!_isEditing || _selectedState == null) ? null : (city) {
                            setState(() {
                              _selectedCity = city;
                            });
                          },
                          hideBottomBorder: true,
                        ),
                      ]),

                      const SizedBox(height: 20),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: (_isEditing && !_isSaving) ? _saveProfile : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0A84FF), // iOS Blue
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: const Color(0xFF2C2C2E), // Grayed out when inactive
                            disabledForegroundColor: Colors.grey,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_circle_outline, size: 18),
                                    SizedBox(width: 8),
                                    Text(
                                      "Save Delivery Details",
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(width: 6),
                                    Icon(Icons.arrow_forward_rounded, size: 16),
                                  ],
                                ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Section Title: My Orders
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.only(left: 8, bottom: 8),
                          child: Text(
                            "ORDERS",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),

                      // Grouped Card: Personal Info & Settings (My Orders)
                      _buildSettingsGroup([
                        ListTile(
                          leading: const Icon(Icons.receipt_long, color: Colors.white70),
                          title: const Text("My Orders", style: TextStyle(color: Colors.white)),
                          subtitle: const Text("View your past purchases", style: TextStyle(color: Colors.grey, fontSize: 12)),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                          onTap: widget.onOrdersTap,
                        ),
                      ]),

                      const SizedBox(height: 28),

                      // Section Title: Help & Support (Moved to Bottom)
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.only(left: 8, bottom: 8),
                          child: Text(
                            "HELP & SUPPORT",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),

                      // Grouped Card: Help Section
                      _buildSettingsGroup([
                        ListTile(
                          leading: const Icon(Icons.support_agent_rounded, color: Colors.white70),
                          title: const Text("Customer Care", style: TextStyle(color: Colors.white)),
                          subtitle: const Text("Reach out to us for any help or queries", style: TextStyle(color: Colors.grey, fontSize: 12)),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                          onTap: _showCustomerCareBottomSheet,
                        ),
                        const Divider(color: Color(0xFF2C2C2E), height: 1, indent: 56),
                        ListTile(
                          leading: const Icon(Icons.assignment_return_outlined, color: Colors.white70),
                          title: const Text("Return & Refund Policy", style: TextStyle(color: Colors.white)),
                          subtitle: const Text("Non-returnable policy & guidelines", style: TextStyle(color: Colors.grey, fontSize: 12)),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                          onTap: _showReturnPolicyDialog,
                        ),
                        const Divider(color: Color(0xFF2C2C2E), height: 1, indent: 56),
                        ListTile(
                          leading: const Icon(Icons.privacy_tip_outlined, color: Colors.white70),
                          title: const Text("Privacy Policy", style: TextStyle(color: Colors.white)),
                          subtitle: const Text("Data protection & safety practices", style: TextStyle(color: Colors.grey, fontSize: 12)),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                          onTap: _showPrivacyPolicyDialog,
                        ),
                      ]),

                      const SizedBox(height: 16),

                      // Actions Card Group
                      _buildSettingsGroup([
                        ListTile(
                          leading: const Icon(Icons.logout, color: Colors.redAccent),
                          title: const Text(
                            "Logout",
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          onTap: () => _showLogoutConfirmation(context, _authService),
                        ),
                        const Divider(color: Color(0xFF2C2C2E), height: 0.5, indent: 56),
                        ListTile(
                          leading: const Icon(Icons.delete_forever, color: Colors.red),
                          title: const Text(
                            "Delete Account",
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          onTap: () => _showDeleteAccountConfirmation(context, _authService),
                        ),
                      ]),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E), // iOS SystemGray6
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2C2C2E), width: 0.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _buildInputGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E), // iOS SystemGray6
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2C2C2E), width: 0.5),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
    bool hideBottomBorder = false,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: hideBottomBorder
            ? null
            : const Border(
                bottom: BorderSide(color: Color(0xFF2C2C2E), width: 0.5),
              ),
      ),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: keyboardType,
        validator: validator,
        style: TextStyle(
          color: readOnly ? Colors.white54 : Colors.white,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF8E8E93), fontSize: 14),
          prefixIcon: Icon(icon, color: const Color(0xFF8E8E93), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required ValueChanged<String?>? onChanged,
    String? placeholder,
    bool hideBottomBorder = false,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: hideBottomBorder
            ? null
            : const Border(
                bottom: BorderSide(color: Color(0xFF2C2C2E), width: 0.5),
              ),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        validator: validator,
        isExpanded: true,
        dropdownColor: const Color(0xFF1C1C1E),
        icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF8E8E93)),
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF8E8E93), fontSize: 14),
          prefixIcon: Icon(icon, color: const Color(0xFF8E8E93), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
        hint: placeholder != null
            ? Text(placeholder, style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 15))
            : null,
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}