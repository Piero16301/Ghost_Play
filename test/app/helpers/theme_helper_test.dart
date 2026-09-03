import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_play/app/app.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group('ThemeHelper', () {
    test('getThemeName returns correct string', () {
      expect(ThemeHelper.getThemeName(ThemeMode.light), 'LIGHT');
      expect(ThemeHelper.getThemeName(ThemeMode.dark), 'DARK');
      expect(ThemeHelper.getThemeName(ThemeMode.system), 'SYSTEM');
    });

    test('getThemeByName returns correct mode', () {
      expect(ThemeHelper.getThemeByName('LIGHT'), ThemeMode.light);
      expect(ThemeHelper.getThemeByName('dark'), ThemeMode.dark);
      expect(ThemeHelper.getThemeByName('System'), ThemeMode.system);
    });

    test('getThemeByName returns light mode as default for unknown', () {
      expect(ThemeHelper.getThemeByName('unknown'), ThemeMode.light);
    });
  });
}
