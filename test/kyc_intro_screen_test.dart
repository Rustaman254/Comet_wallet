import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comet_wallet/screens/kyc/kyc_intro_screen.dart';

void main() {
  testWidgets('KYCIntroScreen renders correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MaterialApp(
      home: KYCIntroScreen(),
    ));

    // Verify that the title is present.
    expect(find.text('Verify Your Identity'), findsOneWidget);

    // Verify that the description text is present.
    expect(find.textContaining('To protect your account'), findsOneWidget);

    // Verify that the "Start Verification" button is present.
    expect(find.text('Start Verification'), findsOneWidget);
    
    // Verify that the checklist attributes are present.
    expect(find.text('Higher transaction limits'), findsOneWidget);
    expect(find.text('Secure account recovery'), findsOneWidget);
    expect(find.text('Access to all financial tools'), findsOneWidget);

    // Verify that the Skip button is present.
    expect(find.text('Skip'), findsOneWidget);
  });
}
