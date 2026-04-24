import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_play/home/pages/states_home/states_home.dart';

void main() {
  group('StatesHomeStatus', () {
    test('status getters work correctly', () {
      expect(StatesHomeStatus.initial.isInitial, isTrue);
      expect(StatesHomeStatus.loading.isLoading, isTrue);
      expect(StatesHomeStatus.success.isSuccess, isTrue);
      expect(StatesHomeStatus.failure.isFailure, isTrue);

      expect(StatesHomeStatus.initial.isLoading, isFalse);
    });
  });

  group('StatesHomeState', () {
    test('supports value equality', () {
      expect(const StatesHomeState(), const StatesHomeState());
    });

    test('props are correct', () {
      expect(
        const StatesHomeState(status: StatesHomeStatus.loading).props,
        [StatesHomeStatus.loading],
      );
    });

    test('copyWith returns same object if no arguments are provided', () {
      expect(const StatesHomeState().copyWith(), const StatesHomeState());
    });

    test('copyWith returns object with updated values', () {
      expect(
        const StatesHomeState().copyWith(status: StatesHomeStatus.success),
        const StatesHomeState(status: StatesHomeStatus.success),
      );
    });
  });

  group('StatesHomeCubit', () {
    test('initial state is correct', () {
      expect(StatesHomeCubit().state, const StatesHomeState());
    });
  });
}
