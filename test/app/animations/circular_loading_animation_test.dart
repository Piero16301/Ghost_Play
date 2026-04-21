import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_play/app/app.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('CircularLoadingAnimation', () {
    const outerColor = Colors.blue;
    const innerColor = Colors.red;
    const backgroundColor = Colors.black;

    testWidgets('renders correctly with given colors and size', (tester) async {
      await tester.pumpApp(
        const CircularLoadingAnimation(
          outerCircleColor: outerColor,
          innerCircleColor: innerColor,
          backgroundColor: backgroundColor,
          size: 150,
        ),
      );

      final containerFinder = find.byType(Container);
      expect(containerFinder, findsOneWidget);

      final container = tester.widget<Container>(containerFinder);
      expect(container.constraints?.maxWidth, 150.0);
      expect(container.constraints?.maxHeight, 150.0);

      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color, backgroundColor);
      expect(decoration.shape, BoxShape.circle);
    });

    testWidgets('renders centerWidget when provided', (tester) async {
      const centerText = 'Testing';
      await tester.pumpApp(
        const CircularLoadingAnimation(
          outerCircleColor: outerColor,
          innerCircleColor: innerColor,
          backgroundColor: backgroundColor,
          centerWidget: Text(centerText),
        ),
      );

      expect(find.text(centerText), findsOneWidget);
    });

    testWidgets('does not render centerWidget when null', (tester) async {
      await tester.pumpApp(
        const CircularLoadingAnimation(
          outerCircleColor: outerColor,
          innerCircleColor: innerColor,
          backgroundColor: backgroundColor,
        ),
      );

      expect(find.byType(Text), findsNothing);
    });

    testWidgets('disposes correctly', (tester) async {
      await tester.pumpApp(
        const CircularLoadingAnimation(
          outerCircleColor: outerColor,
          innerCircleColor: innerColor,
          backgroundColor: backgroundColor,
        ),
      );

      expect(find.byType(CircularLoadingAnimation), findsOneWidget);

      await tester.pumpApp(const SizedBox());

      expect(find.byType(CircularLoadingAnimation), findsNothing);
    });

    group('LoadingPainter', () {
      test('shouldRepaint returns true when progress changes', () {
        final painter = LoadingPainter(
          progress: 0.5,
          outerColor: outerColor,
          innerColor: innerColor,
        );
        final oldPainter = LoadingPainter(
          progress: 0.4,
          outerColor: outerColor,
          innerColor: innerColor,
        );

        expect(painter.shouldRepaint(oldPainter), isTrue);
      });

      test('shouldRepaint returns true when outerColor changes', () {
        final painter = LoadingPainter(
          progress: 0.5,
          outerColor: outerColor,
          innerColor: innerColor,
        );
        final oldPainter = LoadingPainter(
          progress: 0.5,
          outerColor: Colors.green,
          innerColor: innerColor,
        );

        expect(painter.shouldRepaint(oldPainter), isTrue);
      });

      test('shouldRepaint returns true when innerColor changes', () {
        final painter = LoadingPainter(
          progress: 0.5,
          outerColor: outerColor,
          innerColor: innerColor,
        );
        final oldPainter = LoadingPainter(
          progress: 0.5,
          outerColor: outerColor,
          innerColor: Colors.green,
        );

        expect(painter.shouldRepaint(oldPainter), isTrue);
      });

      test('shouldRepaint returns false when all properties are same', () {
        final painter = LoadingPainter(
          progress: 0.5,
          outerColor: outerColor,
          innerColor: innerColor,
        );
        final oldPainter = LoadingPainter(
          progress: 0.5,
          outerColor: outerColor,
          innerColor: innerColor,
        );

        expect(painter.shouldRepaint(oldPainter), isFalse);
      });
    });
  });
}
