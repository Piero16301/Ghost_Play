import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:ghost_play/app/app.dart';
import 'package:ghost_play/bootstrap.dart';
import 'package:ghost_play/firebase_options.dart';
import 'package:material_ui/material_ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with the default options
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  const currentEnv = Environment.mock;

  // Setup service locator
  setupServiceLocator(currentEnv);

  const appCheckDebugToken = String.fromEnvironment('APP_CHECK_DEBUG_TOKEN');
  final debugToken = appCheckDebugToken.isEmpty ? null : appCheckDebugToken;

  // Initialize services and plugins in parallel
  final performance = getIt<PerformanceService>();
  final trace = performance.startTrace('app_initialization');
  await Future.wait([
    () async {
      try {
        await FirebaseAppCheck.instance
            .activate(
              providerAndroid: kDebugMode
                  ? AndroidDebugProvider(debugToken: debugToken)
                  : const AndroidPlayIntegrityProvider(),
              providerApple: kDebugMode
                  ? AppleDebugProvider(debugToken: debugToken)
                  : const AppleDeviceCheckProvider(),
            )
            .timeout(AppVariables.timeoutDuration);
      } on Object catch (e, stackTrace) {
        getIt<CrashService>().recordError(
          e,
          stackTrace,
          reason: 'FirebaseAppCheck activate error',
        );
      }
    }(),
    getIt<LocalStorageService>().initialize(),
    getIt<RemoteConfigService>().initialize(),
  ]);
  getIt<LocalStorageService>().clearOldTranscriptions(
    maxDays: getIt<RemoteConfigService>().maxDaysSavedTranscriptions,
  );
  performance.stopTrace(trace);

  // Bootstrap the app
  await bootstrap(() => const AppPage());
}
