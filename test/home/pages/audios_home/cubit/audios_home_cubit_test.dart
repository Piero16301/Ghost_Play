import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_play/app/app.dart';
import 'package:ghost_play/home/pages/audios_home/audios_home.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mocks.dart';

class MockAudioPlayer extends Mock implements ja.AudioPlayer;

class MockAiService extends Mock implements AiService;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AudiosHomeCubit audiosHomeCubit;
  late MockAudioPlayer audioPlayer;
  late MockAiService aiService;
  late MockAnalyticsService analyticsService;
  late MockCrashService crashService;
  late MockPerformanceService performanceService;

  late StreamController<Duration> positionStream;
  late StreamController<Duration?> durationStream;
  late StreamController<ja.PlayerState> playerStateStream;

  setUpAll(registerFallbackValues);

  setUp(() {
    audioPlayer = MockAudioPlayer();
    aiService = MockAiService();
    analyticsService = MockAnalyticsService();
    crashService = MockCrashService();
    performanceService = MockPerformanceService();

    positionStream = StreamController<Duration>.broadcast();
    durationStream = StreamController<Duration?>.broadcast();
    playerStateStream = StreamController<ja.PlayerState>.broadcast();

    when(() => audioPlayer.positionStream)
        .thenAnswer((_) => positionStream.stream);
    when(() => audioPlayer.durationStream)
        .thenAnswer((_) => durationStream.stream);
    when(() => audioPlayer.playerStateStream)
        .thenAnswer((_) => playerStateStream.stream);
    when(() => audioPlayer.dispose()).thenAnswer((_) async {});
    when(() => audioPlayer.stop()).thenAnswer((_) async {});
    when(() => audioPlayer.pause()).thenAnswer((_) async {});
    when(() => audioPlayer.play()).thenAnswer((_) async {});
    when(() => audioPlayer.setSpeed(any<double>())).thenAnswer((_) async {});
    when(() => audioPlayer.setAudioSource(any<ja.AudioSource>()))
        .thenAnswer((_) async => null);
    when(() => audioPlayer.seek(any<Duration>())).thenAnswer((_) async {});

    unawaited(getIt.reset());
    getIt
      ..registerSingleton<AnalyticsService>(analyticsService)
      ..registerSingleton<CrashService>(crashService)
      ..registerSingleton<PerformanceService>(performanceService);

    when(() => performanceService.startTrace(any<String>()))
        .thenReturn(MockTrace());
    when(
      () => analyticsService.logEvent(
        name: any<String>(named: 'name'),
        parameters: any<Map<String, Object>?>(named: 'parameters'),
      ),
    ).thenAnswer((_) async {});
    when(() => crashService.log(any<String>())).thenReturn(null);
    when(
      () => crashService.recordError(
        any<dynamic>(),
        any<StackTrace?>(),
        reason: any<dynamic>(named: 'reason'),
      ),
    ).thenReturn(null);

    audiosHomeCubit = AudiosHomeCubit(
      audioPlayer: audioPlayer,
      aiService: aiService,
    );
  });

  tearDown(() async {
    await positionStream.close();
    await durationStream.close();
    await playerStateStream.close();
    await audiosHomeCubit.close();
  });

  group('AudiosHomeCubit', () {
    test('can be instantiated without audioPlayer', () {
      expect(AudiosHomeCubit(), isNotNull);
    });

    test('emits updated position when positionStream emits', () async {
      const position = Duration(seconds: 5);
      final expectation = expectLater(
        audiosHomeCubit.stream,
        emitsThrough(
          isA<AudiosHomeState>().having(
            (s) => s.position,
            'position',
            position,
          ),
        ),
      );
      positionStream.add(position);
      await expectation;
    });

    test('emits updated duration when durationStream emits', () async {
      const duration = Duration(seconds: 10);
      final expectation = expectLater(
        audiosHomeCubit.stream,
        emitsThrough(
          isA<AudiosHomeState>().having(
            (s) => s.duration,
            'duration',
            duration,
          ),
        ),
      );
      durationStream.add(duration);
      await expectation;
    });

    test('emits status loading when playerState is loading', () async {
      final expectation = expectLater(
        audiosHomeCubit.stream,
        emitsThrough(
          isA<AudiosHomeState>().having(
            (s) => s.status,
            'status',
            AudiosHomeStatus.loading,
          ),
        ),
      );
      playerStateStream.add(ja.PlayerState(false, ja.ProcessingState.loading));
      await expectation;
    });

    test(
      'emits status playing when playerState is ready and playing',
      () async {
        final expectation = expectLater(
          audiosHomeCubit.stream,
          emitsThrough(
            isA<AudiosHomeState>().having(
              (s) => s.status,
              'status',
              AudiosHomeStatus.playing,
            ),
          ),
        );
        playerStateStream.add(ja.PlayerState(true, ja.ProcessingState.ready));
        await expectation;
      },
    );

    test(
      'emits status paused when playerState is ready and not playing',
      () async {
        final expectation = expectLater(
          audiosHomeCubit.stream,
          emitsThrough(
            isA<AudiosHomeState>().having(
              (s) => s.status,
              'status',
              AudiosHomeStatus.paused,
            ),
          ),
        );
        playerStateStream.add(ja.PlayerState(false, ja.ProcessingState.ready));
        await expectation;
      },
    );

    test('emits status completed when playerState is completed', () async {
      final expectation = expectLater(
        audiosHomeCubit.stream,
        emitsThrough(
          isA<AudiosHomeState>().having(
            (s) => s.status,
            'status',
            AudiosHomeStatus.completed,
          ),
        ),
      );
      playerStateStream.add(
        ja.PlayerState(false, ja.ProcessingState.completed),
      );
      await expectation;
    });

    blocTest<AudiosHomeCubit, AudiosHomeState>(
      'playAudio calls audioPlayer methods',
      build: () => audiosHomeCubit,
      act: (cubit) => cubit.playAudio(
        AudioMetadata(
          uri: 'uri',
          name: 'name',
          date: DateTime(2024),
          sizeBytes: 100,
          durationMs: 1000,
        ),
      ),
      verify: (_) {
        verify(() => audioPlayer.stop()).called(1);
        verify(() => audioPlayer.setAudioSource(any<ja.AudioSource>()))
            .called(1);
        verify(() => audioPlayer.play()).called(1);
        verify(() => analyticsService.logEvent(name: 'play_audio')).called(1);
      },
    );

    blocTest<AudiosHomeCubit, AudiosHomeState>(
      'playAudio emits error on exception',
      build: () => audiosHomeCubit,
      setUp: () {
        when(() => audioPlayer.setAudioSource(any<ja.AudioSource>()))
            .thenThrow(Exception('error'));
      },
      act: (cubit) async => await cubit.playAudio(
        AudioMetadata(
          uri: 'uri',
          name: 'name',
          date: DateTime(2024),
          sizeBytes: 100,
          durationMs: 1000,
        ),
      ),
      expect: () => [
        isA<AudiosHomeState>().having(
          (s) => s.status,
          'status',
          AudiosHomeStatus.loading,
        ),
        isA<AudiosHomeState>().having(
          (s) => s.status,
          'status',
          AudiosHomeStatus.error,
        ),
      ],
      verify: (_) {
        verify(
          () => crashService.recordError(
            any<dynamic>(),
            any<StackTrace?>(),
            reason: any<dynamic>(named: 'reason'),
          ),
        ).called(1);
      },
    );

    blocTest<AudiosHomeCubit, AudiosHomeState>(
      'pause calls audioPlayer.pause',
      build: () => audiosHomeCubit,
      act: (cubit) async => await cubit.pause(),
      verify: (_) {
        verify(() => audioPlayer.pause()).called(1);
        verify(() => analyticsService.logEvent(name: 'pause_audio')).called(1);
      },
    );

    blocTest<AudiosHomeCubit, AudiosHomeState>(
      'resume calls audioPlayer.play and seeks if completed',
      build: () => audiosHomeCubit,
      seed: () => const AudiosHomeState(status: AudiosHomeStatus.completed),
      act: (cubit) async => await cubit.resume(),
      verify: (_) {
        verify(() => audioPlayer.seek(Duration.zero)).called(1);
        verify(() => audioPlayer.play()).called(1);
        verify(() => analyticsService.logEvent(name: 'resume_audio')).called(1);
      },
    );

    blocTest<AudiosHomeCubit, AudiosHomeState>(
      'seek calls audioPlayer.seek',
      build: () => audiosHomeCubit,
      act: (cubit) async => await cubit.seek(const Duration(seconds: 2)),
      verify: (_) {
        verify(() => audioPlayer.seek(const Duration(seconds: 2))).called(1);
        verify(
          () => analyticsService.logEvent(
            name: 'seek_audio',
            parameters: any<Map<String, Object>?>(named: 'parameters'),
          ),
        ).called(1);
      },
    );

    blocTest<AudiosHomeCubit, AudiosHomeState>(
      'changeSpeed cycles playback speeds',
      build: () => audiosHomeCubit,
      act: (cubit) async {
        await cubit.changeSpeed();
        await cubit.changeSpeed();
        await cubit.changeSpeed();
      },
      expect: () => [
        isA<AudiosHomeState>().having((s) => s.playbackSpeed, 'speed', 1.5),
        isA<AudiosHomeState>().having((s) => s.playbackSpeed, 'speed', 2.0),
        isA<AudiosHomeState>().having((s) => s.playbackSpeed, 'speed', 1.0),
      ],
    );

    blocTest<AudiosHomeCubit, AudiosHomeState>(
      'closePlayer stops player and resets state',
      build: () => audiosHomeCubit,
      seed: () => const AudiosHomeState(
        isVisible: true,
        status: AudiosHomeStatus.playing,
      ),
      act: (cubit) async => await cubit.closePlayer(),
      expect: () => [const AudiosHomeState()],
      verify: (_) {
        verify(() => audioPlayer.stop()).called(1);
      },
    );

    test('ignores idle processing state', () async {
      playerStateStream.add(ja.PlayerState(false, ja.ProcessingState.idle));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(audiosHomeCubit.state.status, AudiosHomeStatus.initial);
    });

    blocTest<AudiosHomeCubit, AudiosHomeState>(
      'transcribeAudio does nothing when currentAudio is null',
      build: () => audiosHomeCubit,
      act: (cubit) async => await cubit.transcribeAudio(),
      expect: () => <AudiosHomeState>[],
      verify: (_) {
        verifyNever(
          () => aiService.extractAudioTranscription(
            audio: any<AudioMetadata>(named: 'audio'),
          ),
        );
      },
    );

    blocTest<AudiosHomeCubit, AudiosHomeState>(
      'transcribeAudio emits loading and transcription on success',
      build: () => audiosHomeCubit,
      seed: () => AudiosHomeState(
        isVisible: true,
        currentAudio: AudioMetadata(
          uri: 'uri',
          name: 'audio.opus',
          date: DateTime(2024),
          sizeBytes: 100,
          durationMs: 1000,
        ),
      ),
      setUp: () {
        when(
          () => aiService.extractAudioTranscription(
            audio: any<AudioMetadata>(named: 'audio'),
            forceRefresh: any<bool>(named: 'forceRefresh'),
          ),
        ).thenAnswer((_) async => 'Hola mundo');
      },
      act: (cubit) async => await cubit.transcribeAudio(),
      expect: () => [
        isA<AudiosHomeState>()
            .having((s) => s.isTranscriptionVisible, 'visible', isTrue)
            .having((s) => s.isTranscribing, 'transcribing', isTrue)
            .having((s) => s.transcription, 'transcription', isNull),
        isA<AudiosHomeState>()
            .having((s) => s.isTranscriptionVisible, 'visible', isTrue)
            .having((s) => s.isTranscribing, 'transcribing', isFalse)
            .having((s) => s.transcription, 'transcription', 'Hola mundo'),
      ],
      verify: (_) {
        verify(
          () => analyticsService.logEvent(
            name: 'transcribe_audio',
            parameters: {'force_refresh': 'false'},
          ),
        ).called(1);
        verify(
          () => aiService.extractAudioTranscription(
            audio: any<AudioMetadata>(named: 'audio'),
          ),
        ).called(1);
      },
    );

    blocTest<AudiosHomeCubit, AudiosHomeState>(
      'transcribeAudio passes forceRefresh true when regenerating',
      build: () => audiosHomeCubit,
      seed: () => AudiosHomeState(
        isVisible: true,
        currentAudio: AudioMetadata(
          uri: 'uri',
          name: 'audio.opus',
          date: DateTime(2024),
          sizeBytes: 100,
          durationMs: 1000,
        ),
      ),
      setUp: () {
        when(
          () => aiService.extractAudioTranscription(
            audio: any<AudioMetadata>(named: 'audio'),
            forceRefresh: true,
          ),
        ).thenAnswer((_) async => 'Nuevo texto');
      },
      act: (cubit) async => await cubit.transcribeAudio(forceRefresh: true),
      expect: () => [
        isA<AudiosHomeState>().having(
          (s) => s.isTranscribing,
          'transcribing',
          isTrue,
        ),
        isA<AudiosHomeState>()
            .having((s) => s.isTranscribing, 'transcribing', isFalse)
            .having((s) => s.transcription, 'transcription', 'Nuevo texto'),
      ],
      verify: (_) {
        verify(
          () => analyticsService.logEvent(
            name: 'transcribe_audio',
            parameters: {'force_refresh': 'true'},
          ),
        ).called(1);
        verify(
          () => aiService.extractAudioTranscription(
            audio: any<AudioMetadata>(named: 'audio'),
            forceRefresh: true,
          ),
        ).called(1);
      },
    );

    blocTest<AudiosHomeCubit, AudiosHomeState>(
      'transcribeAudio clears transcription and records error on failure',
      build: () => audiosHomeCubit,
      seed: () => AudiosHomeState(
        isVisible: true,
        currentAudio: AudioMetadata(
          uri: 'uri',
          name: 'audio.opus',
          date: DateTime(2024),
          sizeBytes: 100,
          durationMs: 1000,
        ),
      ),
      setUp: () {
        when(
          () => aiService.extractAudioTranscription(
            audio: any<AudioMetadata>(named: 'audio'),
            forceRefresh: any<bool>(named: 'forceRefresh'),
          ),
        ).thenThrow(Exception('AI failure'));
      },
      act: (cubit) async => await cubit.transcribeAudio(),
      expect: () => [
        isA<AudiosHomeState>()
            .having((s) => s.isTranscriptionVisible, 'visible', isTrue)
            .having((s) => s.isTranscribing, 'transcribing', isTrue)
            .having((s) => s.transcription, 'transcription', isNull),
        isA<AudiosHomeState>()
            .having((s) => s.isTranscriptionVisible, 'visible', isTrue)
            .having((s) => s.isTranscribing, 'transcribing', isFalse)
            .having((s) => s.transcription, 'transcription', isNull),
      ],
      verify: (_) {
        verify(
          () => crashService.recordError(
            any<dynamic>(),
            any<StackTrace?>(),
            reason: any<dynamic>(named: 'reason'),
          ),
        ).called(1);
      },
    );

    test('records errors emitted on audio player streams', () async {
      positionStream.addError(Exception('position error'));
      durationStream.addError(Exception('duration error'));
      playerStateStream.addError(Exception('player state error'));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      verify(
        () => crashService.recordError(
          any<dynamic>(),
          any<StackTrace?>(),
          reason: 'AudioPlayer positionStream error',
        ),
      ).called(1);
      verify(
        () => crashService.recordError(
          any<dynamic>(),
          any<StackTrace?>(),
          reason: 'AudioPlayer durationStream error',
        ),
      ).called(1);
      verify(
        () => crashService.recordError(
          any<dynamic>(),
          any<StackTrace?>(),
          reason: 'AudioPlayer playerStateStream error',
        ),
      ).called(1);
    });
  });
}
