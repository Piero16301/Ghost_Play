part of 'app_cubit.dart';

class AppState extends Equatable {
  const AppState({
    this.language = const Locale('en', 'US'),
    this.theme = ThemeMode.system,
    this.baseColor = Colors.green,
    this.fontFamily = 'GoogleSansFlex',
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
  List<Object> get props => [
    language,
    theme,
    baseColor,
    fontFamily,
  ];
}
