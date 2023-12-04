import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:whatahoot/pages/join_game.dart';

void main() {
  testWidgets('Verify Join Game page', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const MaterialApp(
        home: JoinGamePage(),
      )
    );

    final pageTitle = find.text("Join Game");

    final nickNameWidget = find.ancestor(
        of: find.text("Enter Nickname"),
        matching: find.byType(TextField)
    );

    final joinCodeWidget = find.ancestor(
        of: find.text("Enter Join Code"),
        matching: find.byType(TextField)
    );

    final joinButtonWidget = find.ancestor(
        of: find.text("Join"),
        matching: find.byType(ElevatedButton)
    );

    // Verify EditTexts and buttons
    expect(pageTitle, findsOneWidget);
    expect(joinButtonWidget, findsOneWidget);
    expect(nickNameWidget, findsOneWidget);
    expect(joinCodeWidget, findsOneWidget);

    await tester.enterText(nickNameWidget, "123456789");
    expect(find.text("12345678"), findsOneWidget);
  });
}