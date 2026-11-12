import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:expressive_kit/expressive_kit.dart';
import 'package:ghost_play/app/app.dart';
import 'package:material_ui/material_ui.dart';

part 'app_state.dart';

class AppCubit extends Cubit<AppState> {
  new() : super(const AppState());

  final LocalStorageService _localStorage = getIt<LocalStorageService>();
  final CrashService _crashService = getIt<CrashService>();
  final AnalyticsService _analyticsService = getIt<AnalyticsService>();
  final PerformanceService _performanceService = getIt<PerformanceService>();

  void initialize() {
    final trace = _performanceService.startTrace('app_cubit_initialize');
    try {
      var language = _localStorage.getLanguage();
      if (language == null) {
        language = ExpressiveLanguages.defaultLocale;
        _localStorage.saveLanguage(language: language);
      }

      var theme = _localStorage.getTheme();
      if (theme == null) {
        theme = ExpressiveTheme.defaultTheme;
        _localStorage.saveTheme(theme: theme);
      }

      var baseColor = _localStorage.getBaseColor();
      if (baseColor == null) {
        baseColor = ExpressiveColors.defaultColor;
        _localStorage.saveBaseColor(baseColor: baseColor);
      }

      var fontFamily = _localStorage.getFontFamily();
      final isFontSupported =
          fontFamily != null &&
          (ExpressiveFonts.availableFonts.containsValue(fontFamily) ||
              ExpressiveFonts.availableFonts.containsKey(fontFamily));

      if (!isFontSupported) {
        const defaultFont = ExpressiveFonts.defaultFont;
        _localStorage.saveFontFamily(fontFamily: defaultFont);
        fontFamily = defaultFont;
      } else if (ExpressiveFonts.availableFonts.containsKey(fontFamily)) {
        fontFamily = ExpressiveFonts.availableFonts[fontFamily]!;
      }

      // Update CrashService with finalized values
      _crashService
        ..setCustomKey('language', language.languageCode)
        ..setCustomKey('theme', theme.name)
        ..setCustomKey('fontFamily', fontFamily);

      // Emit consolidated state
      emit(
        state.copyWith(
          language: language,
          theme: theme,
          baseColor: baseColor,
          fontFamily: fontFamily,
        ),
      );
    } finally {
      _performanceService.stopTrace(trace);
    }
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
      parameters: {'color_value': ExpressiveColors.toKey(baseColor)},
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
