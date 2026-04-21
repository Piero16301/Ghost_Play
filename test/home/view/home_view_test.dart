import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_play/app/app.dart';
import 'package:ghost_play/home/home.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';
import '../../helpers/pump_app.dart';

void main() {
  late MockHomeCubit homeCubit;
  late MockPlayerCubit playerCubit;
  late MockAnalyticsService analyticsService;

  setUpAll(() {
    registerFallbackValues();
    setupServiceLocator(Environment.mock);
  });

  setUp(() async {
    homeCubit = MockHomeCubit();
    playerCubit = MockPlayerCubit();
    analyticsService = MockAnalyticsService();

    if (getIt.isRegistered<AnalyticsService>()) {
      await getIt.unregister<AnalyticsService>();
    }
    getIt.registerSingleton<AnalyticsService>(analyticsService);

    when(() => homeCubit.state).thenReturn(const HomeState());
    when(() => homeCubit.initStorage()).thenAnswer((_) async {});
    when(() => homeCubit.loadAudios()).thenAnswer((_) async {});
    when(() => homeCubit.requestPermission()).thenAnswer((_) async {});
    when(() => homeCubit.setWeeks(any())).thenAnswer((_) async {});

    when(() => playerCubit.state).thenReturn(const PlayerState());
    when(() => playerCubit.playAudio(any())).thenAnswer((_) async {});
    when(() => playerCubit.closePlayer()).thenAnswer((_) async {});
  });

  group('HomeView', () {
    testWidgets('renders loading indicator when status is loading', (
      tester,
    ) async {
      when(() => homeCubit.state).thenReturn(
        const HomeState(status: HomeStatus.loading),
      );

      await tester.pumpApp(
        const HomeView(),
        homeCubit: homeCubit,
        playerCubit: playerCubit,
      );

      expect(find.byType(CircularLoadingAnimation), findsOneWidget);
    });

    testWidgets('renders failure message when status is failure', (
      tester,
    ) async {
      when(() => homeCubit.state).thenReturn(
        const HomeState(status: HomeStatus.failure),
      );

      await tester.pumpApp(
        const HomeView(),
        homeCubit: homeCubit,
        playerCubit: playerCubit,
      );

      expect(find.textContaining('An error occurred'), findsOneWidget);
    });

    testWidgets('renders permission request when hasPermission is false', (
      tester,
    ) async {
      when(() => homeCubit.state).thenReturn(
        const HomeState(),
      );

      await tester.pumpApp(
        const HomeView(),
        homeCubit: homeCubit,
        playerCubit: playerCubit,
      );

      expect(find.text('Grant permission'), findsOneWidget);

      await tester.tap(find.text('Grant permission'));
      verify(() => homeCubit.requestPermission()).called(1);
    });

    testWidgets('renders empty message when audios are empty', (
      tester,
    ) async {
      when(() => homeCubit.state).thenReturn(
        const HomeState(hasPermission: true),
      );

      await tester.pumpApp(
        const HomeView(),
        homeCubit: homeCubit,
        playerCubit: playerCubit,
      );

      expect(find.textContaining('No audios found'), findsOneWidget);
    });

    testWidgets('renders list of audios and handles interaction', (
      tester,
    ) async {
      final audio = AudioMetadata(
        name: 'audio1.opus',
        uri: 'uri1',
        date: DateTime.now(),
        sizeBytes: 100,
        durationMs: 3000,
      );
      when(() => homeCubit.state).thenReturn(
        HomeState(
          status: HomeStatus.success,
          audios: [audio],
          hasPermission: true,
        ),
      );

      await tester.pumpApp(
        const HomeView(),
        homeCubit: homeCubit,
        playerCubit: playerCubit,
      );

      expect(find.text('audio1'), findsOneWidget);

      await tester.tap(find.text('audio1'));
      verify(() => playerCubit.playAudio(audio)).called(1);
    });

    testWidgets('handles pull to refresh', (tester) async {
      final audio = AudioMetadata(
        name: 'a',
        uri: 'u',
        date: DateTime.now(),
        sizeBytes: 1,
        durationMs: 1,
      );
      when(() => homeCubit.state).thenReturn(
        HomeState(
          hasPermission: true,
          audios: [audio],
        ),
      );

      await tester.pumpApp(
        const HomeView(),
        homeCubit: homeCubit,
        playerCubit: playerCubit,
      );

      final refreshIndicator = tester.widget<RefreshIndicator>(
        find.byType(RefreshIndicator),
      );
      await refreshIndicator.onRefresh();

      verify(() => homeCubit.loadAudios()).called(greaterThan(0));
    });

    testWidgets('opens weeks menu and selects a value', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final audio = AudioMetadata(
        name: 'a',
        uri: 'u',
        date: DateTime.now(),
        sizeBytes: 1,
        durationMs: 1,
      );
      when(() => homeCubit.state).thenReturn(
        HomeState(hasPermission: true, audios: [audio], weeks: 2),
      );

      await tester.pumpApp(
        const HomeView(),
        homeCubit: homeCubit,
        playerCubit: playerCubit,
      );

      await tester.tap(find.byType(Chip));
      await tester.pumpAndSettle();

      expect(find.text('Filter last weeks'), findsOneWidget);

      await tester.tap(find.text('Last 4 weeks'));
      await tester.pumpAndSettle();

      verify(() => homeCubit.setWeeks(4)).called(1);
    });

    testWidgets('triggers loadAudios on resume if hasPermission', (
      tester,
    ) async {
      when(() => homeCubit.state).thenReturn(
        const HomeState(hasPermission: true),
      );

      await tester.pumpApp(
        const HomeView(),
        homeCubit: homeCubit,
        playerCubit: playerCubit,
      );

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      verify(() => homeCubit.loadAudios()).called(greaterThan(0));
      verify(() => playerCubit.closePlayer()).called(greaterThan(0));
    });

    testWidgets('settings button triggers navigation', (tester) async {
      when(
        () => homeCubit.state,
      ).thenReturn(const HomeState(hasPermission: true));

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const HomeView(),
          ),
          GoRoute(
            name: AppRoute.settings.name,
            path: '/settings',
            builder: (context, state) => const Scaffold(),
          ),
        ],
      );

      await tester.pumpApp(
        const HomeView(),
        homeCubit: homeCubit,
        playerCubit: playerCubit,
        router: router,
      );

      final settingsButton = find.byType(IconButton).first;
      expect(settingsButton, findsOneWidget);

      await tester.tap(settingsButton);
      await tester.pumpAndSettle();
    });

    testWidgets('renders MiniPlayer', (tester) async {
      when(() => homeCubit.state).thenReturn(
        HomeState(
          hasPermission: true,
          audios: [
            AudioMetadata(
              name: 'a',
              uri: 'u',
              date: DateTime(2023),
              sizeBytes: 1,
              durationMs: 1,
            ),
          ],
        ),
      );

      await tester.pumpApp(
        const HomeView(),
        homeCubit: homeCubit,
        playerCubit: playerCubit,
      );

      expect(find.byType(MiniPlayer), findsOneWidget);
    });
  });
}
