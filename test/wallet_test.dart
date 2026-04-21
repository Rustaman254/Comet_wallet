import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;
import 'package:comet_wallet/services/wallet_service.dart';
import 'package:comet_wallet/services/authenticated_http_client.dart';
import 'package:comet_wallet/constants/api_constants.dart';
import 'helpers/mocks.dart';

void main() {
  late MockHttpClient mockHttpClient;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({
      'auth_token': 'fake_token',
      'user_id': '123',
      'user_email': 'test@example.com'
    });
    mockHttpClient = MockHttpClient();
    registerFallbackValue(Uri.parse('http://localhost'));
    AuthenticatedHttpClient.setClient(mockHttpClient);
  });

  tearDown(() {
    AuthenticatedHttpClient.resetClient();
  });

  tearDown(() {
    AuthenticatedHttpClient.resetClient();
  });

  group('WalletService - getWalletBalance', () {
    test('Success fetch - parses KES and USD accurately', () async {
      final mockResponse = {
        'wallets': [
          {'currency': 'KES', 'balance': 5000.0, 'ID': 1},
          {'currency': 'USD', 'balance': 50.25, 'ID': 2},
        ],
        'balances': {
          'KES': 5000.0,
          'USD': 50.25,
        },
        'user_id': 123,
        'status': 'success'
      };

      when(() => mockHttpClient.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => http.Response(jsonEncode(mockResponse), 200));

      final result = await WalletService.getWalletBalance();

      expect(result['balances']['KES'], 5000.0);
      expect(result['balances']['USD'], 50.25);
      expect(result['wallets'].length, 2);
    });

    test('Empty balances - returns empty structure', () async {
      final mockResponse = {
        'wallets': [],
        'balances': {},
        'status': 'success'
      };

      when(() => mockHttpClient.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => http.Response(jsonEncode(mockResponse), 200));

      final result = await WalletService.getWalletBalance();

      expect(result['balances'], isEmpty);
      expect(result['wallets'], isEmpty);
    });
  });

  group('WalletService - swapCurrencies', () {
    test('Success Swap', () async {
      final mockResponse = {
        'status': 'success',
        'message': 'Swap complete',
        'amount_credited': 10.0,
        'from_currency': 'KES',
        'to_currency': 'USD',
        'balance_usda': 10.0,
        'balances': {'KES': 4000.0, 'USD': 60.25}
      };

      when(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response(jsonEncode(mockResponse), 200));

      final result = await WalletService.swapCurrencies(
        fromCurrency: 'KES',
        toCurrency: 'USD',
        amount: 1000.0,
      );

      expect(result['status'], 'success');
      expect(result['amount_credited'], 10.0);
    });

    test('Insufficient funds fail (400)', () async {
      when(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response(jsonEncode({'message': 'Insufficient balance'}), 400));

      expect(
        () => WalletService.swapCurrencies(
          fromCurrency: 'KES',
          toCurrency: 'USD',
          amount: 100000.0,
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
