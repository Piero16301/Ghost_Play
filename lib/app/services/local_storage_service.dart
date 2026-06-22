import 'package:flutter/material.dart';
import 'package:ghost_play/app/app.dart';

class LocalStorageService {
  LocalStorageService({required this._localStorageRepository});

  final LocalStorageRepository _localStorageRepository;

  Future<void> initialize() async {
    await _localStorageRepository.initialize();
  }

  void saveLanguage({required Locale language}) {
    _localStorageRepository.saveLanguage(language: language);
  }

  Locale? getLanguage() {
    return _localStorageRepository.getLanguage();
  }

  void saveTheme({required ThemeMode theme}) {
    _localStorageRepository.saveTheme(theme: theme);
  }

  ThemeMode? getTheme() {
    return _localStorageRepository.getTheme();
  }

  void saveBaseColor({required Color baseColor}) {
    _localStorageRepository.saveBaseColor(baseColor: baseColor);
  }

  Color? getBaseColor() {
    return _localStorageRepository.getBaseColor();
  }

  void saveFontFamily({required String fontFamily}) {
    _localStorageRepository.saveFontFamily(fontFamily: fontFamily);
  }

  String? getFontFamily() {
    return _localStorageRepository.getFontFamily();
  }
}
