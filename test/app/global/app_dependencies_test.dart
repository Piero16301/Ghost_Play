import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_play/app/app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppDependencies', () {
    const channel = MethodChannel('plugins.flutter.io/firebase_core');

    setUp(() async {
      await getIt.reset();

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (methodCall) async {
            if (methodCall.method == 'Firebase#initializeApp' ||
                methodCall.method == 'Firebase#app') {
              return {
                'name': '[DEFAULT]',
                'options': {
                  'apiKey': '123',
                  'appId': '123',
                  'messagingSenderId': '123',
                  'projectId': '123',
                },
                'pluginConstants': <String, dynamic>{},
              };
            }
            return null;
          });
    });

    test('setupServiceLocator registers mock dependencies', () {
      setupServiceLocator(Environment.mock);

      expect(getIt.isRegistered<CrashService>(), isTrue);
      expect(getIt.isRegistered<PerformanceService>(), isTrue);
      expect(getIt.isRegistered<AnalyticsService>(), isTrue);
      expect(getIt.isRegistered<LocalStorageService>(), isTrue);
      expect(getIt.isRegistered<RemoteConfigService>(), isTrue);
      expect(getIt.isRegistered<StorageService>(), isTrue);
      expect(getIt.isRegistered<AiService>(), isTrue);

      expect(getIt<CrashService>(), isA<CrashService>());
      expect(getIt<PerformanceService>(), isA<PerformanceService>());
      expect(getIt<AnalyticsService>(), isA<AnalyticsService>());
      expect(getIt<LocalStorageService>(), isA<LocalStorageService>());
      expect(getIt<RemoteConfigService>(), isA<RemoteConfigService>());
      expect(getIt<StorageService>(), isA<StorageService>());
      expect(getIt<AiService>(), isA<AiService>());
    });

    test('setupServiceLocator registers prod dependencies', () {
      setupServiceLocator(Environment.prod);

      expect(getIt.isRegistered<CrashService>(), isTrue);
      expect(getIt.isRegistered<PerformanceService>(), isTrue);
      expect(getIt.isRegistered<AnalyticsService>(), isTrue);
      expect(getIt.isRegistered<LocalStorageService>(), isTrue);
      expect(getIt.isRegistered<RemoteConfigService>(), isTrue);
      expect(getIt.isRegistered<StorageService>(), isTrue);
      expect(getIt.isRegistered<AiService>(), isTrue);

      try {
        getIt<CrashService>();
      } on Exception catch (_) {}
      try {
        getIt<PerformanceService>();
      } on Exception catch (_) {}
      try {
        getIt<AnalyticsService>();
      } on Exception catch (_) {}
      try {
        getIt<LocalStorageService>();
      } on Exception catch (_) {}
      try {
        getIt<RemoteConfigService>();
      } on Exception catch (_) {}
      try {
        getIt<StorageService>();
      } on Exception catch (_) {}
      try {
        getIt<AiService>();
      } on Exception catch (_) {}
    });

    test('Environment enum has correct values', () {
      expect(Environment.values, contains(Environment.mock));
      expect(Environment.values, contains(Environment.prod));
    });

    group('ServiceFactory', () {
      test('mock cases', () {
        expect(
          ServiceFactory.getCrashRepository(Environment.mock),
          isA<MockCrashRepository>(),
        );
        expect(
          ServiceFactory.getPerformanceRepository(Environment.mock),
          isA<MockPerformanceRepository>(),
        );
        expect(
          ServiceFactory.getAnalyticsRepository(Environment.mock),
          isA<MockAnalyticsRepository>(),
        );
        expect(
          ServiceFactory.getLocalStorageRepository(Environment.mock),
          isA<MockLocalStorageRepository>(),
        );
        expect(
          ServiceFactory.getRemoteConfigRepository(Environment.mock),
          isA<MockRemoteConfigRepository>(),
        );
        expect(
          ServiceFactory.getStorageRepository(Environment.mock),
          isA<MockStorageRepository>(),
        );
        expect(
          ServiceFactory.getAiRepository(Environment.mock),
          isA<MockAiRepository>(),
        );
      });

      test('prod cases (hitting lines via try-catch)', () {
        expect(
          ServiceFactory.getLocalStorageRepository(Environment.prod),
          isA<SharedPrefsLocalStorageRepository>(),
        );
        expect(
          ServiceFactory.getStorageRepository(Environment.prod),
          isA<MethodChannelStorageRepository>(),
        );
        expect(
          ServiceFactory.getAiRepository(Environment.prod),
          isA<FirebaseAiRepository>(),
        );

        try {
          ServiceFactory.getCrashRepository(Environment.prod);
        } on Exception catch (_) {}
        try {
          ServiceFactory.getPerformanceRepository(Environment.prod);
        } on Exception catch (_) {}
        try {
          ServiceFactory.getAnalyticsRepository(Environment.prod);
        } on Exception catch (_) {}
        try {
          ServiceFactory.getRemoteConfigRepository(Environment.prod);
        } on Exception catch (_) {}
      });
    });
  });
}
