import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_play/home/home.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mocks.dart';
import '../../../../helpers/pump_app.dart';
import '../../../../helpers/service_locator.dart';

void main() {
  setUpAll(registerFallbackValues);

  setUp(setupServiceLocatorMocks);

  group('StatesHomePage', () {
    testWidgets('renders StatesHomeView and provides StatesHomeCubit', (
      tester,
    ) async {
      final homeCubit = MockHomeCubit();
      when(() => homeCubit.state).thenReturn(const HomeState());

      await tester.pumpApp(
        const StatesHomePage(),
        homeCubit: homeCubit,
        locale: const Locale('en'),
      );

      expect(find.byType(StatesHomeView), findsOneWidget);
    });
  });
}
