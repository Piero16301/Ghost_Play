import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ghost_play/app/app.dart';

class AppBlocObserver extends BlocObserver {
  const AppBlocObserver();

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    log('onChange(${bloc.runtimeType}, $change)');
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    log('onError(${bloc.runtimeType}, $error, $stackTrace)');
    try {
      getIt<CrashService>().recordError(
        error,
        stackTrace,
        reason: 'Bloc error in ${bloc.runtimeType}',
      );
    } on Exception catch (_) {}
    super.onError(bloc, error, stackTrace);
  }
}

Future<void> bootstrap(FutureOr<Widget> Function() builder) async {
  FlutterError.onError = (details) {
    log(details.exceptionAsString(), stackTrace: details.stack);
    try {
      getIt<CrashService>().recordError(
        details.exception,
        details.stack,
        reason: details.context?.toString() ?? 'Flutter uncaught error',
        fatal: true,
      );
    } on Exception catch (_) {}
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    log(error.toString(), stackTrace: stack);
    try {
      getIt<CrashService>().recordError(
        error,
        stack,
        reason: 'PlatformDispatcher uncaught error',
        fatal: true,
      );
    } on Exception catch (_) {}
    return true;
  };

  Bloc.observer = const AppBlocObserver();

  runApp(await builder());
}
