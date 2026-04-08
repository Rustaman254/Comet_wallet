class ECitizenBill {
  final String name;
  final String currency;
  final double amount;
  final String refNo;

  ECitizenBill({
    required this.name,
    required this.currency,
    required this.amount,
    required this.refNo,
  });

  factory ECitizenBill.fromJson(Map<String, dynamic> json, String refNo) {
    return ECitizenBill(
      name: json['name'] ?? '',
      currency: json['currency'] ?? 'KES',
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      refNo: refNo,
    );
  }
}
