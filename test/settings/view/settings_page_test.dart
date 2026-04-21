import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_play/app/app.dart';
import 'package:ghost_play/settings/settings.dart';
import 'package:mocktail/mocktail.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../helpers/mocks.dart';
import '../../helpers/pump_app.dart';

void main() {
  late MockAppCubit appCubit;

  setUpAll(() {
    registerFallbackValues();
    PackageInfo.setMockInitialValues(
      appName: 'Ghost Play',
      packageName: 'com.ghost.play',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  setUp(() {
    appCubit = MockAppCubit();
    when(() => appCubit.state).thenReturn(const AppState());
  });

  group('SettingsPage', () {
    testWidgets('renders SettingsView', (tester) async {
      await tester.pumpApp(const SettingsPage(), appCubit: appCubit);
      await tester.pumpAndSettle();
      expect(find.byType(SettingsView), findsOneWidget);
    });
  });
}
