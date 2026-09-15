import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_play/app/app.dart';
import 'package:ghost_play/home/home.dart';
import 'package:ghost_play/l10n/l10n.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';

void main() {
  late MockHomeCubit homeCubit;
  late StreamController<HomeState> homeStateController;
  late MockAnalyticsService analyticsService;
  late MockCrashService crashService;
  late MockPerformanceService performanceService;
  late MockStorageService storageService;

  setUpAll(registerFallbackValues);

  setUp(() {
    homeCubit = MockHomeCubit();
    homeStateController = StreamController<HomeState>.broadcast();
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
    when(() => homeCubit.stream).thenAnswer((_) => homeStateController.stream);
    when(() => homeCubit.initStorage()).thenAnswer((_) async {});
    when(() => homeCubit.close()).thenAnswer((_) async {});
    when(() => homeCubit.toggleSelectedIndex(any<int>())).thenReturn(null);

    when(
      () => performanceService.startTrace(any<String>()),
    ).thenReturn(MockTrace());
    when(() => crashService.log(any<String>())).thenReturn(null);
  });

  tearDown(() async {
    await homeStateController.close();
  });

  Widget createWidgetUnderTest({
    GoRouter? router,
    Brightness brightness = Brightness.light,
  }) {
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
      theme: ThemeData(brightness: brightness),
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
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.title, isA<Image>());
      final logoImage = appBar.title! as Image;
      expect(logoImage.width, 40);
      expect(logoImage.height, 40);
      expect(
        (logoImage.image as AssetImage).assetName,
        AppVariables.logoNoBgLight,
      );
      verify(() => homeCubit.initStorage()).called(1);
    });

    testWidgets('renders dark logo when brightness is dark', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(brightness: Brightness.dark),
      );
      expect(find.byType(HomeView), findsOneWidget);
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.title, isA<Image>());
      final logoImage = appBar.title! as Image;
      expect(
        (logoImage.image as AssetImage).assetName,
        AppVariables.logoNoBgDark,
      );
    });

    testWidgets('navigates to settings when settings button is pressed', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final settingsButton = find.byType(IconButton).first;
      await tester.tap(settingsButton);
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      verify(
        () => analyticsService.logEvent(name: 'open_settings_action'),
      ).called(1);
    });

    testWidgets('switches to StatesHomePage when index is 1', (tester) async {
      when(() => homeCubit.state).thenReturn(const HomeState(selectedIndex: 1));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.byType(StatesHomePage), findsOneWidget);
    });

    testWidgets('switches to VideosHomePage when index is 2', (tester) async {
      when(() => homeCubit.state).thenReturn(const HomeState(selectedIndex: 2));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.byType(VideosHomePage), findsOneWidget);
    });

    testWidgets(
      'animates PageController when selectedIndex changes via BlocConsumer '
      'listener',
      (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        expect(find.byType(AudiosHomePage), findsOneWidget);

        // Change index to 1 -> animates to StatesHomePage
        homeStateController.add(const HomeState(selectedIndex: 1));
        await tester.pump();
        await tester.pump(AppVariables.animationDuration);
        await tester.pumpAndSettle();
        expect(find.byType(StatesHomePage), findsOneWidget);

        // Change index to 2 -> animates to VideosHomePage
        homeStateController.add(const HomeState(selectedIndex: 2));
        await tester.pump();
        await tester.pump(AppVariables.animationDuration);
        await tester.pumpAndSettle();
        expect(find.byType(VideosHomePage), findsOneWidget);

        // Change index back to 0 -> animates to AudiosHomePage
        homeStateController.add(const HomeState());
        await tester.pump();
        await tester.pump(AppVariables.animationDuration);
        await tester.pumpAndSettle();
        expect(find.byType(AudiosHomePage), findsOneWidget);

        // Same index -> listenWhen is false, listener does not animate
        homeStateController.add(const HomeState());
        await tester.pump();
      },
    );

    testWidgets(
      'calls toggleSelectedIndex on NavigationBar destination selections',
      (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());

        final destinations = find.byType(NavigationDestination);

        await tester.tap(destinations.at(1));
        await tester.pump();
        verify(() => homeCubit.toggleSelectedIndex(1)).called(1);

        await tester.tap(destinations.at(0));
        await tester.pump();
        verify(() => homeCubit.toggleSelectedIndex(0)).called(1);

        await tester.tap(destinations.at(2));
        await tester.pump();
        verify(() => homeCubit.toggleSelectedIndex(2)).called(1);
      },
    );

    testWidgets(
      'renders SizedBox.shrink for unknown index (hitting default branch)',
      (tester) async {
        when(
          () => homeCubit.state,
        ).thenReturn(const HomeState(selectedIndex: 3));

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
