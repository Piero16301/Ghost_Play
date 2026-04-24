import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_play/app/app.dart';
import 'package:ghost_play/home/pages/audios_home/audios_home.dart';

void main() {
  group('AudiosHomeStatus', () {
    test('status getters work correctly', () {
      expect(AudiosHomeStatus.initial.isInitial, isTrue);
      expect(AudiosHomeStatus.loading.isLoading, isTrue);
      expect(AudiosHomeStatus.playing.isPlaying, isTrue);
      expect(AudiosHomeStatus.paused.isPaused, isTrue);
      expect(AudiosHomeStatus.completed.isCompleted, isTrue);
      expect(AudiosHomeStatus.error.isError, isTrue);

      expect(AudiosHomeStatus.initial.isLoading, isFalse);
    });
  });

  group('AudiosHomeState', () {
    test('supports value equality', () {
      expect(const AudiosHomeState(), const AudiosHomeState());
    });

    test('props are correct', () {
      final audio = AudioMetadata(
        uri: 'uri',
        name: 'name',
        date: DateTime(2024),
        sizeBytes: 100,
        durationMs: 1000,
      );
      final state = AudiosHomeState(
        status: AudiosHomeStatus.playing,
        isVisible: true,
        currentAudio: audio,
        position: const Duration(seconds: 1),
        duration: const Duration(seconds: 2),
        errorMessage: 'error',
        playbackSpeed: 1.5,
      );

      expect(state.props, [
        AudiosHomeStatus.playing,
        true,
        audio,
        const Duration(seconds: 1),
        const Duration(seconds: 2),
        'error',
        1.5,
      ]);
    });

    test('copyWith returns same object if no arguments are provided', () {
      expect(const AudiosHomeState().copyWith(), const AudiosHomeState());
    });

    test('copyWith returns object with updated values', () {
      final audio = AudioMetadata(
        uri: 'uri',
        name: 'name',
        date: DateTime(2024),
        sizeBytes: 100,
        durationMs: 1000,
      );
      expect(
        const AudiosHomeState().copyWith(
          status: AudiosHomeStatus.playing,
          isVisible: true,
          currentAudio: audio,
          position: const Duration(seconds: 1),
          duration: const Duration(seconds: 2),
          errorMessage: 'error',
          playbackSpeed: 1.5,
        ),
        AudiosHomeState(
          status: AudiosHomeStatus.playing,
          isVisible: true,
          currentAudio: audio,
          position: const Duration(seconds: 1),
          duration: const Duration(seconds: 2),
          errorMessage: 'error',
          playbackSpeed: 1.5,
        ),
      );
    });
  });
}
