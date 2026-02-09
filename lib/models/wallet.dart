class Wallet {
  final int id;
  final int userId;
  final String currency;
  final double balance;
  final DateTime createdAt;
  final DateTime updatedAt;

  Wallet({
    required this.id,
    required this.userId,
    required this.currency,
    required this.balance,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: json['ID'] ?? 0,
      userId: json['user_id'] ?? 0,
      currency: json['currency'] ?? '',
      balance: (json['balance'] ?? 0).toDouble(),
      createdAt: json['CreatedAt'] != null 
          ? DateTime.parse(json['CreatedAt']) 
          : DateTime.now(),
      updatedAt: json['UpdatedAt'] != null 
          ? DateTime.parse(json['UpdatedAt']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ID': id,
      'user_id': userId,
      'currency': currency,
      'balance': balance,
      'CreatedAt': createdAt.toIso8601String(),
      'UpdatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Get currency symbol
  String get currencySymbol {
    switch (currency) {
      case 'USD':
        return 'USD';
      case 'EUR':
        return 'EUR';
      case 'GBP':
        return 'GBP';
      case 'KES':
        return 'KSH';
      case 'UGX':
        return 'UGX';
      case 'TZS':
        return 'TZS';
      case 'RWF':
        return 'RWF';
      case 'ZAR':
        return 'ZAR';
      default:
        return currency;
    }
  }

  /// Get formatted balance with currency symbol
  String get formattedBalance {
    return '$currencySymbol ${balance.toStringAsFixed(2)}';
  }

  @override
  String toString() {
    return 'Wallet(id: $id, currency: $currency, balance: $balance)';
  }
}
