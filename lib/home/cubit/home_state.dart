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
    this.selectedIndex = 0,
    this.audiosStatus = HomeStatus.initial,
    this.statesStatus = HomeStatus.initial,
    this.saf,
    this.hasPermission = false,
    this.savedDirectoryUri = '',
    this.audios = const <AudioMetadata>[],
    this.audioWeeksFilter = 1,
    this.states = const <StateMetadata>[],
  });

  final int selectedIndex;
  final HomeStatus audiosStatus;
  final HomeStatus statesStatus;
  final Saf? saf;
  final bool hasPermission;
  final String savedDirectoryUri;
  final List<AudioMetadata> audios;
  final int audioWeeksFilter;
  final List<StateMetadata> states;

  HomeState copyWith({
    int? selectedIndex,
    HomeStatus? audiosStatus,
    HomeStatus? statesStatus,
    Saf? saf,
    bool? hasPermission,
    String? savedDirectoryUri,
    List<AudioMetadata>? audios,
    int? audioWeeksFilter,
    List<StateMetadata>? states,
  }) {
    return HomeState(
      selectedIndex: selectedIndex ?? this.selectedIndex,
      audiosStatus: audiosStatus ?? this.audiosStatus,
      statesStatus: statesStatus ?? this.statesStatus,
      saf: saf ?? this.saf,
      hasPermission: hasPermission ?? this.hasPermission,
      savedDirectoryUri: savedDirectoryUri ?? this.savedDirectoryUri,
      audios: audios ?? this.audios,
      audioWeeksFilter: audioWeeksFilter ?? this.audioWeeksFilter,
      states: states ?? this.states,
    );
  }

  @override
  List<Object?> get props => [
    selectedIndex,
    audiosStatus,
    statesStatus,
    saf,
    hasPermission,
    savedDirectoryUri,
    audios,
    audioWeeksFilter,
    states,
  ];
}
