import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:ghost_play/app/app.dart';
import 'package:just_audio/just_audio.dart' as ja;

part 'audios_home_state.dart';

class AudiosHomeCubit extends Cubit<AudiosHomeState> {
  new({ja.AudioPlayer? audioPlayer, this._aiService})
    : _audioPlayer = audioPlayer ?? ja.AudioPlayer(),
      super(const AudiosHomeState()) {
    _initSubscriptions();
  }

  final ja.AudioPlayer _audioPlayer;
  final AiService? _aiService;
  final AnalyticsService _analyticsService = getIt<AnalyticsService>();
  final CrashService _crashService = getIt<CrashService>();
  final PerformanceService _performanceService = getIt<PerformanceService>();
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<ja.PlayerState>? _playerStateSubscription;

  void _initSubscriptions() {
    _positionSubscription = _audioPlayer.positionStream.listen(
      (position) {
        if (!isClosed) {
          emit(state.copyWith(position: position));
        }
      },
      onError: (Object e, StackTrace stackTrace) => _crashService.recordError(
        e,
        stackTrace,
        reason: 'AudioPlayer positionStream error',
      ),
    );

    _durationSubscription = _audioPlayer.durationStream.listen(
      (duration) {
        if (!isClosed && duration != null) {
          emit(state.copyWith(duration: duration));
        }
      },
      onError: (Object e, StackTrace stackTrace) => _crashService.recordError(
        e,
        stackTrace,
        reason: 'AudioPlayer durationStream error',
      ),
    );

    _playerStateSubscription = _audioPlayer.playerStateStream.listen(
      (playerState) {
        if (!isClosed) {
          final processingState = playerState.processingState;
          final playing = playerState.playing;

          if (processingState == ja.ProcessingState.loading ||
              processingState == ja.ProcessingState.buffering) {
            emit(state.copyWith(status: AudiosHomeStatus.loading));
          } else if (processingState == ja.ProcessingState.ready) {
            if (playing) {
              emit(state.copyWith(status: AudiosHomeStatus.playing));
            } else {
              emit(state.copyWith(status: AudiosHomeStatus.paused));
            }
          } else if (processingState == ja.ProcessingState.completed) {
            emit(
              state.copyWith(
                status: AudiosHomeStatus.completed,
                position: Duration.zero,
              ),
            );
          } else if (processingState == ja.ProcessingState.idle) {}
        }
      },
      onError: (Object e, StackTrace stackTrace) => _crashService.recordError(
        e,
        stackTrace,
        reason: 'AudioPlayer playerStateStream error',
      ),
    );
  }

  Future<void> playAudio(AudioMetadata audio) async {
    if (state.currentAudio?.uri == audio.uri) return;

    final trace = _performanceService.startTrace(
      'audio_playback_start_latency',
    );
    try {
      _analyticsService.logEvent(name: 'play_audio');
      await _audioPlayer.stop();

      emit(
        state.copyWith(
          status: AudiosHomeStatus.loading,
          isVisible: true,
          currentAudio: audio,
          position: Duration.zero,
          duration: Duration.zero,
          playbackSpeed: 1,
          isTranscriptionVisible: false,
          isTranscribing: false,
          clearTranscription: true,
        ),
      );

      await _audioPlayer.setAudioSource(
        ja.AudioSource.uri(Uri.parse(audio.uri)),
      );

      await _audioPlayer.setSpeed(1);
      _crashService.log('Playing audio: ${audio.uri}');
      await _audioPlayer.play();
    } on Exception catch (e, stackTrace) {
      _crashService.recordError(
        e,
        stackTrace,
        reason: 'Error playing audio: ${audio.uri}',
      );
      emit(
        state.copyWith(
          status: AudiosHomeStatus.error,
          errorMessage: e.toString(),
        ),
      );
    } finally {
      _performanceService.stopTrace(trace);
    }
  }

  Future<void> pause() async {
    _analyticsService.logEvent(name: 'pause_audio');
    _crashService.log('Audio paused manually');
    await _audioPlayer.pause();
  }

  Future<void> resume() async {
    _analyticsService.logEvent(name: 'resume_audio');
    if (state.status == AudiosHomeStatus.completed) {
      await _audioPlayer.seek(Duration.zero);
    }
    await _audioPlayer.play();
  }

  Future<void> seek(Duration position) async {
    _analyticsService.logEvent(
      name: 'seek_audio',
      parameters: {'position_seconds': position.inSeconds},
    );
    _crashService.log('Seeking to ${position.inSeconds} seconds');
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

    _analyticsService.logEvent(
      name: 'change_speed',
      parameters: {'speed': nextSpeed},
    );
    await _audioPlayer.setSpeed(nextSpeed);
    emit(state.copyWith(playbackSpeed: nextSpeed));
  }

  Future<void> transcribeAudio({bool forceRefresh = false}) async {
    final audio = state.currentAudio;
    if (audio == null || state.isTranscribing) return;

    _analyticsService.logEvent(
      name: 'transcribe_audio',
      parameters: {'force_refresh': forceRefresh.toString()},
    );
    emit(
      state.copyWith(
        isTranscriptionVisible: true,
        isTranscribing: true,
        clearTranscription: true,
      ),
    );

    try {
      final aiService = _aiService ?? getIt<AiService>();
      final result = await aiService.extractAudioTranscription(
        audio: audio,
        forceRefresh: forceRefresh,
      );
      if (!isClosed && state.currentAudio?.uri == audio.uri) {
        emit(state.copyWith(isTranscribing: false, transcription: result));
      }
    } on Object catch (e, stackTrace) {
      _crashService.recordError(
        e,
        stackTrace,
        reason: 'Error transcribing audio: ${audio.uri}',
      );
      if (!isClosed && state.currentAudio?.uri == audio.uri) {
        emit(state.copyWith(isTranscribing: false, clearTranscription: true));
      }
    }
  }

  Future<void> closePlayer() async {
    _analyticsService.logEvent(name: 'close_player');
    await _audioPlayer.stop();
    emit(const AudiosHomeState());
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
