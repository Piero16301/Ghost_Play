part of 'audios_home_cubit.dart';

enum AudiosHomeStatus {
  initial,
  loading,
  playing,
  paused,
  completed,
  error
  ;

  bool get isInitial => this == initial;
  bool get isLoading => this == loading;
  bool get isPlaying => this == playing;
  bool get isPaused => this == paused;
  bool get isCompleted => this == completed;
  bool get isError => this == error;
}

class AudiosHomeState extends Equatable {
  const AudiosHomeState({
    this.status = AudiosHomeStatus.initial,
    this.isVisible = false,
    this.currentAudio,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.errorMessage,
    this.playbackSpeed = 1.0,
  });

  final AudiosHomeStatus status;
  final bool isVisible;
  final AudioMetadata? currentAudio;
  final Duration position;
  final Duration duration;
  final String? errorMessage;
  final double playbackSpeed;

  AudiosHomeState copyWith({
    AudiosHomeStatus? status,
    bool? isVisible,
    AudioMetadata? currentAudio,
    Duration? position,
    Duration? duration,
    String? errorMessage,
    double? playbackSpeed,
  }) {
    return AudiosHomeState(
      status: status ?? this.status,
      isVisible: isVisible ?? this.isVisible,
      currentAudio: currentAudio ?? this.currentAudio,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      errorMessage: errorMessage ?? this.errorMessage,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
    );
  }

  @override
  List<Object?> get props => [
    status,
    isVisible,
    currentAudio,
    position,
    duration,
    errorMessage,
    playbackSpeed,
  ];
}
