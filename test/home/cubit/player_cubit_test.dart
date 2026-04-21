import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_play/app/app.dart';
import 'package:ghost_play/home/home.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';

void main() {
  group('PlayerCubit', () {
    late ja.AudioPlayer audioPlayer;
    late PlayerCubit playerCubit;

    late StreamController<Duration> positionController;
    late StreamController<Duration?> durationController;
    late StreamController<ja.PlayerState> playerStateController;

    late MockAnalyticsService analyticsService;
    late MockCrashService crashService;
    late MockPerformanceService performanceService;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      registerFallbackValues();
    });

    setUp(() async {
      audioPlayer = MockAudioPlayer();

      analyticsService = MockAnalyticsService();
      crashService = MockCrashService();
      performanceService = MockPerformanceService();

      await getIt.reset();
      getIt
        ..registerSingleton<AnalyticsService>(analyticsService)
        ..registerSingleton<CrashService>(crashService)
        ..registerSingleton<PerformanceService>(performanceService);

      when(() => crashService.setCustomKey(any(), any())).thenReturn(null);
      when(
        () => crashService.recordError(
          any<dynamic>(),
          any<StackTrace?>(),
          reason: any<dynamic>(named: 'reason'),
        ),
      ).thenReturn(null);
      when(() => performanceService.startTrace(any())).thenReturn(MockTrace());
      when(
        () => analyticsService.logEvent(
          name: any(named: 'name'),
          parameters: any(named: 'parameters'),
        ),
      ).thenAnswer((_) async {});

      positionController = StreamController<Duration>.broadcast();
      durationController = StreamController<Duration?>.broadcast();
      playerStateController = StreamController<ja.PlayerState>.broadcast();

      when(
        () => audioPlayer.positionStream,
      ).thenAnswer((_) => positionController.stream);
      when(
        () => audioPlayer.durationStream,
      ).thenAnswer((_) => durationController.stream);
      when(
        () => audioPlayer.playerStateStream,
      ).thenAnswer((_) => playerStateController.stream);

      when(() => audioPlayer.dispose()).thenAnswer((_) async {});
      when(() => audioPlayer.stop()).thenAnswer((_) async {});
      when(() => audioPlayer.pause()).thenAnswer((_) async {});
      when(() => audioPlayer.play()).thenAnswer((_) async {});
      when(() => audioPlayer.setSpeed(any())).thenAnswer((_) async {});
      when(() => audioPlayer.seek(any())).thenAnswer((_) async {});
      when(
        () => audioPlayer.setAudioSource(any()),
      ).thenAnswer((_) async => null);

      playerCubit = PlayerCubit(audioPlayer: audioPlayer);
    });

    tearDown(() {
      unawaited(positionController.close());
      unawaited(durationController.close());
      unawaited(playerStateController.close());
      unawaited(playerCubit.close());
    });

    test('initial state is PlayerState()', () {
      expect(playerCubit.state, const PlayerState());
    });

    group('subscriptions', () {
      blocTest<PlayerCubit, PlayerState>(
        'emits position when positionStream pushes',
        build: () => playerCubit,
        act: (_) => positionController.add(const Duration(seconds: 1)),
        expect: () => [
          const PlayerState(position: Duration(seconds: 1)),
        ],
      );

      blocTest<PlayerCubit, PlayerState>(
        'emits duration when durationStream pushes',
        build: () => playerCubit,
        act: (_) => durationController.add(const Duration(seconds: 10)),
        expect: () => [
          const PlayerState(duration: Duration(seconds: 10)),
        ],
      );

      blocTest<PlayerCubit, PlayerState>(
        'emits loading status when processingState is loading',
        build: () => playerCubit,
        act: (_) => playerStateController.add(
          ja.PlayerState(false, ja.ProcessingState.loading),
        ),
        expect: () => [
          const PlayerState(status: PlayerStatus.loading),
        ],
      );

      blocTest<PlayerCubit, PlayerState>(
        'emits playing status when processingState is ready and playing is '
        'true',
        build: () => playerCubit,
        act: (_) => playerStateController.add(
          ja.PlayerState(true, ja.ProcessingState.ready),
        ),
        expect: () => [
          const PlayerState(status: PlayerStatus.playing),
        ],
      );

      blocTest<PlayerCubit, PlayerState>(
        'emits paused status when processingState is ready and playing is '
        'false',
        build: () => playerCubit,
        act: (_) => playerStateController.add(
          ja.PlayerState(false, ja.ProcessingState.ready),
        ),
        expect: () => [
          const PlayerState(status: PlayerStatus.paused),
        ],
      );

      blocTest<PlayerCubit, PlayerState>(
        'emits completed status when processingState is completed',
        build: () => playerCubit,
        act: (_) => playerStateController.add(
          ja.PlayerState(false, ja.ProcessingState.completed),
        ),
        expect: () => [
          const PlayerState(
            status: PlayerStatus.completed,
          ),
        ],
      );

      blocTest<PlayerCubit, PlayerState>(
        'does nothing when processingState is idle',
        build: () => playerCubit,
        act: (_) => playerStateController.add(
          ja.PlayerState(false, ja.ProcessingState.idle),
        ),
        expect: () => <PlayerState>[],
      );
    });

    group('playAudio', () {
      final audio = AudioMetadata(
        uri: 'file://audio.mp3',
        name: 'test',
        date: DateTime(2023),
        sizeBytes: 100,
        durationMs: 1000,
      );

      blocTest<PlayerCubit, PlayerState>(
        'does nothing if same audio uri',
        seed: () => PlayerState(currentAudio: audio),
        build: () => playerCubit,
        act: (cubit) => cubit.playAudio(audio),
        expect: () => <PlayerState>[],
      );

      blocTest<PlayerCubit, PlayerState>(
        'plays new audio successfully',
        build: () => playerCubit,
        act: (cubit) => cubit.playAudio(audio),
        expect: () => [
          predicate<PlayerState>(
            (state) =>
                state.status == PlayerStatus.loading &&
                state.isVisible &&
                state.currentAudio == audio,
          ),
        ],
        verify: (_) {
          verify(() => audioPlayer.stop()).called(1);
          verify(() => audioPlayer.setAudioSource(any())).called(1);
          verify(() => audioPlayer.play()).called(1);
        },
      );

      blocTest<PlayerCubit, PlayerState>(
        'emits error when play fails',
        build: () {
          when(
            () => audioPlayer.setAudioSource(any()),
          ).thenThrow(Exception('fail'));
          return playerCubit;
        },
        act: (cubit) => cubit.playAudio(audio),
        expect: () => [
          predicate<PlayerState>(
            (state) => state.status == PlayerStatus.loading,
          ),
          predicate<PlayerState>(
            (state) =>
                state.status == PlayerStatus.error &&
                state.errorMessage?.contains('fail') == true,
          ),
        ],
      );
    });

    test('pause calls audioPlayer.pause', () async {
      await playerCubit.pause();
      verify(() => audioPlayer.pause()).called(1);
    });

    group('resume', () {
      test('seeks to zero if completed and plays', () async {
        playerCubit.emit(const PlayerState(status: PlayerStatus.completed));
        await playerCubit.resume();
        verify(() => audioPlayer.seek(Duration.zero)).called(1);
        verify(() => audioPlayer.play()).called(1);
      });

      test('just plays if not completed', () async {
        playerCubit.emit(const PlayerState(status: PlayerStatus.paused));
        await playerCubit.resume();
        verifyNever(() => audioPlayer.seek(any()));
        verify(() => audioPlayer.play()).called(1);
      });
    });

    test('seek calls audioPlayer.seek', () async {
      await playerCubit.seek(const Duration(seconds: 5));
      verify(() => audioPlayer.seek(const Duration(seconds: 5))).called(1);
    });

    group('changeSpeed', () {
      blocTest<PlayerCubit, PlayerState>(
        'changes speed 1.0 -> 1.5',
        seed: () => const PlayerState(),
        build: () => playerCubit,
        act: (cubit) => cubit.changeSpeed(),
        expect: () => [
          const PlayerState(playbackSpeed: 1.5),
        ],
        verify: (_) => verify(() => audioPlayer.setSpeed(1.5)).called(1),
      );

      blocTest<PlayerCubit, PlayerState>(
        'changes speed 1.5 -> 2.0',
        seed: () => const PlayerState(playbackSpeed: 1.5),
        build: () => playerCubit,
        act: (cubit) => cubit.changeSpeed(),
        expect: () => [
          const PlayerState(playbackSpeed: 2),
        ],
        verify: (_) => verify(() => audioPlayer.setSpeed(2)).called(1),
      );

      blocTest<PlayerCubit, PlayerState>(
        'changes speed 2.0 -> 1.0',
        seed: () => const PlayerState(playbackSpeed: 2),
        build: () => playerCubit,
        act: (cubit) => cubit.changeSpeed(),
        expect: () => [
          const PlayerState(),
        ],
        verify: (_) => verify(() => audioPlayer.setSpeed(1)).called(1),
      );
    });

    blocTest<PlayerCubit, PlayerState>(
      'closePlayer stops audio and resets state',
      seed: () => const PlayerState(status: PlayerStatus.playing),
      build: () => playerCubit,
      act: (cubit) => cubit.closePlayer(),
      expect: () => [
        const PlayerState(),
      ],
      verify: (_) => verify(() => audioPlayer.stop()).called(1),
    );

    test('default constructor uses ja.AudioPlayer', () {
      final cubit = PlayerCubit();
      expect(cubit, isA<PlayerCubit>());
      unawaited(cubit.close());
    });
  });
}
