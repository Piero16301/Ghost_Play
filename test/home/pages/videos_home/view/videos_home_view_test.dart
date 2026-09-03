import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_play/app/app.dart';
import 'package:ghost_play/home/home.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import '../../../../helpers/mocks.dart';
import '../../../../helpers/pump_app.dart';
import '../../../../helpers/service_locator.dart';

const _kValidPng = <int>[
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

void main() {
  late HomeCubit homeCubit;
  late VideoPlayerPlatform originalVideoPlayerPlatform;

  setUpAll(registerFallbackValues);

  setUp(() async {
    await setupServiceLocatorMocks();
    homeCubit = MockHomeCubit();

    when(() => homeCubit.state).thenReturn(const HomeState());
    when(() => homeCubit.loadVideos()).thenAnswer((_) async {});
    when(() => homeCubit.requestPermission()).thenAnswer((_) async {});
    when(() => homeCubit.setVideosWeeks(any<int>())).thenAnswer((_) async {});

    final storageService = getIt<StorageService>();
    when(
      () => storageService.getThumbnailBytes(
        uri: any(named: 'uri'),
        isVideo: any(named: 'isVideo'),
      ),
    ).thenAnswer((_) async => Uint8List.fromList(_kValidPng));

    when(
      () => storageService.cacheFile(
        uri: any(named: 'uri'),
        fileName: any(named: 'fileName'),
      ),
    ).thenAnswer((_) async => 'cached_path');

    when(
      () => getIt<PerformanceService>().startTrace(any<String>()),
    ).thenReturn(MockTrace());
    when(
      () => getIt<PerformanceService>().stopTrace(any()),
    ).thenAnswer((_) async {});

    originalVideoPlayerPlatform = VideoPlayerPlatform.instance;
  });

  tearDown(() {
    VideoPlayerPlatform.instance = originalVideoPlayerPlatform;
  });

  group('VideosHomeView', () {
    testWidgets('renders CircularLoadingAnimation when loading', (
      tester,
    ) async {
      when(
        () => homeCubit.state,
      ).thenReturn(const HomeState(videosStatus: HomeStatus.loading));
      await tester.pumpApp(
        const VideosHomeView(),
        homeCubit: homeCubit,
        locale: const Locale('en'),
      );
      expect(find.byType(CircularLoadingAnimation), findsOneWidget);
    });

    testWidgets('renders failure message when status is failure', (
      tester,
    ) async {
      when(
        () => homeCubit.state,
      ).thenReturn(const HomeState(videosStatus: HomeStatus.failure));
      await tester.pumpApp(
        const VideosHomeView(),
        homeCubit: homeCubit,
        locale: const Locale('en'),
      );
      expect(
        find.textContaining('An error occurred while loading the video notes'),
        findsOneWidget,
      );
    });

    testWidgets('renders permission screen when no permission', (tester) async {
      when(
        () => homeCubit.state,
      ).thenReturn(const HomeState());
      await tester.pumpApp(
        const VideosHomeView(),
        homeCubit: homeCubit,
        locale: const Locale('en'),
      );
      expect(find.text('Grant permission'), findsOneWidget);

      await tester.tap(find.text('Grant permission'));
      verify(() => homeCubit.requestPermission()).called(1);
    });

    testWidgets('renders no videos found message when list is empty', (
      tester,
    ) async {
      when(() => homeCubit.state).thenReturn(
        const HomeState(
          hasPermission: true,
          videosStatus: HomeStatus.success,
        ),
      );
      await tester.pumpApp(
        const VideosHomeView(),
        homeCubit: homeCubit,
        locale: const Locale('en'),
      );
      expect(find.text('No video notes found yet'), findsOneWidget);
    });

    testWidgets('renders grid of videos and opens preview on tap', (
      tester,
    ) async {
      VideoPlayerPlatform.instance = _FakeVideoPlayerPlatform(
        duration: const Duration(seconds: 10),
        videoSize: const Size(1080, 1920),
        rotationCorrection: 0,
      );

      final video = MultimediaMetadata(
        uri: 'u',
        name: 'name.mp4',
        date: DateTime(2024),
        sizeBytes: 100,
        isVideo: true,
      );
      when(() => homeCubit.state).thenReturn(
        HomeState(
          hasPermission: true,
          videosStatus: HomeStatus.success,
          videos: [video],
        ),
      );

      await tester.pumpApp(
        const VideosHomeView(),
        homeCubit: homeCubit,
        locale: const Locale('en'),
      );
      await tester.pumpAndSettle();

      expect(find.byType(GridView), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: find.byType(GridView),
          matching: find.byType(InkWell),
        ),
      );
      await tester.pump();

      verify(
        () => getIt<AnalyticsService>().logEvent(
          name: 'preview_video_action',
          parameters: {'uri': 'u'},
        ),
      ).called(1);
    });

    testWidgets('shows weeks menu and calls setVideosWeeks', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final video = MultimediaMetadata(
        uri: 'u',
        name: 'name.mp4',
        date: DateTime(2024),
        sizeBytes: 100,
        isVideo: true,
      );
      when(() => homeCubit.state).thenReturn(
        HomeState(
          hasPermission: true,
          videosStatus: HomeStatus.success,
          videos: [video],
        ),
      );

      await tester.pumpApp(
        const VideosHomeView(),
        homeCubit: homeCubit,
        locale: const Locale('en'),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Chip));
      await tester.pumpAndSettle();
      tester.takeException();

      await tester.tap(find.textContaining('2').last);
      await tester.pumpAndSettle();

      verify(() => homeCubit.setVideosWeeks(2)).called(1);
    });
  });
}

class _FakeVideoPlayerPlatform extends VideoPlayerPlatform {
  _FakeVideoPlayerPlatform({
    required this.videoSize,
    required this.rotationCorrection,
    required this.duration,
  });

  final Duration duration;
  final Size videoSize;
  final int rotationCorrection;
  final Map<int, StreamController<VideoEvent>> _eventControllers = {};
  final Map<int, Duration> _positions = {};
  var _nextTextureId = 1;

  @override
  Future<void> init() async {}

  @override
  Future<void> dispose(int playerId) async {}

  @override
  Future<int?> create(DataSource dataSource) async {
    final id = _nextTextureId++;
    _positions[id] = Duration.zero;

    _eventControllers[id] = StreamController<VideoEvent>.broadcast(
      onListen: () {
        _eventControllers[id]!.add(
          VideoEvent(
            eventType: VideoEventType.initialized,
            duration: duration,
            size: videoSize,
            rotationCorrection: rotationCorrection,
          ),
        );
      },
    );

    return id;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) {
    return _eventControllers[playerId]!.stream;
  }

  @override
  Future<void> setLooping(int playerId, bool looping) async {}

  @override
  Future<void> play(int playerId) async {}

  @override
  Future<void> pause(int playerId) async {}

  @override
  Future<void> setVolume(int playerId, double volume) async {}

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}

  @override
  Future<void> seekTo(int playerId, Duration position) async {
    _positions[playerId] = position;
  }

  @override
  Future<Duration> getPosition(int playerId) async {
    return _positions[playerId] ?? Duration.zero;
  }

  @override
  Widget buildView(int playerId) {
    return const SizedBox.shrink();
  }

  @override
  Future<void> setMixWithOthers(bool mixWithOthers) async {}
}
