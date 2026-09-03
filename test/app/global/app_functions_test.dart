import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_play/app/app.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group('AppFunctions', () {
    group('formatFileName', () {
      test('returns same name if no extension', () {
        const fileName = 'longfilenamewithoutdot';
        expect(AppFunctions.formatFileName(fileName), fileName);
      });

      test('returns same name if name is short', () {
        const fileName = 'short.txt';
        expect(AppFunctions.formatFileName(fileName), fileName);
      });

      test('shortens long file name correctly', () {
        const fileName =
            'thisis_a_very_long_file_name_that_should_be_shortened.mp3';
        final result = AppFunctions.formatFileName(fileName);
        expect(result, 'thisis_a_v..._shortened.mp3');
      });

      test('uses custom start and end counts', () {
        const fileName = 'shorten_me.txt';
        final result = AppFunctions.formatFileName(
          fileName,
          startCount: 3,
          endCount: 3,
        );
        expect(result, 'sho..._me.txt');
      });

      test('returns full name if short even with custom counts', () {
        const fileName = 'abc.txt';
        final result = AppFunctions.formatFileName(
          fileName,
          startCount: 5,
          endCount: 5,
        );
        expect(result, 'abc.txt');
      });
    });

    group('showSnackBar', () {
      testWidgets('shows snackbar with correct message and type (info)', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () => AppFunctions.showSnackBar(
                      context,
                      message: 'Test message',
                    ),
                    child: const Text('Show'),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show'));
        await tester.pump();

        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.text('Test message'), findsOneWidget);

        final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
        expect(snackBar.backgroundColor, Colors.blue);
        expect(find.byType(HugeIcon), findsOneWidget);
      });

      testWidgets('shows snackbar with success type', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () => AppFunctions.showSnackBar(
                      context,
                      message: 'Success!',
                      type: SnackBarType.success,
                    ),
                    child: const Text('Show'),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show'));
        await tester.pump();

        final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
        expect(snackBar.backgroundColor, Colors.green);
      });

      testWidgets('shows snackbar with error type', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () => AppFunctions.showSnackBar(
                      context,
                      message: 'Error!',
                      type: SnackBarType.error,
                    ),
                    child: const Text('Show'),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show'));
        await tester.pump();

        final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
        expect(snackBar.backgroundColor, Colors.red);
      });

      testWidgets('shows snackbar with warning type', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () => AppFunctions.showSnackBar(
                      context,
                      message: 'Warning!',
                      type: SnackBarType.warning,
                    ),
                    child: const Text('Show'),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show'));
        await tester.pump();

        final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
        expect(snackBar.backgroundColor, Colors.orange);
      });

      testWidgets('handles null message', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () => AppFunctions.showSnackBar(
                      context,
                    ),
                    child: const Text('Show'),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show'));
        await tester.pump();

        expect(find.text(''), findsOneWidget);
      });
    });
  });
}
