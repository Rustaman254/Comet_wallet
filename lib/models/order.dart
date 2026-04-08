class Order {
  final int id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String externalRef;
  final String commentRef;
  final String payerEmail;
  final int userId;
  final double amount;
  final String currency;
  final String status;
  final String description;
  final String callbackUrl;

  Order({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.externalRef,
    required this.commentRef,
    required this.payerEmail,
    required this.userId,
    required this.amount,
    required this.currency,
    required this.status,
    required this.description,
    required this.callbackUrl,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['ID'] ?? 0,
      createdAt: DateTime.parse(json['CreatedAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['UpdatedAt'] ?? DateTime.now().toIso8601String()),
      externalRef: json['external_ref'] ?? '',
      commentRef: json['comment_ref'] ?? '',
      payerEmail: json['payer_email'] ?? '',
      userId: json['user_id'] ?? 0,
      amount: (json['amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? '',
      status: json['status'] ?? '',
      description: json['description'] ?? '',
      callbackUrl: json['callback_url'] ?? '',
    );
  }
}
