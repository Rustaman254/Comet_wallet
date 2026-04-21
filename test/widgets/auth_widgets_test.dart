import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:comet_wallet/screens/sign_in_screen.dart';
import 'package:comet_wallet/services/authenticated_http_client.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;
import '../helpers/mocks.dart';

void main() {
  late MockHttpClient mockHttpClient;

  setUp(() {
    mockHttpClient = MockHttpClient();
    AuthenticatedHttpClient.setClient(mockHttpClient);
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
        return const MaterialApp(
          home: SignInScreen(),
        );
      },
    );
  }

  testWidgets('SignInScreen has email and password fields', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Email address or mobile number'), findsAtLeastNWidgets(1));
    expect(find.text('Password'), findsOneWidget);
  });

  testWidgets('SignInScreen shows error when inputs are empty', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    final signInButton = find.text('Sign in');
    await tester.tap(signInButton);
    // Wait for validation error and toast
    await tester.pumpAndSettle(const Duration(seconds: 5));

    expect(find.text('Please enter your email'), findsOneWidget);
    expect(find.text('Please enter your password'), findsOneWidget);
  });

  testWidgets('SignInScreen toggles password visibility', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    final passwordField = find.byType(TextFormField).last;
    expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    
    final visibilityIcon = find.byIcon(Icons.visibility_outlined);
    await tester.ensureVisible(visibilityIcon);
    await tester.tap(visibilityIcon);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
  });
}
