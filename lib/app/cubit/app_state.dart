part of 'app_cubit.dart';

class AppState extends Equatable {
  const AppState({
    this.language = ExpressiveLanguages.defaultLocale,
    this.theme = ExpressiveTheme.defaultTheme,
    this.baseColor = ExpressiveColors.defaultColor,
    this.fontFamily = ExpressiveFonts.defaultFont,
  });

  final Locale language;
  final ThemeMode theme;
  final Color baseColor;
  final String fontFamily;

  AppState copyWith({
    Locale? language,
    ThemeMode? theme,
    Color? baseColor,
    String? fontFamily,
  }) {
    return AppState(
      language: language ?? this.language,
      theme: theme ?? this.theme,
      baseColor: baseColor ?? this.baseColor,
      fontFamily: fontFamily ?? this.fontFamily,
    );
  }

  @override
  List<Object> get props => [language, theme, baseColor, fontFamily];
}
