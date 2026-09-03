import 'package:flutter_bloc/flutter_bloc.dart';
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

  group('AudiosHomePage', () {
    testWidgets('renders AudiosHomeView and provides AudiosHomeCubit', (
      tester,
    ) async {
      final homeCubit = MockHomeCubit();
      when(() => homeCubit.state).thenReturn(const HomeState());

      await tester.pumpApp(
        const AudiosHomePage(),
        homeCubit: homeCubit,
        locale: const Locale('en'),
      );

      expect(find.byType(AudiosHomeView), findsOneWidget);

      final context = tester.element(find.byType(AudiosHomeView));
      expect(context.read<AudiosHomeCubit>(), isA<AudiosHomeCubit>());
    });
  });
}
