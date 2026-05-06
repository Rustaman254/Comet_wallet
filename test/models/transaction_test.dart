import 'package:flutter_test/flutter_test.dart';
import 'package:comet_wallet/models/transaction.dart';

void main() {
  group('Transaction Model Tests', () {
    test('should parse createdAt from different keys', () {
      final json1 = {
        'id': 1,
        'user_id': 22,
        'amount': 150.0,
        'transaction_type': 'mobile_transfer',
        'status': 'pending',
        'phone_number': '254712345678',
        'createdAt': '2026-04-21T09:33:50.934Z',
        'currency': 'KES',
        'transaction_id': 'TX123'
      };

      final json2 = {
        'id': 1,
        'user_id': 22,
        'amount': 150.0,
        'transaction_type': 'mobile_transfer',
        'status': 'pending',
        'phone_number': '254712345678',
        'created_at': '2026-04-21T10:00:00.000Z',
        'currency': 'KES',
        'transaction_id': 'TX124'
      };

      final json3 = {
        'id': 1,
        'user_id': 22,
        'amount': 150.0,
        'transaction_type': 'mobile_transfer',
        'status': 'pending',
        'phone_number': '254712345678',
        'created at': '2026-04-21T11:00:00.000Z',
        'currency': 'KES',
        'transaction_id': 'TX125'
      };

      final t1 = Transaction.fromJson(json1);
      final t2 = Transaction.fromJson(json2);
      final t3 = Transaction.fromJson(json3);

      expect(t1.createdAt.year, 2026);
      expect(t1.createdAt.month, 4);
      expect(t1.createdAt.day, 21);

      expect(t2.createdAt.hour, 10);
      expect(t3.createdAt.hour, 11);
    });
  });
}
