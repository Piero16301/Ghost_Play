part of 'home_cubit.dart';

class HomeState extends Equatable {
  const HomeState({
    this.selectedIndex = 0,
  });

  final int selectedIndex;

  HomeState copyWith({
    int? selectedIndex,
  }) {
    return HomeState(
      selectedIndex: selectedIndex ?? this.selectedIndex,
    );
  }

  @override
  List<Object> get props => [
    selectedIndex,
  ];
}
