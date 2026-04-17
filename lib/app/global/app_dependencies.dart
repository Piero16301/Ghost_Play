import 'package:get_it/get_it.dart';
import 'package:ghost_play/app/app.dart';

final GetIt getIt = GetIt.instance;

void setupServiceLocator(Environment env) {
  getIt
    // 1. Infraestructura y Telemetría (Base de todo)
    ..registerLazySingleton<CrashService>(
      () => CrashService(
        crashRepository: ServiceFactory.getCrashRepository(env),
      ),
    )
    ..registerLazySingleton<PerformanceService>(
      () => PerformanceService(
        performanceRepository: ServiceFactory.getPerformanceRepository(env),
      ),
    )
    ..registerLazySingleton<AnalyticsService>(
      () => AnalyticsService(
        analyticsRepository: ServiceFactory.getAnalyticsRepository(env),
      ),
    );
}

enum Environment { mock, prod }

class ServiceFactory {
  static CrashRepository getCrashRepository(Environment env) {
    switch (env) {
      case Environment.mock:
        return MockCrashRepository();
      case Environment.prod:
        return CrashlyticsCrashRepository();
    }
  }

  static PerformanceRepository getPerformanceRepository(Environment env) {
    switch (env) {
      case Environment.mock:
        return MockPerformanceRepository();
      case Environment.prod:
        return FirebasePerformanceRepository();
    }
  }

  static AnalyticsRepository getAnalyticsRepository(Environment env) {
    switch (env) {
      case Environment.mock:
        return MockAnalyticsRepository();
      case Environment.prod:
        return FirebaseAnalyticsRepository();
    }
  }
}
