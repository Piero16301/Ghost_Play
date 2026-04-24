import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_play/app/app.dart';

void main() {
  group('AppVariables', () {
    test('constants are correct', () {
      expect(AppVariables.appName, 'Ghost Play');
      expect(AppVariables.defaultBaseColor, isA<Color>());
      expect(AppVariables.defaultFontFamily, 'Poppins');
      expect(AppVariables.tabletMaxWidth, 500.0);
      expect(AppVariables.tabletMaxHeight, 400.0);
      expect(AppVariables.waVoiceNotesPath, isNotNull);
    });

    test('formatDateTime is initialized', () {
      expect(AppVariables.formatDateTime, isNotNull);
      final date = DateTime(2023, 10, 27, 14, 30);

      expect(AppVariables.formatDateTime.format(date), '27/10/2023 02:30 PM');
    });

    test('weeksOptions is correct', () {
      expect(AppVariables.weeksOptions, [1, 2, 3, 4, 5, 6, 7, 8]);
    });

    test('availableFonts is initialized and has many entries', () {
      expect(AppVariables.availableFonts, isNotEmpty);
      expect(AppVariables.availableFonts.length, greaterThan(5));
      expect(AppVariables.availableFonts['Poppins'], 'Poppins');
    });

    test('getAvailableFonts returns the same map content', () {
      final fonts = AppVariables.getAvailableFonts();
      expect(fonts, equals(AppVariables.availableFonts));
    });

    test('supportedLocales is correct', () {
      expect(AppVariables.supportedLocales, [
        const Locale('en', 'US'),
        const Locale('es', 'ES'),
        const Locale('it', 'IT'),
      ]);
    });
  });

  group('SnackBarType', () {
    test('getters return correct values', () {
      expect(SnackBarType.success.isSuccess, isTrue);
      expect(SnackBarType.success.isError, isFalse);
      expect(SnackBarType.success.isWarning, isFalse);
      expect(SnackBarType.success.isInfo, isFalse);

      expect(SnackBarType.error.isSuccess, isFalse);
      expect(SnackBarType.error.isError, isTrue);
      expect(SnackBarType.error.isWarning, isFalse);
      expect(SnackBarType.error.isInfo, isFalse);

      expect(SnackBarType.warning.isSuccess, isFalse);
      expect(SnackBarType.warning.isError, isFalse);
      expect(SnackBarType.warning.isWarning, isTrue);
      expect(SnackBarType.warning.isInfo, isFalse);

      expect(SnackBarType.info.isSuccess, isFalse);
      expect(SnackBarType.info.isError, isFalse);
      expect(SnackBarType.info.isWarning, isFalse);
      expect(SnackBarType.info.isInfo, isTrue);
    });
  });
}
