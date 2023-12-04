import 'package:flutter_test/flutter_test.dart';
import 'package:whatahoot2/main.dart';

void main() {
  testWidgets('Verfify main page', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify Create and Join Game.
    expect(find.text("Whatahoot!"), findsWidgets);
    expect(find.text("Join Game"), findsOneWidget);
    expect(find.text("Create Game"), findsOneWidget);

  });
}