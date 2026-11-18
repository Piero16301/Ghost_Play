part of 'audios_home_cubit.dart';

enum AudiosHomeStatus {
  initial,
  loading,
  playing,
  paused,
  completed,
  error;

  bool get isInitial => this == initial;
  bool get isLoading => this == loading;
  bool get isPlaying => this == playing;
  bool get isPaused => this == paused;
  bool get isCompleted => this == completed;
  bool get isError => this == error;
}

class AudiosHomeState extends Equatable {
  const new({
    this.status = AudiosHomeStatus.initial,
    this.isVisible = false,
    this.currentAudio,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.errorMessage,
    this.playbackSpeed = 1.0,
    this.isTranscriptionVisible = false,
    this.isTranscribing = false,
    this.transcription,
  });

  final AudiosHomeStatus status;
  final bool isVisible;
  final AudioMetadata? currentAudio;
  final Duration position;
  final Duration duration;
  final String? errorMessage;
  final double playbackSpeed;
  final bool isTranscriptionVisible;
  final bool isTranscribing;
  final String? transcription;

  AudiosHomeState copyWith({
    AudiosHomeStatus? status,
    bool? isVisible,
    AudioMetadata? currentAudio,
    Duration? position,
    Duration? duration,
    String? errorMessage,
    double? playbackSpeed,
    bool? isTranscriptionVisible,
    bool? isTranscribing,
    String? transcription,
    bool clearTranscription = false,
  }) {
    return AudiosHomeState(
      status: status ?? this.status,
      isVisible: isVisible ?? this.isVisible,
      currentAudio: currentAudio ?? this.currentAudio,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      errorMessage: errorMessage ?? this.errorMessage,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      isTranscriptionVisible:
          isTranscriptionVisible ?? this.isTranscriptionVisible,
      isTranscribing: isTranscribing ?? this.isTranscribing,
      transcription: clearTranscription
          ? null
          : (transcription ?? this.transcription),
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
    isTranscriptionVisible,
    isTranscribing,
    transcription,
  ];
}
