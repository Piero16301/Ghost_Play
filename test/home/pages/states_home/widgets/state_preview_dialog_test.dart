import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_play/app/app.dart';
import 'package:ghost_play/home/home.dart';
import 'package:mocktail/mocktail.dart';
import 'package:video_player/video_player.dart';
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
  late StatesHomeCubit statesHomeCubit;
  late VideoPlayerPlatform originalVideoPlayerPlatform;

  setUpAll(registerFallbackValues);

  setUp(() async {
    await setupServiceLocatorMocks();
    homeCubit = MockHomeCubit();
    statesHomeCubit = MockStatesHomeCubit();

    when(() => homeCubit.state).thenReturn(const HomeState());
    when(() => statesHomeCubit.state).thenReturn(const StatesHomeState());
    when(() => homeCubit.loadStates()).thenAnswer((_) async {});

    final mockTrace = MockTrace();
    when(
      () => getIt<PerformanceService>().startTrace(any<String>()),
    ).thenReturn(mockTrace);
    when(
      () => getIt<PerformanceService>().stopTrace(any()),
    ).thenAnswer((_) async {});

    when(
      () => getIt<CrashService>().log(any<String>()),
    ).thenAnswer((_) {});
    when(
      () => getIt<CrashService>().recordError(
        any<Object>(),
        any<StackTrace>(),
        reason: any<String>(named: 'reason'),
      ),
    ).thenAnswer((_) {});

    when(
      () => getIt<AnalyticsService>().logEvent(
        name: any(named: 'name'),
        parameters: any(named: 'parameters'),
      ),
    ).thenAnswer((_) {});

    when(
      () => getIt<StorageService>().getThumbnailBytes(
        uri: any(named: 'uri'),
        isVideo: any(named: 'isVideo'),
      ),
    ).thenAnswer((_) async => null);

    originalVideoPlayerPlatform = VideoPlayerPlatform.instance;
  });

  tearDown(() {
    VideoPlayerPlatform.instance = originalVideoPlayerPlatform;
  });

  StateMetadata makeItem({bool isVideo = false}) => StateMetadata(
    uri: 'content://test/uri',
    name: 'test_file.jpg',
    date: DateTime(2024),
    isVideo: isVideo,
    sizeBytes: 1024,
  );

  String createTmpPng(String name) {
    final file = File('${Directory.systemTemp.path}/$name')
      ..writeAsBytesSync(_kValidPng);
    return file.path;
  }

  Future<void> pumpDialog(
    WidgetTester tester,
    StateMetadata item,
  ) async {
    await tester.pumpApp(
      Builder(
        builder: (context) => TextButton(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) => StatePreviewDialog(item: item),
          ),
          child: const Text('Open'),
        ),
      ),
      homeCubit: homeCubit,
      statesHomeCubit: statesHomeCubit,
    );
    await tester.tap(find.text('Open'));
    await tester.pump();
  }

  void mockGalChannel({
    bool hasAccess = true,
    bool requestAccess = true,
    bool throwOnPutImage = false,
    List<String>? calls,
  }) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('gal'),
          (call) async {
            calls?.add(call.method);
            switch (call.method) {
              case 'hasAccess':
                return hasAccess;
              case 'requestAccess':
                return requestAccess;
              case 'putImage':
                if (throwOnPutImage) {
                  throw PlatformException(
                    code: 'save_failed',
                    message: 'save failed',
                  );
                }
                return null;
              case 'putVideo':
                return null;
              default:
                return null;
            }
          },
        );
  }

  group('StatePreviewDialog', () {
    testWidgets('shows CircularProgressIndicator while loading', (
      tester,
    ) async {
      final completer = Completer<String?>();
      when(
        () => getIt<StorageService>().cacheFile(
          uri: any(named: 'uri'),
          fileName: any(named: 'fileName'),
        ),
      ).thenAnswer((_) => completer.future);

      await pumpDialog(tester, makeItem());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Cancel'), findsNothing);
      expect(find.text('Save'), findsNothing);

      completer.complete(null);
    });

    testWidgets('shows error state when cacheFile returns null', (
      tester,
    ) async {
      when(
        () => getIt<StorageService>().cacheFile(
          uri: any(named: 'uri'),
          fileName: any(named: 'fileName'),
        ),
      ).thenAnswer((_) async => null);

      await pumpDialog(tester, makeItem());
      await tester.pumpAndSettle();

      expect(find.text('Error loading preview'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Save'), findsNothing);

      verify(
        () => getIt<CrashService>().recordError(
          any<Object>(),
          any<StackTrace>(),
          reason: 'Error caching and init state preview',
        ),
      ).called(1);

      verify(
        () =>
            getIt<PerformanceService>().startTrace('state_preview_cache_init'),
      ).called(1);
      verify(() => getIt<PerformanceService>().stopTrace(any())).called(1);
    });

    testWidgets('shows error state when cacheFile throws exception', (
      tester,
    ) async {
      when(
        () => getIt<StorageService>().cacheFile(
          uri: any(named: 'uri'),
          fileName: any(named: 'fileName'),
        ),
      ).thenThrow(Exception('cache boom'));

      await pumpDialog(tester, makeItem());
      await tester.pumpAndSettle();

      expect(find.text('Error loading preview'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Save'), findsNothing);

      verify(
        () => getIt<CrashService>().recordError(
          any<Object>(),
          any<StackTrace>(),
          reason: 'Error caching and init state preview',
        ),
      ).called(1);
    });

    testWidgets('Cancel button pops dialog in error state', (tester) async {
      when(
        () => getIt<StorageService>().cacheFile(
          uri: any(named: 'uri'),
          fileName: any(named: 'fileName'),
        ),
      ).thenAnswer((_) async => null);

      await pumpDialog(tester, makeItem());
      await tester.pumpAndSettle();

      expect(find.byType(StatePreviewDialog), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byType(StatePreviewDialog), findsNothing);
    });

    testWidgets('shows title, Save and Cancel after successful image cache', (
      tester,
    ) async {
      final path = createTmpPng('dialog_success.png');
      when(
        () => getIt<StorageService>().cacheFile(
          uri: any(named: 'uri'),
          fileName: any(named: 'fileName'),
        ),
      ).thenAnswer((_) async => path);

      await pumpDialog(tester, makeItem());
      await tester.pumpAndSettle();

      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);

      File(path).deleteSync();
    });

    testWidgets('Cancel button pops dialog in success state', (tester) async {
      final path = createTmpPng('dialog_cancel_success.png');
      when(
        () => getIt<StorageService>().cacheFile(
          uri: any(named: 'uri'),
          fileName: any(named: 'fileName'),
        ),
      ).thenAnswer((_) async => path);

      await pumpDialog(tester, makeItem());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byType(StatePreviewDialog), findsNothing);

      File(path).deleteSync();
    });

    testWidgets('Save button calls putImage when gallery access is granted', (
      tester,
    ) async {
      mockGalChannel();
      final path = createTmpPng('dialog_save_image.png');
      when(
        () => getIt<StorageService>().cacheFile(
          uri: any(named: 'uri'),
          fileName: any(named: 'fileName'),
        ),
      ).thenAnswer((_) async => path);

      await pumpDialog(tester, makeItem());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.byType(StatePreviewDialog), findsNothing);

      verify(
        () => getIt<PerformanceService>().startTrace('state_save_to_gallery'),
      ).called(1);
      verify(() => getIt<PerformanceService>().stopTrace(any())).called(2);

      File(path).deleteSync();
    });

    testWidgets(
      'Save requests access and saves when initially denied then granted',
      (
        tester,
      ) async {
        mockGalChannel(hasAccess: false);
        final path = createTmpPng('dialog_save_request.png');
        when(
          () => getIt<StorageService>().cacheFile(
            uri: any(named: 'uri'),
            fileName: any(named: 'fileName'),
          ),
        ).thenAnswer((_) async => path);

        await pumpDialog(tester, makeItem());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(find.byType(StatePreviewDialog), findsNothing);

        File(path).deleteSync();
      },
    );

    testWidgets('Save shows error snackbar when gallery access is denied', (
      tester,
    ) async {
      mockGalChannel(hasAccess: false, requestAccess: false);
      final path = createTmpPng('dialog_denied.png');
      when(
        () => getIt<StorageService>().cacheFile(
          uri: any(named: 'uri'),
          fileName: any(named: 'fileName'),
        ),
      ).thenAnswer((_) async => path);

      await pumpDialog(tester, makeItem());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.byType(StatePreviewDialog), findsOneWidget);
      expect(find.text('Permission denied'), findsOneWidget);

      File(path).deleteSync();
    });

    testWidgets('Save logs success and closes dialog after putImage succeeds', (
      tester,
    ) async {
      mockGalChannel();
      final path = createTmpPng('dialog_save_log.png');
      when(
        () => getIt<StorageService>().cacheFile(
          uri: any(named: 'uri'),
          fileName: any(named: 'fileName'),
        ),
      ).thenAnswer((_) async => path);

      await pumpDialog(tester, makeItem());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      verify(
        () => getIt<AnalyticsService>().logEvent(
          name: 'save_to_gallery_action',
          parameters: any(named: 'parameters'),
        ),
      ).called(1);

      expect(find.byType(StatePreviewDialog), findsNothing);

      File(path).deleteSync();
    });

    testWidgets('Save shows error snackbar when putImage throws exception', (
      tester,
    ) async {
      mockGalChannel(throwOnPutImage: true);
      final path = createTmpPng('dialog_save_error.png');
      when(
        () => getIt<StorageService>().cacheFile(
          uri: any(named: 'uri'),
          fileName: any(named: 'fileName'),
        ),
      ).thenAnswer((_) async => path);

      await pumpDialog(tester, makeItem());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.byType(StatePreviewDialog), findsOneWidget);
      expect(find.text('Error saving'), findsOneWidget);

      verify(
        () => getIt<CrashService>().recordError(
          any<Object>(),
          any<StackTrace>(),
          reason: 'Error saving state to gallery',
        ),
      ).called(1);

      File(path).deleteSync();
    });

    testWidgets('video item save uses putVideo', (
      tester,
    ) async {
      VideoPlayerPlatform.instance = _FakeVideoPlayerPlatform(
        duration: const Duration(hours: 1, minutes: 1, seconds: 1),
      );
      final calls = <String>[];
      mockGalChannel(calls: calls);
      final path = createTmpPng('dialog_video_save.mp4');
      when(
        () => getIt<StorageService>().cacheFile(
          uri: any(named: 'uri'),
          fileName: any(named: 'fileName'),
        ),
      ).thenAnswer((_) async => path);

      await pumpDialog(tester, makeItem(isVideo: true));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Save'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(StatePreviewDialog), findsNothing);
      expect(calls.where((method) => method == 'putVideo').length, 1);
      expect(calls.where((method) => method == 'putImage'), isEmpty);

      File(path).deleteSync();
    });

    testWidgets('video content uses 9/16 when aspect ratio is 1:1', (
      tester,
    ) async {
      VideoPlayerPlatform.instance = _FakeVideoPlayerPlatform(
        duration: const Duration(seconds: 10),
        videoSize: const Size(100, 100),
      );
      final path = createTmpPng('dialog_video_ratio_square.mp4');
      when(
        () => getIt<StorageService>().cacheFile(
          uri: any(named: 'uri'),
          fileName: any(named: 'fileName'),
        ),
      ).thenAnswer((_) async => path);

      await pumpDialog(tester, makeItem(isVideo: true));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      final videoAspectRatioFinder = find.ancestor(
        of: find.byType(VideoPlayer),
        matching: find.byType(AspectRatio),
      );
      final videoAspectRatio = tester.widget<AspectRatio>(
        videoAspectRatioFinder.first,
      );

      expect(videoAspectRatio.aspectRatio, closeTo(9 / 16, 0.0001));

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      File(path).deleteSync();
    });

    testWidgets('video content inverts aspect ratio when rotated 90 degrees', (
      tester,
    ) async {
      VideoPlayerPlatform.instance = _FakeVideoPlayerPlatform(
        duration: const Duration(seconds: 10),
        rotationCorrection: 90,
      );
      final path = createTmpPng('dialog_video_ratio_rotated.mp4');
      when(
        () => getIt<StorageService>().cacheFile(
          uri: any(named: 'uri'),
          fileName: any(named: 'fileName'),
        ),
      ).thenAnswer((_) async => path);

      await pumpDialog(tester, makeItem(isVideo: true));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      final videoAspectRatioFinder = find.ancestor(
        of: find.byType(VideoPlayer),
        matching: find.byType(AspectRatio),
      );
      final videoAspectRatio = tester.widget<AspectRatio>(
        videoAspectRatioFinder.first,
      );

      expect(videoAspectRatio.aspectRatio, closeTo(16 / 9, 0.0001));

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      File(path).deleteSync();
    });

    testWidgets('video controls handle pause, replay from end and volume', (
      tester,
    ) async {
      final fakePlatform = _FakeVideoPlayerPlatform(
        duration: Duration.zero,
      );
      VideoPlayerPlatform.instance = fakePlatform;
      final path = createTmpPng('dialog_video_controls.mp4');
      when(
        () => getIt<StorageService>().cacheFile(
          uri: any(named: 'uri'),
          fileName: any(named: 'fileName'),
        ),
      ).thenAnswer((_) async => path);

      await pumpDialog(tester, makeItem(isVideo: true));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      fakePlatform.emitIsPlaying(isPlaying: true);
      await tester.pump();

      await tester.tap(find.byType(IconButton).first);
      await tester.pump();
      await tester.tap(find.byType(IconButton).first);
      await tester.pump();

      await tester.tap(find.byType(IconButton).last);
      await tester.pump();

      expect(fakePlatform.pauseCalls, greaterThanOrEqualTo(1));
      expect(fakePlatform.playCalls, greaterThanOrEqualTo(1));
      expect(fakePlatform.seekCalls.contains(Duration.zero), isTrue);
      expect(fakePlatform.setVolumeCalls.contains(0), isTrue);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      File(path).deleteSync();
    });

    testWidgets('video slider onChanged and onChangeEnd update and seek', (
      tester,
    ) async {
      final fakePlatform = _FakeVideoPlayerPlatform(
        duration: const Duration(seconds: 5),
      );
      VideoPlayerPlatform.instance = fakePlatform;
      final path = createTmpPng('dialog_video_slider.mp4');
      when(
        () => getIt<StorageService>().cacheFile(
          uri: any(named: 'uri'),
          fileName: any(named: 'fileName'),
        ),
      ).thenAnswer((_) async => path);

      await pumpDialog(tester, makeItem(isVideo: true));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.onChanged, isNotNull);
      expect(slider.onChangeEnd, isNotNull);

      slider.onChanged!(1200);
      await tester.pump();

      final sliderAfterChange = tester.widget<Slider>(find.byType(Slider));
      sliderAfterChange.onChangeEnd!(1200);
      await tester.pump();

      expect(
        fakePlatform.seekCalls.contains(const Duration(milliseconds: 1200)),
        isTrue,
      );

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      File(path).deleteSync();
    });
  });
}

class _FakeVideoPlayerPlatform extends VideoPlayerPlatform {
  _FakeVideoPlayerPlatform({
    required this.duration,
    this.videoSize = const Size(1080, 1920),
    this.rotationCorrection = 0,
  });

  final Duration duration;
  final Size videoSize;
  final int rotationCorrection;
  final Map<int, StreamController<VideoEvent>> _eventControllers = {};
  final Map<int, Duration> _positions = {};
  var _nextTextureId = 1;
  int? _lastPlayerId;
  var _isPlaying = false;
  int pauseCalls = 0;
  int playCalls = 0;
  final seekCalls = <Duration>[];
  final setVolumeCalls = <double>[];

  @override
  Future<void> init() async {}

  @override
  Future<void> dispose(int playerId) async {}

  @override
  Future<int?> create(DataSource dataSource) async {
    final id = _nextTextureId++;
    _positions[id] = Duration.zero;
    _lastPlayerId = id;

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
  Future<void> play(int playerId) async {
    _isPlaying = true;
    playCalls++;
    _eventControllers[playerId]!.add(
      VideoEvent(
        eventType: VideoEventType.isPlayingStateUpdate,
        isPlaying: _isPlaying,
      ),
    );
  }

  @override
  Future<void> pause(int playerId) async {
    _isPlaying = false;
    pauseCalls++;
    _eventControllers[playerId]!.add(
      VideoEvent(
        eventType: VideoEventType.isPlayingStateUpdate,
        isPlaying: _isPlaying,
      ),
    );
  }

  @override
  Future<void> setVolume(int playerId, double volume) async {
    setVolumeCalls.add(volume);
  }

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}

  @override
  Future<void> seekTo(int playerId, Duration position) async {
    _positions[playerId] = position;
    seekCalls.add(position);
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

  void emitIsPlaying({required bool isPlaying}) {
    final playerId = _lastPlayerId;
    if (playerId == null) return;
    _isPlaying = isPlaying;
    _eventControllers[playerId]!.add(
      VideoEvent(
        eventType: VideoEventType.isPlayingStateUpdate,
        isPlaying: isPlaying,
      ),
    );
  }
}
