import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_play/app/app.dart';
import 'package:mocktail/mocktail.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../helpers/mocks.dart';

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
    when(
      () => appCubit.changeLanguage(language: any(named: 'language')),
    ).thenAnswer((_) async {});
    when(
      () => appCubit.changeTheme(theme: any(named: 'theme')),
    ).thenAnswer((_) async {});
    when(
      () => appCubit.changeBaseColor(baseColor: any(named: 'baseColor')),
    ).thenAnswer((_) async {});
    when(
      () => appCubit.changeFontFamily(fontFamily: any(named: 'fontFamily')),
    ).thenAnswer((_) async {});
  });
}
