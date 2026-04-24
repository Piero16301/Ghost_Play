import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_play/app/app.dart';
import 'package:ghost_play/home/home.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mocks.dart';
import '../../../../helpers/pump_app.dart';
import '../../../../helpers/service_locator.dart';

void main() {
  late HomeCubit homeCubit;
  late StatesHomeCubit statesHomeCubit;

  setUpAll(registerFallbackValues);

  setUp(() async {
    await setupServiceLocatorMocks();
    homeCubit = MockHomeCubit();
    statesHomeCubit = MockStatesHomeCubit();

    when(() => homeCubit.state).thenReturn(const HomeState());
    when(() => statesHomeCubit.state).thenReturn(const StatesHomeState());

    when(() => homeCubit.loadStates()).thenAnswer((_) async {});
    when(() => homeCubit.requestPermission()).thenAnswer((_) async {});

    when(
      () => getIt<StorageService>().getThumbnailBytes(
        uri: any(named: 'uri'),
        isVideo: any(named: 'isVideo'),
      ),
    ).thenAnswer((_) async => null);

    when(
      () => getIt<StorageService>().cacheFile(
        uri: any(named: 'uri'),
        fileName: any(named: 'fileName'),
      ),
    ).thenAnswer((_) async => null);

    when(
      () => getIt<AnalyticsService>().logEvent(
        name: any(named: 'name'),
        parameters: any(named: 'parameters'),
      ),
    ).thenAnswer((_) {});

    when(
      () => getIt<CrashService>().log(any()),
    ).thenAnswer((_) {});

    when(
      () => getIt<CrashService>().recordError(
        any<Object>(),
        any<StackTrace>(),
        reason: any<String>(named: 'reason'),
      ),
    ).thenAnswer((_) {});

    final mockTrace = MockTrace();
    when(
      () => getIt<PerformanceService>().startTrace(any()),
    ).thenReturn(mockTrace);
    when(
      () => getIt<PerformanceService>().stopTrace(any()),
    ).thenAnswer((_) async {});
  });

  group('StatesHomeView', () {
    testWidgets('renders CircularLoadingAnimation when loading', (
      tester,
    ) async {
      when(() => homeCubit.state).thenReturn(
        const HomeState(statesStatus: HomeStatus.loading),
      );

      await tester.pumpApp(
        const StatesHomeView(),
        homeCubit: homeCubit,
        statesHomeCubit: statesHomeCubit,
      );

      expect(find.byType(CircularLoadingAnimation), findsOneWidget);
    });

    testWidgets('renders failure message when status is failure', (
      tester,
    ) async {
      when(() => homeCubit.state).thenReturn(
        const HomeState(statesStatus: HomeStatus.failure),
      );

      await tester.pumpApp(
        const StatesHomeView(),
        homeCubit: homeCubit,
        statesHomeCubit: statesHomeCubit,
      );

      expect(
        find.text(
          'An error occurred while loading the states, please restart the app',
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders permission screen when no permission', (tester) async {
      when(() => homeCubit.state).thenReturn(
        const HomeState(),
      );

      await tester.pumpApp(
        const StatesHomeView(),
        homeCubit: homeCubit,
        statesHomeCubit: statesHomeCubit,
      );

      expect(find.text('Grant permission'), findsOneWidget);

      await tester.tap(find.text('Grant permission'));
      verify(() => homeCubit.requestPermission()).called(1);
    });

    testWidgets('renders no states found message when list is empty', (
      tester,
    ) async {
      when(() => homeCubit.state).thenReturn(
        const HomeState(hasPermission: true),
      );

      await tester.pumpApp(
        const StatesHomeView(),
        homeCubit: homeCubit,
        statesHomeCubit: statesHomeCubit,
      );

      expect(find.text('No states found yet'), findsOneWidget);
    });

    testWidgets('renders grid of states and opens preview on tap', (
      tester,
    ) async {
      final stateItem = StateMetadata(
        uri: 'uri',
        name: 'test.jpg',
        date: DateTime.now(),
        isVideo: false,
        sizeBytes: 1024,
      );

      when(() => homeCubit.state).thenReturn(
        HomeState(hasPermission: true, states: [stateItem]),
      );

      await tester.pumpApp(
        const StatesHomeView(),
        homeCubit: homeCubit,
        statesHomeCubit: statesHomeCubit,
      );

      expect(find.byType(GridView), findsOneWidget);

      await tester.tap(find.byType(InkWell));
      await tester.pump();

      verify(
        () => getIt<AnalyticsService>().logEvent(
          name: 'preview_state_action',
          parameters: {'uri': 'uri'},
        ),
      ).called(1);

      expect(find.byType(StatePreviewDialog), findsOneWidget);
    });

    testWidgets('calls loadStates on refresh', (tester) async {
      when(() => homeCubit.state).thenReturn(
        HomeState(
          hasPermission: true,
          states: [
            StateMetadata(
              uri: 'uri',
              name: 'test.jpg',
              date: DateTime.now(),
              isVideo: false,
              sizeBytes: 1024,
            ),
          ],
        ),
      );

      await tester.pumpApp(
        const StatesHomeView(),
        homeCubit: homeCubit,
        statesHomeCubit: statesHomeCubit,
      );

      final refreshIndicator = tester.widget<RefreshIndicator>(
        find.byType(RefreshIndicator),
      );
      await refreshIndicator.onRefresh();
      await tester.pumpAndSettle();

      verify(() => homeCubit.loadStates()).called(1);
    });
    testWidgets('renders Image.memory when thumbnail bytes are available', (
      tester,
    ) async {
      const validPng = <int>[
        0x89,
        0x50,
        0x4E,
        0x47,
        0x0D,
        0x0A,
        0x1A,
        0x0A,
        0x00,
        0x00,
        0x00,
        0x0D,
        0x49,
        0x48,
        0x44,
        0x52,
        0x00,
        0x00,
        0x00,
        0x01,
        0x00,
        0x00,
        0x00,
        0x01,
        0x08,
        0x02,
        0x00,
        0x00,
        0x00,
        0x90,
        0x77,
        0x53,
        0xDE,
        0x00,
        0x00,
        0x00,
        0x0C,
        0x49,
        0x44,
        0x41,
        0x54,
        0x08,
        0xD7,
        0x63,
        0xF8,
        0xCF,
        0xC0,
        0x00,
        0x00,
        0x00,
        0x02,
        0x00,
        0x01,
        0xE2,
        0x21,
        0xBC,
        0x33,
        0x00,
        0x00,
        0x00,
        0x00,
        0x49,
        0x45,
        0x4E,
        0x44,
        0xAE,
        0x42,
        0x60,
        0x82,
      ];
      final thumbBytes = Uint8List.fromList(validPng);
      when(
        () => getIt<StorageService>().getThumbnailBytes(
          uri: any(named: 'uri'),
          isVideo: any(named: 'isVideo'),
        ),
      ).thenAnswer((_) async => thumbBytes);

      final stateItem = StateMetadata(
        uri: 'uri',
        name: 'test.jpg',
        date: DateTime.now(),
        isVideo: false,
        sizeBytes: 1024,
      );

      when(() => homeCubit.state).thenReturn(
        HomeState(hasPermission: true, states: [stateItem]),
      );

      await tester.pumpApp(
        const StatesHomeView(),
        homeCubit: homeCubit,
        statesHomeCubit: statesHomeCubit,
      );

      await tester.pump();

      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('renders play icon overlay for video items', (
      tester,
    ) async {
      final stateItem = StateMetadata(
        uri: 'video_uri',
        name: 'test.mp4',
        date: DateTime.now(),
        isVideo: true,
        sizeBytes: 2048,
      );

      when(() => homeCubit.state).thenReturn(
        HomeState(hasPermission: true, states: [stateItem]),
      );

      await tester.pumpApp(
        const StatesHomeView(),
        homeCubit: homeCubit,
        statesHomeCubit: statesHomeCubit,
      );

      await tester.pump();

      expect(find.byType(GridView), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is HugeIcon && w.icon == HugeIcons.strokeRoundedPlayCircle,
        ),
        findsOneWidget,
      );
    });
  });
}
