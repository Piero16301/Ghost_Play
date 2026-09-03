import 'package:ghost_play/app/app.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class LocalStorageRepository {
  static const kUserLanguage = '__user_language__';
  static const kUserTheme = '__user_theme__';
  static const kUserBaseColor = '__user_base_color__';
  static const kUserFontFamily = '__user_font_family__';

  Future<void> initialize();
  void saveLanguage({required Locale language});
  Locale? getLanguage();
  void saveTheme({required ThemeMode theme});
  ThemeMode? getTheme();
  void saveBaseColor({required Color baseColor});
  Color? getBaseColor();
  void saveFontFamily({required String fontFamily});
  String? getFontFamily();
}

class MockLocalStorageRepository implements LocalStorageRepository {
  @override
  Future<void> initialize() async {}

  @override
  void saveLanguage({required Locale language}) {}

  @override
  Locale? getLanguage() {
    return const Locale('en', 'US');
  }

  @override
  void saveTheme({required ThemeMode theme}) {}

  @override
  ThemeMode? getTheme() {
    return ThemeMode.light;
  }

  @override
  void saveBaseColor({required Color baseColor}) {}

  @override
  Color? getBaseColor() {
    return Colors.blue;
  }

  @override
  void saveFontFamily({required String fontFamily}) {}

  @override
  String? getFontFamily() {
    return 'default';
  }
}

class SharedPrefsLocalStorageRepository implements LocalStorageRepository {
  SharedPrefsLocalStorageRepository({this._prefs});

  SharedPreferences? _prefs;

  @override
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  @override
  void saveLanguage({required Locale language}) {
    final languageString = '${language.languageCode}_${language.countryCode}';
    _prefs
        ?.setString(LocalStorageRepository.kUserLanguage, languageString)
        .ignore();
  }

  @override
  Locale? getLanguage() {
    final languageString = _prefs?.getString(
      LocalStorageRepository.kUserLanguage,
    );
    if (languageString == null) {
      return null;
    }
    final languageParts = languageString.split('_');
    return Locale(languageParts.first, languageParts.last);
  }

  @override
  void saveTheme({required ThemeMode theme}) {
    _prefs
        ?.setString(
          LocalStorageRepository.kUserTheme,
          ThemeHelper.getThemeName(theme),
        )
        .ignore();
  }

  @override
  ThemeMode? getTheme() {
    final themeString = _prefs?.getString(LocalStorageRepository.kUserTheme);
    if (themeString == null) {
      return null;
    }
    return ThemeHelper.getThemeByName(themeString);
  }

  @override
  void saveBaseColor({required Color baseColor}) {
    _prefs
        ?.setString(
          LocalStorageRepository.kUserBaseColor,
          ColorHelper.getColorName(baseColor),
        )
        .ignore();
  }

  @override
  Color? getBaseColor() {
    final baseColorString = _prefs?.getString(
      LocalStorageRepository.kUserBaseColor,
    );
    if (baseColorString == null) {
      return null;
    }
    return ColorHelper.getColorByName(baseColorString);
  }

  @override
  void saveFontFamily({required String fontFamily}) {
    _prefs
        ?.setString(
          LocalStorageRepository.kUserFontFamily,
          fontFamily,
        )
        .ignore();
  }

  @override
  String? getFontFamily() {
    return _prefs?.getString(LocalStorageRepository.kUserFontFamily);
  }
}
