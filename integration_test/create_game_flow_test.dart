import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:whatahoot2/firebase_options.dart';
import 'package:whatahoot2/main.dart';
import 'package:whatahoot2/pages/creategame.dart';
import 'package:whatahoot2/pages/joingame.dart';


void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('end-to-end test verify Create Game QR', (WidgetTester tester) async {

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Build our app and trigger a frame.
    await tester.pumpWidget(
        const MyApp()
    );

    final createGameButtonWidget = find.ancestor(
        of: find.text("Create Game"),
        matching: find.byType(ElevatedButton)
    );

    await tester.tap(createGameButtonWidget);

    await tester.pumpWidget(
        const MaterialApp(
          home: CreateGamePage(),
        )
    );

    final pageTitle = find.text("Create Game");

    final nickNameWidget = find.ancestor(
        of: find.text("Enter A Nickname"),
        matching: find.byType(TextField)
    );

    final hootyButtonWidget = find.ancestor(
        of: find.text("WhataCaption!"),
        matching: find.byType(ElevatedButton)
    );

    // Verify text and buttons
    expect(pageTitle, findsOneWidget);
    expect(hootyButtonWidget, findsOneWidget);
    expect(nickNameWidget, findsOneWidget);

    // Emulate a tap on the action button
    await tester.tap(hootyButtonWidget);

    await tester.pumpWidget(
        const MaterialApp(
          home: JoinGamePage(),
        )
    );

    // Trigger a frame.
    await tester.pumpAndSettle();

    final qrImageWidget = find.byType(QrImageView);
    final qrTextCode = find.byType(Text);

    final continueButtonWidget = find.ancestor(
        of: find.text("Continue"),
        matching: find.byType(ElevatedButton)
    );

    // Verify text and buttons
    expect(qrImageWidget, findsOneWidget);
    expect(qrTextCode, findsAtLeastNWidgets(1));
    expect(continueButtonWidget, findsOneWidget);

  });
}