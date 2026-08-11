import 'dart:async';

import 'package:flutter/material.dart';

import '../models/admin_user.dart';
import '../services/admin_user_service.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final AdminUserService _service = AdminUserService();

  final TextEditingController _searchController =
  TextEditingController();

  Timer? _searchTimer;

  List<AdminUser> _users = [];

  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchTimer?.cancel();

    _searchTimer = Timer(
      const Duration(milliseconds: 400),
          () {
        _loadUsers();
      },
    );
  }

  Future<void> _loadUsers() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final users = await _service.searchUsers(
        _searchController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        _users = users;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _showResetPasswordDialog(
      AdminUser user,
      ) async {
    final newPasswordController =
    TextEditingController();

    final confirmPasswordController =
    TextEditingController();

    bool obscureNewPassword = true;
    bool obscureConfirmPassword = true;
    bool resetting = false;

    await showDialog(
      context: context,
      barrierDismissible: !resetting,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> resetPassword() async {
              final newPassword =
                  newPasswordController.text;

              final confirmPassword =
                  confirmPasswordController.text;

              if (newPassword.isEmpty ||
                  confirmPassword.isEmpty) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Please fill both password fields",
                    ),
                  ),
                );
                return;
              }

              if (newPassword.length < 8) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Password must be at least 8 characters",
                    ),
                  ),
                );
                return;
              }

              if (newPassword != confirmPassword) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Passwords do not match",
                    ),
                  ),
                );
                return;
              }

              setDialogState(() {
                resetting = true;
              });

              try {
                await _service.resetPassword(
                  user.id,
                  newPassword,
                );

                if (!mounted) return;

                Navigator.pop(dialogContext);

                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  SnackBar(
                    content: Text(
                      "Password reset successfully for ${user.fullName}",
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                setDialogState(() {
                  resetting = false;
                });

                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  SnackBar(
                    content: Text(
                      e.toString().replaceFirst(
                        "Exception: ",
                        "",
                      ),
                    ),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            }

            return AlertDialog(
              title: const Text("Reset Password"),

              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      user.fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      user.phoneNumber,
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),

                    const SizedBox(height: 24),

                    TextField(
                      controller: newPasswordController,
                      obscureText: obscureNewPassword,
                      enabled: !resetting,
                      decoration: InputDecoration(
                        labelText: "New Password",
                        border: const OutlineInputBorder(),
                        prefixIcon:
                        const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureNewPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              obscureNewPassword =
                              !obscureNewPassword;
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller:
                      confirmPasswordController,
                      obscureText:
                      obscureConfirmPassword,
                      enabled: !resetting,
                      decoration: InputDecoration(
                        labelText: "Confirm Password",
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureConfirmPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              obscureConfirmPassword =
                              !obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              actions: [
                TextButton(
                  onPressed: resetting
                      ? null
                      : () {
                    Navigator.pop(
                      dialogContext,
                    );
                  },
                  child: const Text("Cancel"),
                ),

                ElevatedButton(
                  onPressed:
                  resetting ? null : resetPassword,
                  child: resetting
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child:
                    CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                      : const Text(
                    "Reset Password",
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    newPasswordController.dispose();
    confirmPasswordController.dispose();
  }

  Future<void> _toggleUserStatus(AdminUser user) async {
    try {
      final updatedUser = await _service.toggleUserStatus(user.id);
      if (!mounted) return;

      setState(() {
        final index = _users.indexWhere((u) => u.id == user.id);
        if (index != -1) {
          _users[index] = updatedUser;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            updatedUser.active
                ? "Activated customer ${user.fullName}"
                : "Deactivated customer ${user.fullName}",
          ),
          backgroundColor: updatedUser.active ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst("Exception: ", ""),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Customers"),
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText:
                "Search by name or phone number",
                prefixIcon:
                const Icon(Icons.search),
                suffixIcon:
                _searchController.text.isNotEmpty
                    ? IconButton(
                  icon:
                  const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _loadUsers();
                    setState(() {});
                  },
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: _buildUserList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserList() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 50,
            ),

            const SizedBox(height: 12),

            Text(
              _error!.replaceFirst(
                "Exception: ",
                "",
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: _loadUsers,
              child: const Text("Retry"),
            ),
          ],
        ),
      );
    }

    if (_users.isEmpty) {
      return const Center(
        child: Text(
          "No customers found",
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,

      child: ListView.separated(
        physics:
        const AlwaysScrollableScrollPhysics(),

        itemCount: _users.length,

        separatorBuilder: (_, __) =>
        const SizedBox(height: 10),

        itemBuilder: (context, index) {
          final user = _users[index];

          return Card(
            child: ListTile(
              contentPadding:
              const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),

              leading: CircleAvatar(
                child: Text(
                  user.fullName.isNotEmpty
                      ? user.fullName[0]
                      .toUpperCase()
                      : "?",
                ),
              ),

              title: Text(
                user.fullName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),

              subtitle: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),

                  Text(user.phoneNumber),

                  if (user.email != null &&
                      user.email!.isNotEmpty)
                    Text(user.email!),

                  const SizedBox(height: 4),

                  Text(
                    user.active
                        ? "Active"
                        : "Inactive",
                    style: TextStyle(
                      color: user.active
                          ? Colors.green
                          : Colors.red,
                      fontSize: 12,
                      fontWeight:
                      FontWeight.w600,
                    ),
                  ),
                ],
              ),

              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: "Reset Password",
                    icon: const Icon(
                      Icons.lock_reset,
                    ),
                    onPressed: () =>
                        _showResetPasswordDialog(user),
                  ),
                  Switch(
                    value: user.active,
                    activeColor: Colors.green,
                    onChanged: (val) => _toggleUserStatus(user),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}