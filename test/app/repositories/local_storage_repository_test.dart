import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_play/app/app.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SharedPrefsLocalStorageRepository', () {
    late MockSharedPreferences prefs;
    late SharedPrefsLocalStorageRepository repository;

    setUp(() {
      prefs = MockSharedPreferences();
      repository = SharedPrefsLocalStorageRepository(prefs: prefs);
    });

    test('initialize calls SharedPreferences.getInstance', () async {
      const channel = MethodChannel('plugins.flutter.io/shared_preferences');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (methodCall) async {
            if (methodCall.method == 'getAll') {
              return <String, dynamic>{};
            }
            return null;
          });

      final repo = SharedPrefsLocalStorageRepository();
      await repo.initialize();
    });

    test('saveLanguage saves language string', () async {
      when(() => prefs.setString(any(), any())).thenAnswer((_) async => true);

      repository.saveLanguage(language: const Locale('es', 'ES'));

      verify(
        () => prefs.setString(LocalStorageRepository.kUserLanguage, 'es_ES'),
      ).called(1);
    });

    test('saveLanguage does nothing if _prefs is null', () {
      final _ = SharedPrefsLocalStorageRepository()
        ..saveLanguage(language: const Locale('es', 'ES'));
    });

    test('getLanguage returns correct locale', () {
      when(
        () => prefs.getString(LocalStorageRepository.kUserLanguage),
      ).thenReturn('en_US');

      final locale = repository.getLanguage();

      expect(locale, equals(const Locale('en', 'US')));
    });

    test('getLanguage returns null if string is null', () {
      when(
        () => prefs.getString(LocalStorageRepository.kUserLanguage),
      ).thenReturn(null);
      expect(repository.getLanguage(), isNull);
    });

    test('getLanguage returns null if _prefs is null', () {
      final repo = SharedPrefsLocalStorageRepository();
      expect(repo.getLanguage(), isNull);
    });

    test('saveTheme saves theme name', () async {
      when(() => prefs.setString(any(), any())).thenAnswer((_) async => true);

      repository.saveTheme(theme: ThemeMode.dark);

      verify(
        () => prefs.setString(LocalStorageRepository.kUserTheme, 'DARK'),
      ).called(1);
    });

    test('saveTheme does nothing if _prefs is null', () {
      final _ = SharedPrefsLocalStorageRepository()
        ..saveTheme(theme: ThemeMode.dark);
    });

    test('getTheme returns correct theme', () {
      when(
        () => prefs.getString(LocalStorageRepository.kUserTheme),
      ).thenReturn('DARK');

      expect(repository.getTheme(), equals(ThemeMode.dark));
    });

    test('getTheme returns null if string is null', () {
      when(
        () => prefs.getString(LocalStorageRepository.kUserTheme),
      ).thenReturn(null);
      expect(repository.getTheme(), isNull);
    });

    test('getTheme returns null if _prefs is null', () {
      final repo = SharedPrefsLocalStorageRepository();
      expect(repo.getTheme(), isNull);
    });

    test('saveBaseColor saves color name', () async {
      when(() => prefs.setString(any(), any())).thenAnswer((_) async => true);

      repository.saveBaseColor(baseColor: Colors.red);

      verify(
        () => prefs.setString(LocalStorageRepository.kUserBaseColor, 'RED'),
      ).called(1);
    });

    test('saveBaseColor does nothing if _prefs is null', () {
      final _ = SharedPrefsLocalStorageRepository()
        ..saveBaseColor(baseColor: Colors.red);
    });

    test('getBaseColor returns correct color', () {
      when(
        () => prefs.getString(LocalStorageRepository.kUserBaseColor),
      ).thenReturn('RED');

      expect(repository.getBaseColor(), equals(Colors.red));
    });

    test('getBaseColor returns null if string is null', () {
      when(
        () => prefs.getString(LocalStorageRepository.kUserBaseColor),
      ).thenReturn(null);
      expect(repository.getBaseColor(), isNull);
    });

    test('getBaseColor returns null if _prefs is null', () {
      final repo = SharedPrefsLocalStorageRepository();
      expect(repo.getBaseColor(), isNull);
    });

    test('saveFontFamily saves font name', () async {
      when(() => prefs.setString(any(), any())).thenAnswer((_) async => true);

      repository.saveFontFamily(fontFamily: 'Roboto');

      verify(
        () => prefs.setString(LocalStorageRepository.kUserFontFamily, 'Roboto'),
      ).called(1);
    });

    test('saveFontFamily does nothing if _prefs is null', () {
      final _ = SharedPrefsLocalStorageRepository()
        ..saveFontFamily(fontFamily: 'Roboto');
    });

    test('getFontFamily returns correct font', () {
      when(
        () => prefs.getString(LocalStorageRepository.kUserFontFamily),
      ).thenReturn('Roboto');

      expect(repository.getFontFamily(), equals('Roboto'));
    });

    test('getFontFamily returns null if _prefs is null', () {
      final repo = SharedPrefsLocalStorageRepository();
      expect(repo.getFontFamily(), isNull);
    });

    test('MockLocalStorageRepository returns default values', () {
      final mock = MockLocalStorageRepository();
      unawaited(mock.initialize());
      expect(mock.getLanguage(), isNotNull);
      expect(mock.getTheme(), isNotNull);
      expect(mock.getBaseColor(), isNotNull);
      expect(mock.getFontFamily(), isNotNull);
      mock
        ..saveLanguage(language: const Locale('en'))
        ..saveTheme(theme: ThemeMode.light)
        ..saveBaseColor(baseColor: Colors.blue)
        ..saveFontFamily(fontFamily: 'f');
    });
  });
}
