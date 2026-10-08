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
  final TextEditingController _searchController = TextEditingController();

  Timer? _searchTimer;
  List<AdminUser> _users = [];
  bool _loading = false;
  String? _error;
  String _selectedTab = "active"; // "active", "blocked", "deleted"

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
                : "Blocked customer ${user.fullName}",
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

  Future<void> _confirmClearBlockedList() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text("Clear Blocked Users List?", style: TextStyle(color: Colors.white)),
        content: const Text(
          "Are you sure you want to permanently clear all admin-blocked users from the system?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Clear List"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _service.clearBlockedUsers();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Blocked users list cleared successfully!"),
          backgroundColor: Colors.green,
        ),
      );
      _loadUsers();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to clear blocked users: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeUsers = _users.where((u) => u.active).toList();
    final blockedUsers = _users.where((u) => !u.active && !u.deletedByUser).toList();
    final deletedUsers = _users.where((u) => !u.active && u.deletedByUser).toList();

    List<AdminUser> displayedUsers;
    if (_selectedTab == "active") {
      displayedUsers = activeUsers;
    } else if (_selectedTab == "blocked") {
      displayedUsers = blockedUsers;
    } else {
      displayedUsers = deletedUsers;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Customer Directory"),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: "Search by name or phone number",
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _loadUsers();
                              setState(() {});
                            },
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 14),

                // 3 Category Tabs (Active | Blocked by Admin | Deleted by Customer)
                Row(
                  children: [
                    Expanded(
                      child: _buildTabButton(
                        label: "Active",
                        count: activeUsers.length,
                        isSelected: _selectedTab == "active",
                        activeColor: const Color(0xFF30D158),
                        onTap: () {
                          setState(() {
                            _selectedTab = "active";
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildTabButton(
                        label: "Blocked",
                        count: blockedUsers.length,
                        isSelected: _selectedTab == "blocked",
                        activeColor: const Color(0xFFFF9F0A),
                        onTap: () {
                          setState(() {
                            _selectedTab = "blocked";
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildTabButton(
                        label: "Deleted",
                        count: deletedUsers.length,
                        isSelected: _selectedTab == "deleted",
                        activeColor: const Color(0xFFFF453A),
                        onTap: () {
                          setState(() {
                            _selectedTab = "deleted";
                          });
                        },
                      ),
                    ),
                  ],
                ),
                if (_selectedTab == "blocked" && blockedUsers.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent, width: 0.8),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.cleaning_services_outlined, size: 14),
                      label: const Text("Clear Blocked List", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      onPressed: _confirmClearBlockedList,
                    ),
                  ),
                ],
                const SizedBox(height: 14),

                // User List
                Expanded(
                  child: _buildUserList(displayedUsers),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required String label,
    required int count,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.15) : const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? activeColor : const Color(0xFF2C2C2E),
            width: isSelected ? 1.5 : 0.8,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? activeColor : Colors.grey,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? activeColor : Colors.grey.shade800,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserList(List<AdminUser> displayedUsers) {
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
              _error!.replaceFirst("Exception: ", ""),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007AFF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: _loadUsers,
              child: const Text(
                "Retry",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }

    if (displayedUsers.isEmpty) {
      String emptyMsg = "No active customers found";
      IconData emptyIcon = Icons.people_outline;
      if (_selectedTab == "blocked") {
        emptyMsg = "No admin-blocked users";
        emptyIcon = Icons.block_outlined;
      } else if (_selectedTab == "deleted") {
        emptyMsg = "No user-deleted accounts";
        emptyIcon = Icons.delete_forever_outlined;
      }

      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              emptyIcon,
              size: 48,
              color: Colors.grey,
            ),
            const SizedBox(height: 10),
            Text(
              emptyMsg,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: displayedUsers.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final user = displayedUsers[index];

          Color badgeColor;
          String badgeText;

          if (user.active) {
            badgeColor = Colors.green;
            badgeText = "Active";
          } else if (user.deletedByUser) {
            badgeColor = Colors.redAccent;
            badgeText = "Deleted Account";
          } else {
            badgeColor = Colors.orangeAccent;
            badgeText = "Blocked by Admin";
          }

          return Container(
            margin: const EdgeInsets.symmetric(vertical: 2),
            decoration: BoxDecoration(
              color: !user.active ? const Color(0xFF2C1C1E) : const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: !user.active ? badgeColor.withValues(alpha: 0.3) : const Color(0xFF2C2C2E),
                width: !user.active ? 1.0 : 0.5,
              ),
            ),
            child: ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 6,
              ),
              leading: CircleAvatar(
                radius: 20,
                backgroundColor: badgeColor.withValues(alpha: 0.2),
                child: Text(
                  user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : "?",
                  style: TextStyle(
                    color: badgeColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      user.fullName.isNotEmpty ? user.fullName : "Customer (ID: ${user.id})",
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: badgeColor.withValues(alpha: 0.4),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        color: badgeColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.phone_outlined, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          "Login Phone: ${user.phoneNumber}",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    if (user.email != null && user.email!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.email_outlined, size: 12, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              user.email!,
                              style: const TextStyle(
                                color: Color(0xFF8E8E93),
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              trailing: Transform.scale(
                scale: 0.8,
                child: Switch.adaptive(
                  value: user.active,
                  activeTrackColor: Colors.green,
                  onChanged: (val) => _toggleUserStatus(user),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}