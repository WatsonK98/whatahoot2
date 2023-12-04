import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whatahoot2/pages/creategame.dart';

void main() {
  testWidgets('Verify Create Game page', (WidgetTester tester) async {
    // Build our app and trigger a frame.
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

    await tester.enterText(nickNameWidget, "123456789");
    expect(find.text("12345678"), findsOneWidget);
  });
}