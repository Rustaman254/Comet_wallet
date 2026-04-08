import 'package:flutter_test/flutter_test.dart';
import 'package:comet_wallet/models/transaction.dart';
import 'dart:convert';

void main() {
  group('Transaction Model Tests', () {
    test('Correctly parses transaction list JSON', () {
      const jsonString = '''
      {
        "message": "Transactions fetched successfully",
        "status": "success",
        "transactions": [
          {
            "OwnershipID": null,
            "amount": 2,
            "id": 144,
            "ownership": null,
            "phoneNumber": "254710865696",
            "status": "failed",
            "transactionType": "wallet_topup",
            "user": {
              "id": 127,
              "name": "Test User",
              "email": "test@example.com"
            },
            "userID": 127
          }
        ]
      }
      ''';

      final Map<String, dynamic> jsonData = jsonDecode(jsonString);
      final response = TransactionResponse.fromJson(jsonData);

      expect(response.status, 'success');
      expect(response.transactions.length, 1);
      
      final transaction = response.transactions.first;
      expect(transaction.id, 144);
      expect(transaction.amount, 2.0);
      expect(transaction.status, 'failed');
      expect(transaction.transactionType, 'wallet_topup');
      expect(transaction.user?.id, 127);
    });

    test('Handles null fields gracefully', () {
      final Map<String, dynamic> jsonData = {
        "id": 1,
        "amount": 10.0,
        "status": "pending"
      };
      
      final transaction = Transaction.fromJson(jsonData);
      expect(transaction.id, 1);
      expect(transaction.amount, 10.0);
      expect(transaction.status, 'pending');
      expect(transaction.phoneNumber, '');
      expect(transaction.transactionType, '');
    });
  });
}
