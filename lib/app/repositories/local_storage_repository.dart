import 'package:expressive_kit/expressive_kit.dart';
import 'package:ghost_play/app/app.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class LocalStorageRepository {
  static const kUserLanguage = '__user_language__';
  static const kUserTheme = '__user_theme__';
  static const kUserBaseColor = '__user_base_color__';
  static const kUserFontFamily = '__user_font_family__';
  static const kTranscriptionPrefix = '__transcription__';

  Future<void> initialize();
  void saveLanguage({required Locale language});
  Locale? getLanguage();
  void saveTheme({required ThemeMode theme});
  ThemeMode? getTheme();
  void saveBaseColor({required Color baseColor});
  Color? getBaseColor();
  void saveFontFamily({required String fontFamily});
  String? getFontFamily();
  void saveTranscription({
    required String fileName,
    required TranscriptionMetadata transcription,
  });
  TranscriptionMetadata? getTranscription({required String fileName});
  void clearOldTranscriptions({required int maxDays});
}

class MockLocalStorageRepository implements LocalStorageRepository {
  final Map<String, TranscriptionMetadata> _transcriptions = {};

  @override
  Future<void> initialize() async {}

  @override
  void saveLanguage({required Locale language}) {}

  @override
  Locale? getLanguage() {
    return ExpressiveLanguages.defaultLocale;
  }

  @override
  void saveTheme({required ThemeMode theme}) {}

  @override
  ThemeMode? getTheme() {
    return ExpressiveTheme.defaultTheme;
  }

  @override
  void saveBaseColor({required Color baseColor}) {}

  @override
  Color? getBaseColor() {
    return ExpressiveColors.defaultColor;
  }

  @override
  void saveFontFamily({required String fontFamily}) {}

  @override
  String? getFontFamily() {
    return ExpressiveFonts.defaultFont;
  }

  @override
  void saveTranscription({
    required String fileName,
    required TranscriptionMetadata transcription,
  }) {
    _transcriptions[fileName] = transcription;
  }

  @override
  TranscriptionMetadata? getTranscription({required String fileName}) {
    return _transcriptions[fileName];
  }

  @override
  void clearOldTranscriptions({required int maxDays}) {
    final cutoff = DateTime.now().subtract(Duration(days: maxDays));
    _transcriptions.removeWhere((_, value) => value.timestamp.isBefore(cutoff));
  }
}

class SharedPrefsLocalStorageRepository implements LocalStorageRepository {
  new({this._prefs});

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
    return ExpressiveLanguages.fromLanguageCode(languageString);
  }

  @override
  void saveTheme({required ThemeMode theme}) {
    _prefs
        ?.setString(
          LocalStorageRepository.kUserTheme,
          ExpressiveTheme.toKey(theme),
        )
        .ignore();
  }

  @override
  ThemeMode? getTheme() {
    final themeString = _prefs?.getString(LocalStorageRepository.kUserTheme);
    if (themeString == null) {
      return null;
    }
    return ExpressiveTheme.fromKey(themeString);
  }

  @override
  void saveBaseColor({required Color baseColor}) {
    _prefs
        ?.setString(
          LocalStorageRepository.kUserBaseColor,
          ExpressiveColors.toKey(baseColor),
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
    return ExpressiveColors.fromKey(baseColorString);
  }

  @override
  void saveFontFamily({required String fontFamily}) {
    _prefs
        ?.setString(LocalStorageRepository.kUserFontFamily, fontFamily)
        .ignore();
  }

  @override
  String? getFontFamily() {
    return _prefs?.getString(LocalStorageRepository.kUserFontFamily);
  }

  @override
  void saveTranscription({
    required String fileName,
    required TranscriptionMetadata transcription,
  }) {
    _prefs
        ?.setString(
          '${LocalStorageRepository.kTranscriptionPrefix}$fileName',
          transcription.toJson(),
        )
        .ignore();
  }

  @override
  TranscriptionMetadata? getTranscription({required String fileName}) {
    final raw = _prefs?.getString(
      '${LocalStorageRepository.kTranscriptionPrefix}$fileName',
    );
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      return TranscriptionMetadata.fromJson(raw);
    } on Object {
      return null;
    }
  }

  @override
  void clearOldTranscriptions({required int maxDays}) {
    final prefs = _prefs;
    if (prefs == null) return;

    final cutoff = DateTime.now().subtract(Duration(days: maxDays));
    final keys = prefs
        .getKeys()
        .where((k) => k.startsWith(LocalStorageRepository.kTranscriptionPrefix))
        .toList();

    for (final key in keys) {
      final raw = prefs.getString(key);
      if (raw == null || raw.isEmpty) {
        prefs.remove(key).ignore();
        continue;
      }

      try {
        final metadata = TranscriptionMetadata.fromJson(raw);
        if (metadata.timestamp.isBefore(cutoff)) {
          prefs.remove(key).ignore();
        }
      } on Object {
        prefs.remove(key).ignore();
      }
    }
  }
}
