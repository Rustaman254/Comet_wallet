class UserProfile {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String location;
  final bool kycVerified;
  final bool isAccountActivated;
  final bool activationFeePaid;
  final Map<String, dynamic> walletBalances;
  final String status;
  final UserRole? role;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.location,
    required this.kycVerified,
    required this.isAccountActivated,
    required this.activationFeePaid,
    required this.walletBalances,
    required this.status,
    this.role,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      location: json['location'] ?? '',
      kycVerified: json['kyc_verified'] ?? false,
      isAccountActivated: json['is_account_activated'] ?? false,
      activationFeePaid: json['activation_fee_paid'] ?? false,
      walletBalances: json['wallet_balances'] != null 
          ? Map<String, dynamic>.from(json['wallet_balances']) 
          : {},
      status: json['status'] ?? '',
      role: json['role'] != null ? UserRole.fromJson(json['role']) : null,
    );
  }
}

class UserRole {
  final int id;
  final String name;
  final String description;
  final String permissions;
  final String status;

  UserRole({
    required this.id,
    required this.name,
    required this.description,
    required this.permissions,
    required this.status,
  });

  factory UserRole.fromJson(Map<String, dynamic> json) {
    return UserRole(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      permissions: json['permissions'] ?? '',
      status: json['status'] ?? '',
    );
  }
}
