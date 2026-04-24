part of 'states_home_cubit.dart';

enum StatesHomeStatus {
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

class StatesHomeState extends Equatable {
  const StatesHomeState({
    this.status = StatesHomeStatus.initial,
  });

  final StatesHomeStatus status;

  StatesHomeState copyWith({
    StatesHomeStatus? status,
  }) {
    return StatesHomeState(
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [status];
}
