import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:ghost_play/app/app.dart';
import 'package:just_audio/just_audio.dart' as ja;

part 'player_state.dart';

class PlayerCubit extends Cubit<PlayerState> {
  PlayerCubit() : super(const PlayerState()) {
    _initSubscriptions();
  }

  final ja.AudioPlayer _audioPlayer = ja.AudioPlayer();
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<ja.PlayerState>? _playerStateSubscription;

  void _initSubscriptions() {
    _positionSubscription = _audioPlayer.positionStream.listen((position) {
      if (!isClosed) {
        emit(state.copyWith(position: position));
      }
    });

    _durationSubscription = _audioPlayer.durationStream.listen((duration) {
      if (!isClosed && duration != null) {
        emit(state.copyWith(duration: duration));
      }
    });

    _playerStateSubscription = _audioPlayer.playerStateStream.listen((
      playerState,
    ) {
      if (!isClosed) {
        final processingState = playerState.processingState;
        final playing = playerState.playing;

        if (processingState == ja.ProcessingState.loading ||
            processingState == ja.ProcessingState.buffering) {
          emit(state.copyWith(status: PlayerStatus.loading));
        } else if (processingState == ja.ProcessingState.ready) {
          if (playing) {
            emit(state.copyWith(status: PlayerStatus.playing));
          } else {
            emit(state.copyWith(status: PlayerStatus.paused));
          }
        } else if (processingState == ja.ProcessingState.completed) {
          emit(
            state.copyWith(
              status: PlayerStatus.completed,
              position: Duration.zero,
            ),
          );
        } else if (processingState == ja.ProcessingState.idle) {}
      }
    });
  }

  Future<void> playAudio(AudioMetadata audio) async {
    if (state.currentAudio?.uri == audio.uri) return;

    try {
      await _audioPlayer.stop();

      emit(
        state.copyWith(
          status: PlayerStatus.loading,
          isVisible: true,
          currentAudio: audio,
          position: Duration.zero,
          duration: Duration.zero,
          playbackSpeed: 1,
        ),
      );

      await _audioPlayer.setAudioSource(
        ja.AudioSource.uri(Uri.parse(audio.uri)),
      );

      await _audioPlayer.setSpeed(1);
      await _audioPlayer.play();
    } on Exception catch (e) {
      emit(
        state.copyWith(
          status: PlayerStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> resume() async {
    if (state.status == PlayerStatus.completed) {
      await _audioPlayer.seek(Duration.zero);
    }
    await _audioPlayer.play();
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  Future<void> changeSpeed() async {
    var nextSpeed = 1.0;
    if (state.playbackSpeed == 1.0) {
      nextSpeed = 1.5;
    } else if (state.playbackSpeed == 1.5) {
      nextSpeed = 2.0;
    } else {
      nextSpeed = 1.0;
    }

    await _audioPlayer.setSpeed(nextSpeed);
    emit(state.copyWith(playbackSpeed: nextSpeed));
  }

  Future<void> closePlayer() async {
    await _audioPlayer.stop();
    emit(const PlayerState());
  }

  @override
  Future<void> close() {
    unawaited(_positionSubscription?.cancel());
    unawaited(_durationSubscription?.cancel());
    unawaited(_playerStateSubscription?.cancel());
    unawaited(_audioPlayer.dispose());
    return super.close();
  }
}
