import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_play/app/app.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';

void main() {
  late MockLocalStorageService localStorageService;
  late MockAnalyticsService analyticsService;
  late MockCrashService crashService;
  late MockPerformanceService performanceService;

  setUpAll(registerFallbackValues);

  setUp(() async {
    localStorageService = MockLocalStorageService();
    analyticsService = MockAnalyticsService();
    crashService = MockCrashService();
    performanceService = MockPerformanceService();

    await getIt.reset();
    getIt
      ..registerSingleton<LocalStorageService>(localStorageService)
      ..registerSingleton<AnalyticsService>(analyticsService)
      ..registerSingleton<CrashService>(crashService)
      ..registerSingleton<PerformanceService>(performanceService);

    when(() => crashService.setCustomKey(any(), any())).thenReturn(null);
    when(() => performanceService.startTrace(any())).thenReturn(MockTrace());
    when(
      () => analyticsService.logEvent(
        name: any(named: 'name'),
        parameters: any(named: 'parameters'),
      ),
    ).thenAnswer((_) async {});
  });

  group('AppCubit', () {
    test('initial state is correct', () {
      expect(AppCubit().state, const AppState());
    });

    blocTest<AppCubit, AppState>(
      'initialize emits updated state when data exists',
      setUp: () {
        when(
          () => localStorageService.getLanguage(),
        ).thenReturn(const Locale('es', 'ES'));
        when(() => localStorageService.getTheme()).thenReturn(ThemeMode.dark);
        when(() => localStorageService.getBaseColor()).thenReturn(Colors.red);
        when(() => localStorageService.getFontFamily()).thenReturn('Roboto');
      },
      build: AppCubit.new,
      act: (cubit) => cubit.initialize(),
      expect: () => [
        const AppState(
          language: Locale('es', 'ES'),
          theme: ThemeMode.dark,
          baseColor: Colors.red,
          fontFamily: 'Roboto',
        ),
      ],
    );

    blocTest<AppCubit, AppState>(
      'initialize saves and emits defaults when storage is empty',
      setUp: () {
        when(() => localStorageService.getLanguage()).thenReturn(null);
        when(() => localStorageService.getTheme()).thenReturn(null);
        when(() => localStorageService.getBaseColor()).thenReturn(null);
        when(() => localStorageService.getFontFamily()).thenReturn(null);

        when(
          () => localStorageService.saveLanguage(
            language: any(named: 'language'),
          ),
        ).thenReturn(null);
        when(
          () => localStorageService.saveTheme(theme: any(named: 'theme')),
        ).thenReturn(null);
        when(
          () => localStorageService.saveBaseColor(
            baseColor: any(named: 'baseColor'),
          ),
        ).thenReturn(null);
        when(
          () => localStorageService.saveFontFamily(
            fontFamily: any(named: 'fontFamily'),
          ),
        ).thenReturn(null);
      },
      build: AppCubit.new,
      act: (cubit) => cubit.initialize(),
      expect: () => [const AppState()],
      verify: (_) {
        verify(
          () => localStorageService.saveLanguage(
            language: AppVariables.supportedLocales.first,
          ),
        ).called(1);
        verify(
          () => localStorageService.saveTheme(theme: ThemeMode.system),
        ).called(1);
        verify(
          () => localStorageService.saveBaseColor(
            baseColor: AppVariables.defaultBaseColor,
          ),
        ).called(1);
        verify(
          () => localStorageService.saveFontFamily(
            fontFamily: AppVariables.defaultFontFamily,
          ),
        ).called(1);
      },
    );

    blocTest<AppCubit, AppState>(
      'initialize resets font to default when current font is unsupported',
      setUp: () {
        when(
          () => localStorageService.getLanguage(),
        ).thenReturn(const Locale('en', 'US'));
        when(() => localStorageService.getTheme()).thenReturn(ThemeMode.system);
        when(() => localStorageService.getBaseColor()).thenReturn(Colors.green);
        when(
          () => localStorageService.getFontFamily(),
        ).thenReturn('InvalidFont');

        when(
          () => localStorageService.saveFontFamily(
            fontFamily: any(named: 'fontFamily'),
          ),
        ).thenReturn(null);
      },
      build: AppCubit.new,
      act: (cubit) => cubit.initialize(),
      expect: () => [
        const AppState(),
      ],
      verify: (_) {
        verify(
          () => localStorageService.saveFontFamily(
            fontFamily: AppVariables.defaultFontFamily,
          ),
        ).called(1);
      },
    );

    group('change methods', () {
      setUp(() {
        when(
          () => localStorageService.saveLanguage(
            language: any(named: 'language'),
          ),
        ).thenReturn(null);
        when(
          () => localStorageService.saveTheme(theme: any(named: 'theme')),
        ).thenReturn(null);
        when(
          () => localStorageService.saveBaseColor(
            baseColor: any(named: 'baseColor'),
          ),
        ).thenReturn(null);
        when(
          () => localStorageService.saveFontFamily(
            fontFamily: any(named: 'fontFamily'),
          ),
        ).thenReturn(null);
      });

      blocTest<AppCubit, AppState>(
        'changeLanguage saves and emits new language',
        build: AppCubit.new,
        act: (cubit) =>
            cubit.changeLanguage(language: const Locale('es', 'ES')),
        expect: () => [
          const AppState(language: Locale('es', 'ES')),
        ],
        verify: (_) {
          verify(
            () => localStorageService.saveLanguage(
              language: const Locale('es', 'ES'),
            ),
          ).called(1);
          verify(() => crashService.setCustomKey('language', 'es')).called(1);
          verify(
            () => analyticsService.logEvent(
              name: 'change_language',
              parameters: {'language': 'es'},
            ),
          ).called(1);
        },
      );

      blocTest<AppCubit, AppState>(
        'changeTheme saves and emits new theme',
        build: AppCubit.new,
        act: (cubit) => cubit.changeTheme(theme: ThemeMode.dark),
        expect: () => [
          const AppState(theme: ThemeMode.dark),
        ],
        verify: (_) {
          verify(
            () => localStorageService.saveTheme(theme: ThemeMode.dark),
          ).called(1);
          verify(() => crashService.setCustomKey('theme', 'dark')).called(1);
          verify(
            () => analyticsService.logEvent(
              name: 'change_theme',
              parameters: {'theme': 'dark'},
            ),
          ).called(1);
        },
      );

      blocTest<AppCubit, AppState>(
        'changeBaseColor saves and emits new base color',
        build: AppCubit.new,
        act: (cubit) => cubit.changeBaseColor(baseColor: Colors.blue),
        expect: () => [
          const AppState(baseColor: Colors.blue),
        ],
        verify: (_) {
          verify(
            () => localStorageService.saveBaseColor(baseColor: Colors.blue),
          ).called(1);
          verify(
            () => analyticsService.logEvent(
              name: 'change_base_color',
              parameters: {'color_value': 'BLUE'},
            ),
          ).called(1);
        },
      );

      blocTest<AppCubit, AppState>(
        'changeFontFamily saves and emits new font family',
        build: AppCubit.new,
        act: (cubit) => cubit.changeFontFamily(fontFamily: 'Montserrat'),
        expect: () => [
          const AppState(fontFamily: 'Montserrat'),
        ],
        verify: (_) {
          verify(
            () => localStorageService.saveFontFamily(fontFamily: 'Montserrat'),
          ).called(1);
          verify(
            () => crashService.setCustomKey('fontFamily', 'Montserrat'),
          ).called(1);
          verify(
            () => analyticsService.logEvent(
              name: 'change_font_family',
              parameters: {'font_family': 'Montserrat'},
            ),
          ).called(1);
        },
      );
    });
  });
}
