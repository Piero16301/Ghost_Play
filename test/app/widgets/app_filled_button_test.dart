import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_play/app/app.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group('AppFilledButton', () {
    testWidgets('renders icon and label correctly', (tester) async {
      var pressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppFilledButton(
              onPressed: () => pressed = true,
              icon: const Icon(Icons.add),
              label: 'Add',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.text('Add'), findsOneWidget);

      await tester.tap(find.byType(AppFilledButton));
      expect(pressed, isTrue);
    });

    testWidgets('renders only icon when isOnlyIcon is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppFilledButton(
              onPressed: () {},
              icon: const Icon(Icons.add),
              isOnlyIcon: true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('renders with custom color and padding', (tester) async {
      const customColor = Colors.red;
      const customPadding = EdgeInsets.all(20);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppFilledButton(
              onPressed: () {},
              label: 'Custom',
              icon: const Icon(Icons.add),
              color: customColor,
              innerPadding: customPadding,
            ),
          ),
        ),
      );

      final filledButton = tester.widget<FilledButton>(
        find.byType(FilledButton),
      );
      final style = filledButton.style!;

      expect(style.backgroundColor!.resolve({}), customColor);
      expect(style.padding!.resolve({}), customPadding);
    });

    testWidgets('handles null label by using icon as label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppFilledButton(
              onPressed: () {},
              icon: const Icon(Icons.add),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.add), findsNWidgets(2));
    });
  });
}
