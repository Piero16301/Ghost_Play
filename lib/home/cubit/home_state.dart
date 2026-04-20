part of 'home_cubit.dart';

enum HomeStatus {
  initial,
  loading,
  success,
  failure
  ;

  bool get isInitial => this == initial;
  bool get isLoading => this == loading;
  bool get isSuccess => this == success;
  bool get isFailure => this == failure;
}

class HomeState extends Equatable {
  const HomeState({
    this.status = HomeStatus.initial,
    this.saf,
    this.hasPermission = false,
    this.savedDirectoryUri = '',
    this.audios = const <AudioMetadata>[],
  });

  final HomeStatus status;
  final Saf? saf;
  final bool hasPermission;
  final String savedDirectoryUri;
  final List<AudioMetadata> audios;

  HomeState copyWith({
    HomeStatus? status,
    Saf? saf,
    bool? hasPermission,
    String? savedDirectoryUri,
    List<AudioMetadata>? audios,
  }) {
    return HomeState(
      status: status ?? this.status,
      saf: saf ?? this.saf,
      hasPermission: hasPermission ?? this.hasPermission,
      savedDirectoryUri: savedDirectoryUri ?? this.savedDirectoryUri,
      audios: audios ?? this.audios,
    );
  }

  @override
  List<Object?> get props => [
    status,
    saf,
    hasPermission,
    savedDirectoryUri,
    audios,
  ];
}
