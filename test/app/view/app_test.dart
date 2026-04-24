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
  late MockStorageService storageService;

  setUpAll(registerFallbackValues);

  setUp(() {
    localStorageService = MockLocalStorageService();
    analyticsService = MockAnalyticsService();
    crashService = MockCrashService();
    performanceService = MockPerformanceService();
    storageService = MockStorageService();

    unawaited(getIt.reset());
    getIt
      ..registerSingleton<LocalStorageService>(localStorageService)
      ..registerSingleton<AnalyticsService>(analyticsService)
      ..registerSingleton<CrashService>(crashService)
      ..registerSingleton<PerformanceService>(performanceService)
      ..registerSingleton<StorageService>(storageService);

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
    when(() => performanceService.startTrace(any())).thenReturn(MockTrace());
    when(
      () => analyticsService.logEvent(
        name: any(named: 'name'),
        parameters: any(named: 'parameters'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => storageService.getPersistedPermissionDirectories(),
    ).thenAnswer((_) async => []);
  });

  group('AppPage', () {
    testWidgets('renders AppView', (tester) async {
      // ignore: prefer_const_constructors // To prevent testing framework
      await tester.pumpWidget(AppPage());
      expect(find.byType(AppView), findsOneWidget);
    });
  });
}
