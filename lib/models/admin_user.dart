class AdminUser {
  final int id;
  final String fullName;
  final String phoneNumber;
  final String? email;
  final bool active;

  AdminUser({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    this.email,
    required this.active,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json["id"],
      fullName: json["fullName"] ?? "",
      phoneNumber: json["phoneNumber"] ?? "",
      email: json["email"],
      active: json["active"] ?? false,
    );
  }
}