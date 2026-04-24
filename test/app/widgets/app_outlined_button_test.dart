import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_play/app/app.dart';
import 'package:hugeicons/hugeicons.dart';

void main() {
  group('AppOutlinedButton', () {
    testWidgets('renders icon and label correctly', (tester) async {
      var pressed = false;
      const iconData = HugeIcons.strokeRoundedAdd01;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppOutlinedButton(
              onPressed: () => pressed = true,
              icon: iconData,
              label: 'Add',
            ),
          ),
        ),
      );

      expect(find.byType(HugeIcon), findsOneWidget);
      expect(find.text('Add'), findsOneWidget);

      await tester.tap(find.byType(AppOutlinedButton));
      expect(pressed, isTrue);
    });

    testWidgets('renders without icon when icon is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppOutlinedButton(
              label: 'Only Text',
            ),
          ),
        ),
      );

      expect(find.byType(HugeIcon), findsNothing);
      expect(find.text('Only Text'), findsOneWidget);
    });

    testWidgets('renders with custom padding', (tester) async {
      const customPadding = EdgeInsets.all(20);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppOutlinedButton(
              label: 'Custom',
              innerPadding: customPadding,
            ),
          ),
        ),
      );

      final outlinedButton = tester.widget<OutlinedButton>(
        find.byType(OutlinedButton),
      );
      final style = outlinedButton.style!;

      expect(style.padding!.resolve({}), customPadding);
    });

    testWidgets('handles null label correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppOutlinedButton(),
          ),
        ),
      );

      expect(find.text(''), findsOneWidget);
    });
  });
}
