import 'user_profile.dart';

class TransactionResponse {
  final String message;
  final String status;
  final List<Transaction> transactions;

  TransactionResponse({
    required this.message,
    required this.status,
    required this.transactions,
  });

  factory TransactionResponse.fromJson(Map<String, dynamic> json) {
    return TransactionResponse(
      message: json['message'] ?? '',
      status: json['status'] ?? '',
      transactions: (json['transactions'] as List?)
              ?.map((t) => Transaction.fromJson(t))
              .toList() ??
          [],
    );
  }
}

class Transaction {
  final int id;
  final int userID;
  final double amount;
  final String phoneNumber;
  final String status;
  final String transactionType;
  final int? ownershipID;
  final dynamic ownership;
  final TransactionUser? user;
  final String? explorerLink;
  final String transactionId;
  final DateTime createdAt;
  final String currency;

  Transaction({
    required this.id,
    required this.userID,
    required this.amount,
    required this.phoneNumber,
    required this.status,
    required this.transactionType,
    this.ownershipID,
    this.ownership,
    this.user,
    this.explorerLink,
    required this.transactionId,
    required this.createdAt,
    required this.currency,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      if (json['CreatedAt'] != null) {
        parsedDate = DateTime.parse(json['CreatedAt']);
      } else if (json['created_at'] != null) {
        parsedDate = DateTime.parse(json['created_at']);
      } else {
        parsedDate = DateTime.now();
      }
    } catch (e) {
      parsedDate = DateTime.now();
    }

    return Transaction(
      id: json['id'] ?? 0,
      userID: json['userID'] ?? 0,
      amount: (json['amount'] is num) ? (json['amount'] as num).toDouble() : 0.0,
      phoneNumber: json['phoneNumber'] ?? '',
      status: json['status'] ?? '',
      transactionType: json['transactionType'] ?? '',
      ownershipID: json['OwnershipID'],
      ownership: json['ownership'],
      user: json['user'] != null ? TransactionUser.fromJson(json['user']) : null,
      explorerLink: json['explorerLink'],
      transactionId: json['transactionId'] ?? '',
      createdAt: parsedDate,
      currency: json['currency'] ?? 'KES',
    );
  }
}

class TransactionUser {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String location;
  final String publicKey;
  final bool kycVerified;
  final bool isAccountActivated;
  final bool activationFeePaid;
  final String status;
  final int roleID;
  final UserRole? role;
  final String token;

  TransactionUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.location,
    required this.publicKey,
    required this.kycVerified,
    required this.isAccountActivated,
    required this.activationFeePaid,
    required this.status,
    required this.roleID,
    this.role,
    required this.token,
  });

  factory TransactionUser.fromJson(Map<String, dynamic> json) {
    return TransactionUser(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      location: json['location'] ?? '',
      publicKey: json['public_key'] ?? '',
      kycVerified: json['kyc_verified'] ?? false,
      isAccountActivated: json['is_account_activated'] ?? false,
      activationFeePaid: json['activation_fee_paid'] ?? false,
      status: json['status'] ?? '',
      roleID: json['RoleID'] ?? 0,
      role: json['role'] != null ? UserRole.fromJson(json['role']) : null,
      token: json['token'] ?? '',
    );
  }
}
