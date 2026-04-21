import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_play/app/app.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';

void main() {
  late MockLocalStorageService localStorageService;
  late MockAnalyticsService analyticsService;
  late MockCrashService crashService;
  late MockPerformanceService performanceService;

  setUpAll(registerFallbackValues);

  setUp(() {
    localStorageService = MockLocalStorageService();
    analyticsService = MockAnalyticsService();
    crashService = MockCrashService();
    performanceService = MockPerformanceService();

    unawaited(getIt.reset());
    getIt
      ..registerSingleton<LocalStorageService>(localStorageService)
      ..registerSingleton<AnalyticsService>(analyticsService)
      ..registerSingleton<CrashService>(crashService)
      ..registerSingleton<PerformanceService>(performanceService);

    when(() => localStorageService.getLanguage()).thenReturn(null);
    when(() => localStorageService.getTheme()).thenReturn(null);
    when(() => localStorageService.getBaseColor()).thenReturn(null);
    when(() => localStorageService.getFontFamily()).thenReturn(null);
    when(
      () => localStorageService.saveLanguage(language: any(named: 'language')),
    ).thenReturn(null);
    when(
      () => localStorageService.saveTheme(theme: any(named: 'theme')),
    ).thenReturn(null);
    when(
      () =>
          localStorageService.saveBaseColor(baseColor: any(named: 'baseColor')),
    ).thenReturn(null);
    when(
      () => localStorageService.saveFontFamily(
        fontFamily: any(named: 'fontFamily'),
      ),
    ).thenReturn(null);
    when(() => crashService.setCustomKey(any(), any())).thenReturn(null);
    when(
      () => analyticsService.logEvent(
        name: any(named: 'name'),
        parameters: any(named: 'parameters'),
      ),
    ).thenAnswer((_) async {});
  });

  group('AppPage', () {
    testWidgets('renders AppView', (tester) async {
      await tester.pumpWidget(const AppPage());
      expect(find.byType(AppView), findsOneWidget);
    });
  });
}
