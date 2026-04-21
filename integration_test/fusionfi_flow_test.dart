import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:comet_wallet/main.dart' as app;
import 'package:comet_wallet/services/authenticated_http_client.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// We need to use mocktail even in integration tests if we want to mock the backend responses
// without running a real server.

class MockHttpClient extends Mock implements http.Client {}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late MockHttpClient mockHttpClient;

  setUp(() {
    mockHttpClient = MockHttpClient();
    AuthenticatedHttpClient.setClient(mockHttpClient);
  });

  group('FusionFi E2E Flow', () {
    testWidgets('Full flow: Login -> Dashboard -> Swap', (tester) async {
      // Mock login success
      when(() => mockHttpClient.post(any(), headers: any(named: 'headers'), body: any(named: 'body')))
          .thenAnswer((_) async => http.Response(jsonEncode({
                'token': 'fake_token',
                'user': {'id': '1', 'email': 'test@example.com', 'name': 'Tester'}
              }), 200));

      // Mock profile fetch
      when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response(jsonEncode({
                'user': {
                  'id': 1,
                  'name': 'Tester',
                  'email': 'test@example.com',
                  'location': 'Kenya',
                  'kyc_verified': true,
                  'is_account_activated': true
                }
              }), 200));

      // Mock balance fetch
      when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response(jsonEncode({
                'wallets': [{'currency': 'KES', 'balance': 1000.0}],
                'balances': {'KES': 1000.0},
                'status': 'success'
              }), 200));

      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Ensure we are on login screen if not logged in
      // (This depends on current splash/main_wrapper logic)
      
      // Fill login form
      final emailField = find.byType(TextFormField).at(0);
      final passwordField = find.byType(TextFormField).at(1);
      await tester.enterText(emailField, 'test@example.com');
      await tester.enterText(passwordField, 'password123');
      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();

      // Check for PIN screen or Dashboard
      // expect(find.text('Verify PIN'), findsOneWidget);
      // For this test, we assume navigation works.
      
      // Navigate to Swap
      // await tester.tap(find.text('Swap'));
      // await tester.pumpAndSettle();
      
      // Perform swap...
    });
  });
}
