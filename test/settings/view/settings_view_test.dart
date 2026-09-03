import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_play/app/app.dart';
import 'package:ghost_play/settings/settings.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
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

  group('SettingsView', () {
    testWidgets('renders all settings cards', (tester) async {
      await tester.pumpApp(const SettingsView(), appCubit: appCubit);
      await tester.pumpAndSettle();

      expect(find.byType(LocaleSettingsCard), findsOneWidget);
      expect(find.byType(ThemeSettingsCard), findsOneWidget);
      expect(find.byType(ColorSettingsCard), findsOneWidget);
      expect(find.byType(FontSettingsCard), findsOneWidget);
      expect(find.byType(SettingsAppSpecs), findsOneWidget);
    });

    testWidgets('calls changeLanguage when a new language is selected', (
      tester,
    ) async {
      await tester.pumpApp(const SettingsView(), appCubit: appCubit);
      await tester.pumpAndSettle();

      final dropdown = find.byType(DropdownButton<Locale>);
      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Spanish').last);
      await tester.pumpAndSettle();

      verify(
        () => appCubit.changeLanguage(language: const Locale('es', 'ES')),
      ).called(1);
    });

    testWidgets('onChanged for language does nothing if value is null', (
      tester,
    ) async {
      await tester.pumpApp(const SettingsView(), appCubit: appCubit);
      await tester.pumpAndSettle();

      final dropdown = tester.widget<DropdownButton<Locale>>(
        find.byType(DropdownButton<Locale>),
      );
      dropdown.onChanged!(null);

      verifyNever(
        () => appCubit.changeLanguage(language: any(named: 'language')),
      );
    });

    testWidgets('calls changeTheme when a new theme is selected', (
      tester,
    ) async {
      await tester.pumpApp(const SettingsView(), appCubit: appCubit);
      await tester.pumpAndSettle();

      final dropdown = find.byType(DropdownButton<ThemeMode>);
      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Dark').last);
      await tester.pumpAndSettle();

      verify(() => appCubit.changeTheme(theme: ThemeMode.dark)).called(1);
    });

    testWidgets('onChanged for theme does nothing if value is null', (
      tester,
    ) async {
      await tester.pumpApp(const SettingsView(), appCubit: appCubit);
      await tester.pumpAndSettle();

      final dropdown = tester.widget<DropdownButton<ThemeMode>>(
        find.byType(DropdownButton<ThemeMode>),
      );
      dropdown.onChanged!(null);

      verifyNever(() => appCubit.changeTheme(theme: any(named: 'theme')));
    });

    testWidgets('calls changeBaseColor when a new color is selected', (
      tester,
    ) async {
      await tester.pumpApp(const SettingsView(), appCubit: appCubit);
      await tester.pumpAndSettle();

      final dropdown = find.byType(DropdownButton<Color>);
      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Blue').last);
      await tester.pumpAndSettle();

      verify(() => appCubit.changeBaseColor(baseColor: Colors.blue)).called(1);
    });

    testWidgets('onChanged for color does nothing if value is null', (
      tester,
    ) async {
      await tester.pumpApp(const SettingsView(), appCubit: appCubit);
      await tester.pumpAndSettle();

      final dropdown = tester.widget<DropdownButton<Color>>(
        find.byType(DropdownButton<Color>),
      );
      dropdown.onChanged!(null);

      verifyNever(
        () => appCubit.changeBaseColor(baseColor: any(named: 'baseColor')),
      );
    });

    testWidgets('calls changeFontFamily when a new font is selected', (
      tester,
    ) async {
      await tester.pumpApp(const SettingsView(), appCubit: appCubit);
      await tester.pumpAndSettle();

      final dropdown = find.byType(DropdownButton<String>);
      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Roboto').last);
      await tester.pumpAndSettle();

      verify(() => appCubit.changeFontFamily(fontFamily: 'Roboto')).called(1);
    });

    testWidgets('onChanged for font does nothing if value is null', (
      tester,
    ) async {
      await tester.pumpApp(const SettingsView(), appCubit: appCubit);
      await tester.pumpAndSettle();

      final dropdown = tester.widget<DropdownButton<String>>(
        find.byType(DropdownButton<String>),
      );
      dropdown.onChanged!(null);

      verifyNever(
        () => appCubit.changeFontFamily(fontFamily: any(named: 'fontFamily')),
      );
    });

    testWidgets('font fallback logic works when state has unknown font', (
      tester,
    ) async {
      when(
        () => appCubit.state,
      ).thenReturn(const AppState(fontFamily: 'UnknownFont'));

      await tester.pumpApp(const SettingsView(), appCubit: appCubit);
      await tester.pumpAndSettle();

      expect(find.byType(FontSettingsCard), findsOneWidget);
    });

    testWidgets('pops when back button is pressed', (tester) async {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: Text('Home')),
          ),
          GoRoute(path: '/settings', builder: (_, _) => const SettingsView()),
        ],
      );

      await tester.pumpApp(
        const SizedBox(),
        appCubit: appCubit,
        router: router,
      );
      await tester.pumpAndSettle();

      unawaited(router.push('/settings'));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsView), findsOneWidget);

      await tester.tap(find.byType(IconButton).first);
      await tester.pumpAndSettle();

      expect(find.byType(SettingsView), findsNothing);
      expect(find.text('Home'), findsOneWidget);
    });
  });
}
