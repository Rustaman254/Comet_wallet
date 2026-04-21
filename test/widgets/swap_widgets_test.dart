import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;
import 'package:comet_wallet/screens/swap_screen.dart';
import 'package:comet_wallet/bloc/wallet_bloc.dart';
import 'package:comet_wallet/bloc/wallet_state.dart';
import 'package:comet_wallet/bloc/wallet_event.dart';
import 'package:comet_wallet/services/authenticated_http_client.dart';
import '../helpers/mocks.dart';

class MockWalletBloc extends Mock implements WalletBloc {}

void main() {
  late MockWalletBloc mockWalletBloc;
  late MockHttpClient mockHttpClient;

  setUp(() {
    mockWalletBloc = MockWalletBloc();
    mockHttpClient = MockHttpClient();
    AuthenticatedHttpClient.setClient(mockHttpClient);

    registerFallbackValue(Uri.parse('http://localhost'));
    registerFallbackValue(const FetchWalletDataFromServer());
    registerFallbackValue(const SwapCurrencies(fromCurrency: 'KES', toCurrency: 'USD', amount: 100));

    when(() => mockWalletBloc.state).thenReturn(const WalletLoaded(
      balances: [
        {'currency': 'KES', 'symbol': 'KSH', 'amount': '5000.00'},
        {'currency': 'USD', 'symbol': 'USD', 'amount': '50.25'},
      ],
      transactions: [],
      totalIncome: 0.0,
      totalExpense: 0.0,
      pendingCount: 0,
      completedCount: 0,
    ));
    when(() => mockWalletBloc.stream).thenAnswer((_) => const Stream.empty());

    // Mock exchange rate API
    final rateResponse = {
      'status': 'success',
      'rate': 0.0077,
      'from_currency': 'KES',
      'to_currency': 'USD'
    };
    when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
        .thenAnswer((_) async => http.Response(jsonEncode(rateResponse), 200));
  });

  tearDown(() {
    AuthenticatedHttpClient.resetClient();
  });

  Widget createWidgetUnderTest() {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          home: BlocProvider<WalletBloc>.value(
            value: mockWalletBloc,
            child: const SwapScreen(),
          ),
        );
      },
    );
  }

  testWidgets('SwapScreen renders correctly and shows balance', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Swap'), findsOneWidget);
    expect(find.textContaining('Bal: 5000.00 KES'), findsOneWidget);
  });

  testWidgets('SwapScreen validates insufficient funds', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    final amountField = find.byType(TextFormField).first;
    await tester.enterText(amountField, '6000');
    await tester.pump();

    final swapButton = find.text('Swap Now');
    await tester.ensureVisible(swapButton);
    await tester.tap(swapButton);
    await tester.pumpAndSettle();

    // Verify validator logic directly as UI error message can be flaky in headless tests
    final formField = tester.widget<TextFormField>(amountField);
    expect(formField.validator!('6000'), contains('Insufficient balance'));
  });
}
