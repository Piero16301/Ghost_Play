part of 'player_cubit.dart';

enum PlayerStatus { initial, loading, playing, paused, completed, error }

class PlayerState extends Equatable {
  const PlayerState({
    this.status = PlayerStatus.initial,
    this.isVisible = false,
    this.currentAudio,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.errorMessage,
    this.playbackSpeed = 1.0,
  });

  final PlayerStatus status;
  final bool isVisible;
  final AudioMetadata? currentAudio;
  final Duration position;
  final Duration duration;
  final String? errorMessage;
  final double playbackSpeed;

  PlayerState copyWith({
    PlayerStatus? status,
    bool? isVisible,
    AudioMetadata? currentAudio,
    Duration? position,
    Duration? duration,
    String? errorMessage,
    double? playbackSpeed,
  }) {
    return PlayerState(
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
