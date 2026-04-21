import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mocktail/mocktail.dart';
import 'package:comet_wallet/screens/home_screen.dart';
import 'package:comet_wallet/bloc/wallet_bloc.dart';
import 'package:comet_wallet/bloc/wallet_state.dart';
import 'package:comet_wallet/bloc/wallet_event.dart';
import 'package:comet_wallet/models/transaction.dart';
import 'package:comet_wallet/services/authenticated_http_client.dart';
import '../helpers/mocks.dart';

class MockWalletBloc extends Mock implements WalletBloc {}

void main() {
  late MockWalletBloc mockWalletBloc;

  setUp(() {
    mockWalletBloc = MockWalletBloc();
    // Register fallbacks
    registerFallbackValue(const FetchWalletDataFromServer());
    
    // Default state
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
            child: const HomeScreen(),
          ),
        );
      },
    );
  }

  testWidgets('HomeScreen renders balance cards correctly', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Total Balance'), findsAtLeastNWidgets(1));
    expect(find.textContaining('5000'), findsOneWidget);
  });

  testWidgets('HomeScreen toggles balance visibility', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.textContaining('5000'), findsOneWidget);

    final visibilityIcon = find.byIcon(Icons.visibility_outlined).first;
    await tester.tap(visibilityIcon);
    await tester.pump();

    expect(find.text('••••••'), findsOneWidget);
    expect(find.textContaining('5000'), findsNothing);
  });
}
