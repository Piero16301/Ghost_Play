import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_play/app/app.dart';
import 'package:ghost_play/home/home.dart';
import 'package:ghost_play/l10n/l10n.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';

void main() {
  late MockHomeCubit homeCubit;
  late MockAnalyticsService analyticsService;
  late MockCrashService crashService;
  late MockPerformanceService performanceService;
  late MockStorageService storageService;

  setUpAll(registerFallbackValues);

  setUp(() {
    homeCubit = MockHomeCubit();
    analyticsService = MockAnalyticsService();
    crashService = MockCrashService();
    performanceService = MockPerformanceService();
    storageService = MockStorageService();

    unawaited(getIt.reset());
    getIt
      ..registerSingleton<AnalyticsService>(analyticsService)
      ..registerSingleton<CrashService>(crashService)
      ..registerSingleton<PerformanceService>(performanceService)
      ..registerSingleton<StorageService>(storageService);

    when(() => homeCubit.state).thenReturn(const HomeState());
    when(() => homeCubit.initStorage()).thenAnswer((_) async {});
    when(() => homeCubit.close()).thenAnswer((_) async {});
    when(() => homeCubit.toggleSelectedIndex(any<int>())).thenReturn(null);

    when(
      () => performanceService.startTrace(any<String>()),
    ).thenReturn(MockTrace());
    when(() => crashService.log(any<String>())).thenReturn(null);
  });

  Widget createWidgetUnderTest({GoRouter? router}) {
    final effectiveRouter =
        router ??
        GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => BlocProvider<HomeCubit>.value(
                value: homeCubit,
                child: const HomeView(),
              ),
            ),
            GoRoute(
              path: '/settings',
              name: AppRoute.settings.name,
              builder: (context, state) =>
                  const Scaffold(body: Text('Settings')),
            ),
          ],
        );

    return MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppVariables.supportedLocales,
      routerConfig: effectiveRouter,
    );
  }

  group('HomeView', () {
    testWidgets('renders correctly and calls initStorage on init', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      expect(find.byType(HomeView), findsOneWidget);
      expect(find.text(AppVariables.appName), findsOneWidget);
      verify(() => homeCubit.initStorage()).called(1);
    });

    testWidgets('navigates to settings when settings button is pressed', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final settingsButton = find.byType(IconButton).first;
      await tester.tap(settingsButton);
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('switches to StatesHomePage when index is 1', (tester) async {
      when(() => homeCubit.state).thenReturn(const HomeState(selectedIndex: 1));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.byType(StatesHomePage), findsOneWidget);
    });

    testWidgets(
      'calls toggleSelectedIndex on NavigationBar destination selection',
      (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());

        await tester.tap(find.text('States'));
        await tester.pump();

        verify(() => homeCubit.toggleSelectedIndex(1)).called(1);
      },
    );

    testWidgets(
      'renders SizedBox.shrink for unknown index (hitting default branch)',
      (tester) async {
        when(
          () => homeCubit.state,
        ).thenReturn(const HomeState(selectedIndex: 2));

        await tester.pumpWidget(createWidgetUnderTest());

        expect(tester.takeException(), isAssertionError);
      },
    );

    testWidgets('triggers dispose', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpWidget(const SizedBox());
    });
  });
}
