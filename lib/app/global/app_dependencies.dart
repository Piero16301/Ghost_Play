import 'package:get_it/get_it.dart';
import 'package:ghost_play/app/app.dart';

final GetIt getIt = GetIt.instance;

void setupServiceLocator(Environment env) {
  getIt
    // 1. Infraestructura y Telemetría (Base de todo)
    ..registerLazySingleton<CrashService>(
      () =>
          CrashService(crashRepository: ServiceFactory.getCrashRepository(env)),
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
    )
    // 2. Configuración y Almacenamiento Local
    ..registerLazySingleton<LocalStorageService>(
      () => LocalStorageService(
        localStorageRepository: ServiceFactory.getLocalStorageRepository(env),
      ),
    )
    ..registerLazySingleton<RemoteConfigService>(
      () => RemoteConfigService(
        remoteConfigRepository: ServiceFactory.getRemoteConfigRepository(env),
      ),
    )
    ..registerLazySingleton<StorageService>(
      () => StorageService(
        storageRepository: ServiceFactory.getStorageRepository(env),
      ),
    )
    // 3. Servicios de Lógica de Negocio / IA
    ..registerLazySingleton<AiService>(
      () => AiService(aiRepository: ServiceFactory.getAiRepository(env)),
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

  static LocalStorageRepository getLocalStorageRepository(Environment env) {
    switch (env) {
      case Environment.mock:
        return MockLocalStorageRepository();
      case Environment.prod:
        return SharedPrefsLocalStorageRepository();
    }
  }

  static RemoteConfigRepository getRemoteConfigRepository(Environment env) {
    switch (env) {
      case Environment.mock:
        return MockRemoteConfigRepository();
      case Environment.prod:
        return FirebaseRemoteConfigRepository();
    }
  }

  static StorageRepository getStorageRepository(Environment env) {
    switch (env) {
      case Environment.mock:
        return MockStorageRepository();
      case Environment.prod:
        return MethodChannelStorageRepository();
    }
  }

  static AiRepository getAiRepository(Environment env) {
    switch (env) {
      case Environment.mock:
        return MockAiRepository();
      case Environment.prod:
        return FirebaseAiRepository();
    }
  }
}
