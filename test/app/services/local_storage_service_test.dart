import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_play/app/app.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';

void main() {
  group('LocalStorageService', () {
    late LocalStorageRepository repository;
    late LocalStorageService service;

    setUpAll(registerFallbackValues);

    setUp(() {
      repository = MocktailLocalStorageRepository();
      service = LocalStorageService(localStorageRepository: repository);
    });

    test('initialize delegates to repository', () async {
      when(() => repository.initialize()).thenAnswer((_) async {});
      await service.initialize();
      verify(() => repository.initialize()).called(1);
    });

    test('saveLanguage delegates to repository', () {
      const locale = Locale('es');
      when(
        () => repository.saveLanguage(language: any(named: 'language')),
      ).thenReturn(null);
      service.saveLanguage(language: locale);
      verify(() => repository.saveLanguage(language: locale)).called(1);
    });

    test('getLanguage delegates to repository', () {
      const locale = Locale('en');
      when(() => repository.getLanguage()).thenReturn(locale);
      expect(service.getLanguage(), equals(locale));
      verify(() => repository.getLanguage()).called(1);
    });

    test('saveTheme delegates to repository', () {
      const theme = ThemeMode.dark;
      when(
        () => repository.saveTheme(theme: any(named: 'theme')),
      ).thenReturn(null);
      service.saveTheme(theme: theme);
      verify(() => repository.saveTheme(theme: theme)).called(1);
    });

    test('getTheme delegates to repository', () {
      const theme = ThemeMode.dark;
      when(() => repository.getTheme()).thenReturn(theme);
      expect(service.getTheme(), equals(theme));
      verify(() => repository.getTheme()).called(1);
    });

    test('saveBaseColor delegates to repository', () {
      const color = Colors.red;
      when(
        () => repository.saveBaseColor(baseColor: any(named: 'baseColor')),
      ).thenReturn(null);
      service.saveBaseColor(baseColor: color);
      verify(() => repository.saveBaseColor(baseColor: color)).called(1);
    });

    test('getBaseColor delegates to repository', () {
      const color = Colors.red;
      when(() => repository.getBaseColor()).thenReturn(color);
      expect(service.getBaseColor(), equals(color));
      verify(() => repository.getBaseColor()).called(1);
    });

    test('saveFontFamily delegates to repository', () {
      const font = 'Roboto';
      when(
        () => repository.saveFontFamily(fontFamily: any(named: 'fontFamily')),
      ).thenReturn(null);
      service.saveFontFamily(fontFamily: font);
      verify(() => repository.saveFontFamily(fontFamily: font)).called(1);
    });

    test('getFontFamily delegates to repository', () {
      const font = 'Roboto';
      when(() => repository.getFontFamily()).thenReturn(font);
      expect(service.getFontFamily(), equals(font));
      verify(() => repository.getFontFamily()).called(1);
    });
  });
}
