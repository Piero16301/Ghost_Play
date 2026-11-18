import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_play/app/app.dart';
import 'package:ghost_play/home/home.dart';
import 'package:ghost_play/settings/settings.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../helpers/mocks.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/service_locator.dart';

void main() {
  late MockAppCubit appCubit;

  setUpAll(() {
    registerFallbackValues();
    PackageInfo.setMockInitialValues(
      appName: 'Ghost Play',
      packageName: 'com.ghost.play',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  setUp(() async {
    await setupServiceLocatorMocks();
    appCubit = MockAppCubit();

    when(() => appCubit.state).thenReturn(const AppState());
    when(() => getIt<PerformanceService>().startTrace(any<String>()))
        .thenReturn(MockTrace());
    when(() => getIt<PerformanceService>().stopTrace(any())).thenReturn(null);
    when(() => getIt<CrashService>().log(any<String>())).thenReturn(null);
    when(() => getIt<CrashService>().setCustomKey(any(), any()))
        .thenReturn(null);
    when(
      () => getIt<CrashService>().recordError(
        any<dynamic>(),
        any<StackTrace?>(),
        reason: any<dynamic>(named: 'reason'),
      ),
    ).thenReturn(null);
    when(
      () => getIt<AnalyticsService>().logEvent(
        name: any<String>(named: 'name'),
        parameters: any<Map<String, Object>?>(named: 'parameters'),
      ),
    ).thenReturn(null);
    when(
      () => getIt<AnalyticsService>().setCurrentScreen(
        screenName: any<String>(named: 'screenName'),
      ),
    ).thenReturn(null);
    when(() => getIt<StorageService>().getPersistedPermissionDirectories())
        .thenAnswer((_) async => []);
  });

  group('AppRoute', () {
    test('defines expected paths and names', () {
      expect(AppRoute.home.path, '/');
      expect(AppRoute.home.name, 'home');
      expect(AppRoute.settings.path, '/settings');
      expect(AppRoute.settings.name, 'settings');
    });
  });

  group('AppRouter', () {
    testWidgets('renders HomePage on initial route and navigates to settings', (
      tester,
    ) async {
      final router = AppRouter.getRouter();
      addTearDown(router.dispose);

      expect(router, isA<GoRouter>());

      await tester.pumpApp(
        const SizedBox.shrink(),
        appCubit: appCubit,
        router: router,
        locale: const Locale('en'),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HomePage), findsOneWidget);

      router.goNamed(AppRoute.settings.name);
      await tester.pumpAndSettle();

      expect(find.byType(SettingsPage), findsOneWidget);
    });
  });
}
