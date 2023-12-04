import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:whatahoot2/firebase_options.dart';
import 'package:whatahoot2/main.dart';
import 'package:whatahoot2/pages/joingame.dart';
import 'package:whatahoot2/pages/whatacaption/caption.dart';
import 'package:whatahoot2/pages/whatacaption/upload.dart';
import 'package:whatahoot2/pages/whatacaption/vote.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Verify Create Whata caption', (WidgetTester tester) async {

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Build our app and trigger a frame.
    await tester.pumpWidget(
        const MyApp()
    );

    final joinGameButtonWidget = find.ancestor(
        of: find.text("Join Game"),
        matching: find.byType(ElevatedButton)
    );
    await tester.tap(joinGameButtonWidget);

    // Build our app and trigger a frame.
    await tester.pumpWidget(
        const MaterialApp(
          home: JoinGamePage(),
        )
    );
    final joinButtonWidget = find.ancestor(
        of: find.text("Join"),
        matching: find.byType(ElevatedButton)
    );
    await tester.tap(joinButtonWidget);

    // Build our app and trigger a frame.
    await tester.pumpWidget(
        const MaterialApp(
          home: UploadPage(),
        )
    );

    final pageTitle = find.text("WhataCaption!");

    final uploadButtonWidget = find.text("Upload");

    final continueButtonWidget = find.ancestor(
        of: find.text("Continue"),
        matching: find.byType(ElevatedButton)
    );

    // Verify text and buttons
    expect(pageTitle, findsOneWidget);
    expect(uploadButtonWidget, findsOneWidget);
    expect(continueButtonWidget, findsOneWidget);

    // Build our app and trigger a frame.
    await tester.pumpWidget(
        const MaterialApp(
          home: CaptionPage(),
        )
    );

    final pageCaptionTitle = find.text("Caption!");

    final captionTextFieldWidget = find.ancestor(
        of: find.text("Enter Caption"),
        matching: find.byType(TextField)
    );

    final letsButtonWidget = find.ancestor(
        of: find.text("Let's Go!"),
        matching: find.byType(ElevatedButton)
    );

    // Verify text and buttons
    expect(pageCaptionTitle, findsOneWidget);
    expect(letsButtonWidget, findsOneWidget);
    expect(captionTextFieldWidget, findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Build our app and trigger a frame.
    await tester.pumpWidget(
        const MaterialApp(
          home: VotePage(),
        )
    );

    final pageVoteTitle = find.text("Vote!");

    // Verify text and buttons
    expect(pageVoteTitle, findsOneWidget);
    expect(find.byType(Text), findsAtLeastNWidgets(1));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

  });
}