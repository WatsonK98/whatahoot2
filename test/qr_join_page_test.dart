import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:whatahoot/firebase_options.dart';
import 'package:whatahoot/main.dart';
import 'package:whatahoot/pages/qr_join.dart';

void main() {
  //Remove this test
  testWidgets('Verify QR join page', (WidgetTester tester) async {

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Build our app and trigger a frame.
    await tester.pumpWidget(
        const MyApp()
    );

    // Build our app and trigger a frame.
    await tester.pumpWidget(
        const MaterialApp(
          home: QRJoinPage(),
        )
    );

    final pageTitle = find.text("Create Game");
    final qrImageWidget = find.byType(QrImageView);
    final qrTextCode = find.byType(Text);

    final continueButtonWidget = find.ancestor(
        of: find.text("Continue"),
        matching: find.byType(ElevatedButton)
    );

    // Verify text and buttons
    expect(pageTitle, findsOneWidget);
    expect(qrImageWidget, findsOneWidget);
    expect(qrTextCode, findsAtLeastNWidgets(1));
    expect(continueButtonWidget, findsOneWidget);

  });
}