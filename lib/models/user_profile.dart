class UserProfile {
  final String fullName;
  final String? email;
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;
  final String? landmark;

  UserProfile({
    required this.fullName,
    this.email,
    this.address,
    this.city,
    this.state,
    this.pincode,
    this.landmark,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      fullName: json['fullName'] ?? '',
      email: json['email'],
      address: json['address'],
      city: json['city'],
      state: json['state'],
      pincode: json['pincode'],
      landmark: json['landmark'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'email': email,
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
      'landmark': landmark,
    };
  }
}
