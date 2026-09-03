import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_play/app/app.dart';
import 'package:ghost_play/home/home.dart';
import 'package:ghost_play/l10n/l10n.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

extension PumpApp on WidgetTester {
  Future<void> pumpApp(
    Widget widget, {
    AppCubit? appCubit,
    HomeCubit? homeCubit,
    AudiosHomeCubit? audiosHomeCubit,
    GoRouter? router,
    Locale? locale,
  }) {
    return pumpWidget(
      MultiBlocProvider(
        providers: [
          if (appCubit != null)
            BlocProvider.value(value: appCubit)
          else
            BlocProvider(create: (_) => AppCubit()),
          if (homeCubit != null) BlocProvider.value(value: homeCubit),
          if (audiosHomeCubit != null)
            BlocProvider.value(value: audiosHomeCubit),
        ],
        child: router != null
            ? MaterialApp.router(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                routerConfig: router,
                locale: locale,
              )
            : MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                locale: locale,
                home: Scaffold(body: widget),
              ),
      ),
    );
  }
}
