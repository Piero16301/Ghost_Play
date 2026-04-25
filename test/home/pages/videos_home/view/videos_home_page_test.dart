import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_play/home/home.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mocks.dart';
import '../../../../helpers/pump_app.dart';
import '../../../../helpers/service_locator.dart';

void main() {
  late HomeCubit homeCubit;

  setUpAll(registerFallbackValues);

  setUp(() async {
    await setupServiceLocatorMocks();
    homeCubit = MockHomeCubit();
    when(() => homeCubit.state).thenReturn(const HomeState());
  });

  testWidgets('renders VideosHomeView', (tester) async {
    await tester.pumpApp(
      const VideosHomePage(),
      homeCubit: homeCubit,
    );
    expect(find.byType(VideosHomeView), findsOneWidget);
  });
}
