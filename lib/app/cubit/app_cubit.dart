import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:ghost_play/app/app.dart';

part 'app_state.dart';

class AppCubit extends Cubit<AppState> {
  AppCubit() : super(const AppState());

  final LocalStorageService _localStorage = getIt<LocalStorageService>();
  final CrashService _crashService = getIt<CrashService>();
  final AnalyticsService _analyticsService = getIt<AnalyticsService>();

  void initialize() {
    // Setting the language to the device language if it's not set
    final language = _localStorage.getLanguage();
    if (language == null) {
      final deviceLanguage = AppVariables.supportedLocales.first;
      _localStorage.saveLanguage(language: deviceLanguage);
    }

    // Setting the theme to the device theme if it's not set
    final theme = _localStorage.getTheme();
    if (theme == null) {
      _localStorage.saveTheme(theme: ThemeMode.system);
    }

    // Setting the base color to GREEN if it's not set
    final baseColor = _localStorage.getBaseColor();
    if (baseColor == null) {
      _localStorage.saveBaseColor(baseColor: AppVariables.defaultBaseColor);
    }

    // Setting the font family to Popping if it's not set
    var fontFamily = _localStorage.getFontFamily();
    final isFontSupported =
        fontFamily != null &&
        AppVariables.availableFonts.containsValue(fontFamily);

    if (!isFontSupported) {
      final defaultFont =
          AppVariables.availableFonts[AppVariables.defaultFontFamily] ??
          AppVariables.defaultFontFamily;
      _localStorage.saveFontFamily(fontFamily: defaultFont);
      fontFamily = defaultFont;
    }

    // Add custom keys for CrashService
    _crashService
      ..setCustomKey(
        'language',
        _localStorage.getLanguage()?.languageCode ??
            AppVariables.supportedLocales.first.languageCode,
      )
      ..setCustomKey(
        'theme',
        _localStorage.getTheme()?.name ?? ThemeMode.system.name,
      )
      ..setCustomKey(
        'fontFamily',
        _localStorage.getFontFamily() ?? AppVariables.defaultFontFamily,
      );

    // Emit state with all loaded configurations at once
    emit(
      state.copyWith(
        language: _localStorage.getLanguage(),
        theme: _localStorage.getTheme(),
        baseColor: _localStorage.getBaseColor(),
        fontFamily: _localStorage.getFontFamily(),
      ),
    );
  }

  void changeLanguage({required Locale language}) {
    _localStorage.saveLanguage(language: language);
    _crashService.setCustomKey('language', language.languageCode);
    _analyticsService.logEvent(
      name: 'change_language',
      parameters: {'language': language.languageCode},
    );
    emit(state.copyWith(language: language));
  }

  void changeTheme({required ThemeMode theme}) {
    _localStorage.saveTheme(theme: theme);
    _crashService.setCustomKey('theme', theme.name);
    _analyticsService.logEvent(
      name: 'change_theme',
      parameters: {'theme': theme.name},
    );
    emit(state.copyWith(theme: theme));
  }

  void changeBaseColor({required Color baseColor}) {
    _localStorage.saveBaseColor(baseColor: baseColor);
    _analyticsService.logEvent(
      name: 'change_base_color',
      parameters: {'color_value': ColorHelper.getColorName(baseColor)},
    );
    emit(state.copyWith(baseColor: baseColor));
  }

  void changeFontFamily({required String fontFamily}) {
    _localStorage.saveFontFamily(fontFamily: fontFamily);
    _crashService.setCustomKey('fontFamily', fontFamily);
    _analyticsService.logEvent(
      name: 'change_font_family',
      parameters: {'font_family': fontFamily},
    );
    emit(state.copyWith(fontFamily: fontFamily));
  }
}
