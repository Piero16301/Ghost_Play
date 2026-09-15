import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_play/app/app.dart';
import 'package:ghost_play/home/home.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import '../../helpers/mocks.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/service_locator.dart';

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

    final mockTrace = MockTrace();
    when(
      () => getIt<PerformanceService>().startTrace(any<String>()),
    ).thenReturn(mockTrace);
    when(
      () => getIt<PerformanceService>().stopTrace(any()),
    ).thenAnswer((_) async {});

    when(() => getIt<CrashService>().log(any<String>())).thenAnswer((_) {});
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

    originalVideoPlayerPlatform = VideoPlayerPlatform.instance;
  });

  tearDown(() {
    VideoPlayerPlatform.instance = originalVideoPlayerPlatform;
  });

  MultimediaMetadata makeItem() => MultimediaMetadata(
    uri: 'content://test/video_note.mp4',
    name: 'PTV-20260914-WA0001.mp4',
    date: DateTime(2024),
    isVideo: true,
    sizeBytes: 1024 * 1024 * 2,
  );

  String createTmpMp4(String name) {
    final file = File('${Directory.systemTemp.path}/$name')
      ..writeAsBytesSync(_kValidPng);
    return file.path;
  }

  Future<void> pumpDialog(WidgetTester tester, MultimediaMetadata item) async {
    await tester.pumpApp(
      Builder(
        builder: (context) => TextButton(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) => VideoNotePreviewDialog(item: item),
          ),
          child: const Text('Open'),
        ),
      ),
      homeCubit: homeCubit,
    );
    await tester.tap(find.text('Open'));
    await tester.pump();
  }

  void mockGalChannel({
    bool hasAccess = true,
    bool requestAccess = true,
    bool throwOnPutVideo = false,
    List<String>? calls,
  }) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('gal'), (call) async {
          calls?.add(call.method);
          switch (call.method) {
            case 'hasAccess':
              return hasAccess;
            case 'requestAccess':
              return requestAccess;
            case 'putVideo':
              if (throwOnPutVideo) {
                throw PlatformException(
                  code: 'save_failed',
                  message: 'save failed',
                );
              }
              return null;
            default:
              return null;
          }
        });
  }

  group('VideoNotePreviewDialog', () {
    testWidgets('shows loading state initially', (tester) async {
      final completer = Completer<String?>();
      when(
        () => getIt<StorageService>().cacheFile(
          uri: any(named: 'uri'),
          fileName: any(named: 'fileName'),
        ),
      ).thenAnswer((_) => completer.future);

      await pumpDialog(tester, makeItem());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete(null);
      await tester.pumpAndSettle();
    });

    testWidgets('shows error state when cache fails', (tester) async {
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

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byType(VideoNotePreviewDialog), findsNothing);
    });

    testWidgets('renders successfully with controls and circular player', (
      tester,
    ) async {
      VideoPlayerPlatform.instance = _FakeVideoPlayerPlatform(
        duration: const Duration(seconds: 30),
      );
      final path = createTmpMp4('video_note_success.mp4');
      when(
        () => getIt<StorageService>().cacheFile(
          uri: any(named: 'uri'),
          fileName: any(named: 'fileName'),
        ),
      ).thenAnswer((_) async => path);

      await pumpDialog(tester, makeItem());
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(VideoNotePreviewDialog), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      File(path).deleteSync();
    });

    testWidgets(
      'dialog does not expand to full screen height on large screens',
      (tester) async {
        VideoPlayerPlatform.instance = _FakeVideoPlayerPlatform(
          duration: const Duration(seconds: 30),
        );
        final path = createTmpMp4('video_note_height.mp4');
        when(
          () => getIt<StorageService>().cacheFile(
            uri: any(named: 'uri'),
            fileName: any(named: 'fileName'),
          ),
        ).thenAnswer((_) async => path);

        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await pumpDialog(tester, makeItem());
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(VideoNotePreviewDialog), findsOneWidget);

        // Verify the inner content container height is compact (~385)
        // and dialog doesn't take the full screen height (1200)
        final contentContainerFinder = find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.constraints?.maxWidth == 500 &&
              widget.child is Column,
        );
        expect(contentContainerFinder, findsOneWidget);
        final contentSize = tester.getSize(contentContainerFinder);
        expect(contentSize.height, lessThan(450));

        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        File(path).deleteSync();
      },
    );

    testWidgets('plays and pauses when tapping play/pause button', (
      tester,
    ) async {
      final fakePlatform = _FakeVideoPlayerPlatform(
        duration: const Duration(seconds: 20),
      );
      VideoPlayerPlatform.instance = fakePlatform;
      final path = createTmpMp4('video_note_play_pause.mp4');
      when(
        () => getIt<StorageService>().cacheFile(
          uri: any(named: 'uri'),
          fileName: any(named: 'fileName'),
        ),
      ).thenAnswer((_) async => path);

      await pumpDialog(tester, makeItem());
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      // Initially plays
      expect(fakePlatform.playCalls, greaterThanOrEqualTo(1));

      // Tap pause
      final pauseButton = find.byWidgetPredicate(
        (widget) =>
            widget is HugeIcon && widget.icon == HugeIcons.strokeRoundedPause,
      );
      if (pauseButton.evaluate().isNotEmpty) {
        await tester.tap(pauseButton.first);
        await tester.pump(const Duration(milliseconds: 100));
        expect(fakePlatform.pauseCalls, greaterThanOrEqualTo(1));
      }

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      File(path).deleteSync();
    });

    testWidgets('toggles volume when tapping volume button', (tester) async {
      final fakePlatform = _FakeVideoPlayerPlatform(
        duration: const Duration(seconds: 20),
      );
      VideoPlayerPlatform.instance = fakePlatform;
      final path = createTmpMp4('video_note_volume.mp4');
      when(
        () => getIt<StorageService>().cacheFile(
          uri: any(named: 'uri'),
          fileName: any(named: 'fileName'),
        ),
      ).thenAnswer((_) async => path);

      await pumpDialog(tester, makeItem());
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      final volumeIcon = find.byWidgetPredicate(
        (widget) =>
            widget is HugeIcon &&
            widget.icon == HugeIcons.strokeRoundedVolumeHigh,
      );
      expect(volumeIcon, findsOneWidget);

      await tester.tap(volumeIcon);
      await tester.pump(const Duration(milliseconds: 100));
      expect(fakePlatform.setVolumeCalls.contains(0), isTrue);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      File(path).deleteSync();
    });

    testWidgets('saves video note to gallery when Save is tapped', (
      tester,
    ) async {
      final calls = <String>[];
      mockGalChannel(calls: calls);
      VideoPlayerPlatform.instance = _FakeVideoPlayerPlatform(
        duration: const Duration(seconds: 15),
      );
      final path = createTmpMp4('video_note_save.mp4');
      when(
        () => getIt<StorageService>().cacheFile(
          uri: any(named: 'uri'),
          fileName: any(named: 'fileName'),
        ),
      ).thenAnswer((_) async => path);

      await pumpDialog(tester, makeItem());
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Save'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(calls.where((c) => c == 'putVideo').length, 1);
      expect(find.byType(VideoNotePreviewDialog), findsNothing);

      File(path).deleteSync();
    });

    testWidgets('can seek by dragging around the circular timeline', (
      tester,
    ) async {
      final fakePlatform = _FakeVideoPlayerPlatform(
        duration: const Duration(seconds: 60),
      );
      VideoPlayerPlatform.instance = fakePlatform;
      final path = createTmpMp4('video_note_seek.mp4');
      when(
        () => getIt<StorageService>().cacheFile(
          uri: any(named: 'uri'),
          fileName: any(named: 'fileName'),
        ),
      ).thenAnswer((_) async => path);

      await pumpDialog(tester, makeItem());
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      final customPaintFinder = find.byWidgetPredicate(
        (widget) => widget is CustomPaint && widget.size.width > 0,
      );
      expect(customPaintFinder, findsOneWidget);

      final center = tester.getCenter(customPaintFinder.first);
      // Drag along perimeter: from top (12 o'clock) to right (3 o'clock)
      await tester.dragFrom(
        Offset(center.dx, center.dy - 100),
        const Offset(100, 100),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(fakePlatform.seekCalls.isNotEmpty, isTrue);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      File(path).deleteSync();
    });

    testWidgets('taps inside video circle to pause and resume', (tester) async {
      final fakePlatform = _FakeVideoPlayerPlatform(
        duration: const Duration(seconds: 40),
      );
      VideoPlayerPlatform.instance = fakePlatform;
      final path = createTmpMp4('video_note_tap_video.mp4');
      when(
        () => getIt<StorageService>().cacheFile(
          uri: any(named: 'uri'),
          fileName: any(named: 'fileName'),
        ),
      ).thenAnswer((_) async => path);

      await pumpDialog(tester, makeItem());
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      final customPaintFinder = find.byWidgetPredicate(
        (widget) => widget is CustomPaint && widget.size.width > 0,
      );
      final center = tester.getCenter(customPaintFinder.first);

      // Tap directly in the center of the video
      await tester.tapAt(center);
      await tester.pump(const Duration(milliseconds: 100));

      expect(fakePlatform.pauseCalls, greaterThanOrEqualTo(1));

      // Tap again to resume
      await tester.tapAt(center);
      await tester.pump(const Duration(milliseconds: 100));

      expect(fakePlatform.playCalls, greaterThanOrEqualTo(2));

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      File(path).deleteSync();
    });

    testWidgets('taps on outer perimeter of video to seek', (tester) async {
      final fakePlatform = _FakeVideoPlayerPlatform(
        duration: const Duration(seconds: 40),
      );
      VideoPlayerPlatform.instance = fakePlatform;
      final path = createTmpMp4('video_note_tap_perimeter.mp4');
      when(
        () => getIt<StorageService>().cacheFile(
          uri: any(named: 'uri'),
          fileName: any(named: 'fileName'),
        ),
      ).thenAnswer((_) async => path);

      await pumpDialog(tester, makeItem());
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      final customPaintFinder = find.byWidgetPredicate(
        (widget) => widget is CustomPaint && widget.size.width > 0,
      );
      final playerRect = tester.getRect(customPaintFinder.first);
      final radius = playerRect.width / 2;
      // Tap on the edge (perimeter) of the circle
      await tester.tapAt(
        Offset(playerRect.center.dx + radius - 2, playerRect.center.dy),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(fakePlatform.seekCalls.isNotEmpty, isTrue);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      File(path).deleteSync();
    });
  });
}

class _FakeVideoPlayerPlatform extends VideoPlayerPlatform {
  _FakeVideoPlayerPlatform({required this.duration});

  final Duration duration;
  final Size videoSize = const Size(720, 720);
  final int rotationCorrection = 0;
  final Map<int, StreamController<VideoEvent>> _eventControllers = {};
  final Map<int, Duration> _positions = {};
  var _nextTextureId = 1;
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
    _eventControllers[playerId]?.add(
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
    _eventControllers[playerId]?.add(
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
}
