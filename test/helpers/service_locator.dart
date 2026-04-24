import 'dart:async';

import 'package:ghost_play/app/app.dart';
import 'mocks.dart';

Future<void> setupServiceLocatorMocks() async {
  await getIt.reset();

  final analyticsService = MockAnalyticsService();
  final crashService = MockCrashService();
  final performanceService = MockPerformanceService();
  final storageService = MockStorageService();

  getIt
    ..registerSingleton<AnalyticsService>(analyticsService)
    ..registerSingleton<CrashService>(crashService)
    ..registerSingleton<PerformanceService>(performanceService)
    ..registerSingleton<StorageService>(storageService);
}
