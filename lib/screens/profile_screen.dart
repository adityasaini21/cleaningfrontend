import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../services/cart_provider.dart';
import '../models/user_profile.dart';
import '../core/constants/india_states_cities.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback onOrdersTap;
  final bool startInEditMode;
  final VoidCallback? onProfileSaved;

  const ProfileScreen({
    super.key,
    required this.onOrdersTap,
    this.startInEditMode = false,
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

  // Password Controllers
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _isEditing = widget.startInEditMode; // Toggle edit mode if redirected from onboarding
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
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
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
    if (!_formKey.currentState!.validate()) return;

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
          widget.onProfileSaved?.call(); // Automatically trigger callback to navigate back to Products
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? "Profile updated successfully!" : "Failed to update profile"),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  void _showChangePasswordDialog() {
    _oldPasswordController.clear();
    _newPasswordController.clear();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1C1C1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF2C2C2E), width: 0.5),
          ),
          title: const Text(
            "Change Password",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              TextField(
                controller: _oldPasswordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Old Password",
                  labelStyle: TextStyle(color: Colors.grey),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF38383A)),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF0A84FF)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _newPasswordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "New Password",
                  labelStyle: TextStyle(color: Colors.grey),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF38383A)),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF0A84FF)),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Color(0xFF0A84FF)),
              ),
            ),
            TextButton(
              onPressed: () async {
                final oldPassword = _oldPasswordController.text.trim();
                final newPassword = _newPasswordController.text.trim();

                if (oldPassword.isEmpty || newPassword.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("All fields are required")),
                  );
                  return;
                }

                if (newPassword.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("New password must be at least 6 characters")),
                  );
                  return;
                }

                final error = await _profileService.changePassword(oldPassword, newPassword);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(error ?? "Password changed successfully!"),
                      backgroundColor: error == null ? Colors.green : Colors.red,
                    ),
                  );
                }
              },
              child: const Text(
                "Change",
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
          ],
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
          TextButton(
            onPressed: _isLoading
                ? null
                : () {
                    setState(() {
                      if (_isEditing) {
                        _revertChanges();
                        _isEditing = false;
                      } else {
                        _isEditing = true;
                      }
                    });
                  },
            child: Text(
              _isEditing ? "Cancel" : "Edit",
              style: TextStyle(
                color: _isEditing ? Colors.redAccent : const Color(0xFF0A84FF),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // Avatar & Welcome Text
                      CircleAvatar(
                        radius: 55,
                        backgroundColor: Colors.blue.shade600,
                        child: Text(
                          firstName.isNotEmpty ? firstName[0].toUpperCase() : "U",
                          style: const TextStyle(
                            fontSize: 40,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Hello, $firstName 👋",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "Welcome to NuKlean",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Grouped Card: Personal Info & Settings
                      _buildSettingsGroup([
                        ListTile(
                          leading: const Icon(Icons.receipt_long, color: Colors.white70),
                          title: const Text("My Orders", style: TextStyle(color: Colors.white)),
                          subtitle: const Text("View your past purchases", style: TextStyle(color: Colors.grey, fontSize: 12)),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                          onTap: widget.onOrdersTap,
                        ),
                        const Divider(color: Color(0xFF2C2C2E), height: 1, indent: 56),
                        ListTile(
                          leading: const Icon(Icons.lock_outline, color: Colors.white70),
                          title: const Text("Change Password", style: TextStyle(color: Colors.white)),
                          subtitle: const Text("Keep your account secure", style: TextStyle(color: Colors.grey, fontSize: 12)),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                          onTap: _showChangePasswordDialog,
                        ),
                      ]),

                      const SizedBox(height: 25),

                      // Section Title: Personal Details
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.only(left: 8, bottom: 8),
                          child: Text(
                            "PERSONAL DETAILS",
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
                          label: "Full Name",
                          icon: Icons.person_outline,
                          readOnly: !_isEditing,
                          validator: (val) => val == null || val.trim().isEmpty ? "Full name is required" : null,
                        ),
                        _buildInputField(
                          controller: _emailController,
                          label: "Email Address",
                          icon: Icons.mail_outline,
                          readOnly: !_isEditing,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        _buildInputField(
                          controller: _addressController,
                          label: "Shipping Address",
                          icon: Icons.home_outlined,
                          readOnly: !_isEditing,
                        ),
                        _buildInputField(
                          controller: _landmarkController,
                          label: "Landmark",
                          icon: Icons.pin_drop_outlined,
                          readOnly: !_isEditing,
                        ),
                        _buildInputField(
                          controller: _pincodeController,
                          label: "Pincode",
                          icon: Icons.map_outlined,
                          readOnly: !_isEditing,
                          keyboardType: TextInputType.number,
                        ),
                        _buildDropdownField(
                          label: "State",
                          icon: Icons.map_outlined,
                          value: _selectedState,
                          items: indiaStatesAndCities.keys.toList(),
                          onChanged: !_isEditing ? null : (state) {
                            setState(() {
                              _selectedState = state;
                              _selectedCity = null; // Reset city selection
                            });
                          },
                        ),
                        _buildDropdownField(
                          label: "City",
                          icon: Icons.location_city_outlined,
                          value: _selectedCity,
                          placeholder: _selectedState == null ? "Choose State first" : "Select City",
                          items: _selectedState != null ? indiaStatesAndCities[_selectedState]! : [],
                          onChanged: (!_isEditing || _selectedState == null) ? null : (city) {
                            setState(() {
                              _selectedCity = city;
                            });
                          },
                          hideBottomBorder: true,
                        ),
                      ]),

                      const SizedBox(height: 25),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: (_isEditing && _hasChanges() && !_isSaving) ? _saveProfile : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0A84FF), // iOS Blue
                            disabledBackgroundColor: const Color(0xFF2C2C2E), // Grayed out when inactive
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : Text(
                                  "Save Changes",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: (_isEditing && _hasChanges()) ? Colors.white : Colors.grey,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Logout Card
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
                      ]),

                      const SizedBox(height: 100),
                    ],
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2C2C2E), width: 0.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
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
        borderRadius: BorderRadius.circular(14),
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