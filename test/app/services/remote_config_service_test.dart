import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_play/app/app.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';

void main() {
  setUpAll(registerFallbackValues);

  group('RemoteConfigService', () {
    late MocktailRemoteConfigRepository repository;
    late MockCrashService crashService;
    late MockPerformanceService performanceService;
    late MockTrace trace;
    late RemoteConfigService service;

    setUp(() async {
      await getIt.reset();
      repository = MocktailRemoteConfigRepository();
      crashService = MockCrashService();
      performanceService = MockPerformanceService();
      trace = MockTrace();

      getIt
        ..registerSingleton<CrashService>(crashService)
        ..registerSingleton<PerformanceService>(performanceService);

      when(() => performanceService.startTrace(any())).thenReturn(trace);
      when(() => performanceService.stopTrace(any())).thenReturn(null);

      service = RemoteConfigService(remoteConfigRepository: repository);
    });

    tearDown(() async {
      await getIt.reset();
    });

    test('initialize delegates to repository', () async {
      when(() => repository.initialize()).thenAnswer((_) async {});

      await service.initialize();

      verify(() => repository.initialize()).called(1);
      verify(() => performanceService.startTrace('remote_config_initialize'))
          .called(1);
      verify(() => performanceService.stopTrace(trace)).called(1);
      verifyNever(
        () => crashService.recordError(
          any<dynamic>(),
          any<StackTrace?>(),
          reason: any<String?>(named: 'reason'),
        ),
      );
    });

    test('initialize records error when repository throws Exception', () async {
      final exception = Exception('fetch failed');
      when(() => repository.initialize()).thenThrow(exception);

      await service.initialize();

      verify(
        () => crashService.recordError(
          exception,
          any<StackTrace?>(),
          reason: 'RemoteConfig initialization failed',
        ),
      ).called(1);
      verify(() => performanceService.startTrace('remote_config_initialize'))
          .called(1);
      verify(() => performanceService.stopTrace(trace)).called(1);
    });

    test('getters delegate to repository', () {
      when(() => repository.geminiModelName).thenReturn('model');
      when(() => repository.geminiSystemInstruction).thenReturn('system');
      when(() => repository.geminiPromptExtractAudio).thenReturn('audio');
      when(() => repository.geminiPromptExtractVideo).thenReturn('video');
      when(() => repository.maxDaysSavedTranscriptions).thenReturn(21);

      expect(service.geminiModelName, 'model');
      expect(service.geminiSystemInstruction, 'system');
      expect(service.geminiPromptExtractAudio, 'audio');
      expect(service.geminiPromptExtractVideo, 'video');
      expect(service.maxDaysSavedTranscriptions, 21);

      verify(() => repository.geminiModelName).called(1);
      verify(() => repository.geminiSystemInstruction).called(1);
      verify(() => repository.geminiPromptExtractAudio).called(1);
      verify(() => repository.geminiPromptExtractVideo).called(1);
      verify(() => repository.maxDaysSavedTranscriptions).called(1);
    });
  });
}
