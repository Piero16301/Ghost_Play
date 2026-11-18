import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_play/app/app.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';

void main() {
  setUpAll(registerFallbackValues);

  group('AiService', () {
    late MocktailAiRepository aiRepository;
    late MockLocalStorageService localStorage;
    late MockPerformanceService performance;
    late MockStorageService storageService;
    late MockRemoteConfigService remoteConfig;
    late MockCrashService crashService;
    late MockAnalyticsService analyticsService;
    late MockTrace trace;
    late AiService service;
    late Directory tempDir;

    setUp(() async {
      await getIt.reset();
      aiRepository = MocktailAiRepository();
      localStorage = MockLocalStorageService();
      performance = MockPerformanceService();
      storageService = MockStorageService();
      remoteConfig = MockRemoteConfigService();
      crashService = MockCrashService();
      analyticsService = MockAnalyticsService();
      trace = MockTrace();

      getIt
        ..registerSingleton<LocalStorageService>(localStorage)
        ..registerSingleton<PerformanceService>(performance)
        ..registerSingleton<StorageService>(storageService)
        ..registerSingleton<RemoteConfigService>(remoteConfig)
        ..registerSingleton<CrashService>(crashService)
        ..registerSingleton<AnalyticsService>(analyticsService);

      when(
        () => analyticsService.logEvent(
          name: any(named: 'name'),
          parameters: any(named: 'parameters'),
        ),
      ).thenReturn(null);
      when(() => performance.startTrace(any())).thenReturn(trace);
      when(() => performance.stopTrace(any())).thenReturn(null);
      when(() => remoteConfig.geminiModelName).thenReturn('gemini-model');
      when(() => remoteConfig.geminiSystemInstruction)
          .thenReturn('sys-instruction');
      when(() => remoteConfig.geminiPromptExtractAudio)
          .thenReturn('extract audio');
      when(() => remoteConfig.geminiPromptExtractVideo)
          .thenReturn('extract video');
      when(
        () => localStorage.saveTranscription(
          fileName: any(named: 'fileName'),
          transcription: any(named: 'transcription'),
        ),
      ).thenReturn(null);

      service = AiService(aiRepository: aiRepository);
      tempDir = Directory.systemTemp.createTempSync('ai_service_test_');
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
      await getIt.reset();
    });

    group('extractAudioTranscription', () {
      final validAudio = AudioMetadata(
        uri: 'content://audio/1',
        name: 'PTT-01.OPUS',
        date: DateTime(2026),
        sizeBytes: 128,
        durationMs: 1000,
      );

      test('returns null when uri is empty or extension is not opus', () async {
        final emptyUri = AudioMetadata(
          uri: '',
          name: 'audio.opus',
          date: DateTime(2026),
          sizeBytes: 10,
          durationMs: 100,
        );
        final wrongExt = AudioMetadata(
          uri: 'content://audio/2',
          name: 'audio.mp3',
          date: DateTime(2026),
          sizeBytes: 10,
          durationMs: 100,
        );

        expect(
          await service.extractAudioTranscription(audio: emptyUri),
          isNull,
        );
        expect(
          await service.extractAudioTranscription(audio: wrongExt),
          isNull,
        );
        verifyNever(() => performance.startTrace(any()));
      });

      test('returns cached transcription when forceRefresh is false', () async {
        when(() => localStorage.getTranscription(fileName: validAudio.name))
            .thenReturn(
              TranscriptionMetadata(
                text: 'cached audio text',
                timestamp: DateTime(2026),
              ),
            );

        final result = await service.extractAudioTranscription(
          audio: validAudio,
        );

        expect(result, 'cached audio text');
        verify(
          () => analyticsService.logEvent(
            name: 'audio_transcription_source',
            parameters: {'source': 'cache_hit'},
          ),
        ).called(1);
        verifyNever(() => performance.startTrace(any()));
        verifyNever(
          () => storageService.cacheFile(
            uri: any(named: 'uri'),
            fileName: any(named: 'fileName'),
          ),
        );
      });

      test(
        'returns null and stops trace when cacheFile returns null',
        () async {
          when(() => localStorage.getTranscription(fileName: validAudio.name))
              .thenReturn(
                TranscriptionMetadata(text: '   ', timestamp: DateTime(2026)),
              );
          when(
            () => storageService.cacheFile(
              uri: validAudio.uri,
              fileName: validAudio.name,
            ),
          ).thenAnswer((_) async => null);

          final result = await service.extractAudioTranscription(
            audio: validAudio,
          );

          expect(result, isNull);
          verify(
            () => performance.startTrace('gemini_extract_audio_transcription'),
          ).called(1);
          verify(() => performance.stopTrace(trace)).called(1);
        },
      );

      test('bypasses cache on forceRefresh, reads and deletes temp file, '
          'generates and saves transcription', () async {
        final tempFile = File('${tempDir.path}/PTT-01.opus')
          ..writeAsBytesSync([1, 2, 3]);
        when(
          () => storageService.cacheFile(
            uri: validAudio.uri,
            fileName: validAudio.name,
          ),
        ).thenAnswer((_) async => tempFile.path);
        when(
          () => aiRepository.generateContentRemote(
            model: any(named: 'model'),
            systemInstruction: any(named: 'systemInstruction'),
            prompt: any(named: 'prompt'),
          ),
        ).thenAnswer((_) async => 'fresh transcription');

        final result = await service.extractAudioTranscription(
          audio: validAudio,
          forceRefresh: true,
        );

        expect(result, 'fresh transcription');
        verify(
          () => analyticsService.logEvent(
            name: 'audio_transcription_source',
            parameters: {'source': 'remote_call'},
          ),
        ).called(1);
        expect(tempFile.existsSync(), isFalse);
        verifyNever(
          () => localStorage.getTranscription(fileName: any(named: 'fileName')),
        );
        final captured = verify(
          () => aiRepository.generateContentRemote(
            model: 'gemini-model',
            systemInstruction: 'sys-instruction',
            prompt: captureAny(named: 'prompt'),
          ),
        ).captured;
        final prompt = captured.first as List<PromptPart>;
        expect(prompt, hasLength(2));
        expect(prompt[0].type, PromptPartType.text);
        expect(prompt[0].text, 'extract audio');
        expect(prompt[1].type, PromptPartType.file);
        expect(prompt[1].mimeType, 'audio/ogg');
        expect(prompt[1].bytes, [1, 2, 3]);

        verify(
          () => localStorage.saveTranscription(
            fileName: validAudio.name,
            transcription: any(
              named: 'transcription',
              that: isA<TranscriptionMetadata>().having(
                (t) => t.text,
                'text',
                'fresh transcription',
              ),
            ),
          ),
        ).called(1);
        verify(() => performance.stopTrace(trace)).called(1);
      });

      test(
        'does not save transcription when AI returns null or whitespace',
        () async {
          final tempFile1 = File('${tempDir.path}/a1.opus')
            ..writeAsBytesSync([4, 5]);
          final tempFile2 = File('${tempDir.path}/a2.opus')
            ..writeAsBytesSync([6, 7]);
          var callCount = 0;

          when(() => localStorage.getTranscription(fileName: validAudio.name))
              .thenReturn(null);
          when(
            () => storageService.cacheFile(
              uri: validAudio.uri,
              fileName: validAudio.name,
            ),
          ).thenAnswer(
            (_) async => callCount++ == 0 ? tempFile1.path : tempFile2.path,
          );
          when(
            () => aiRepository.generateContentRemote(
              model: any(named: 'model'),
              systemInstruction: any(named: 'systemInstruction'),
              prompt: any(named: 'prompt'),
            ),
          ).thenAnswer((_) async => callCount == 1 ? null : '   ');

          expect(
            await service.extractAudioTranscription(audio: validAudio),
            isNull,
          );
          expect(
            await service.extractAudioTranscription(audio: validAudio),
            '   ',
          );
          verifyNever(
            () => localStorage.saveTranscription(
              fileName: any(named: 'fileName'),
              transcription: any(named: 'transcription'),
            ),
          );
        },
      );

      test(
        'records error, stops trace, and rethrows when exception occurs',
        () async {
          final exception = Exception('ai failed');
          final tempFile = File('${tempDir.path}/err.opus')
            ..writeAsBytesSync([1]);
          when(() => localStorage.getTranscription(fileName: validAudio.name))
              .thenReturn(null);
          when(
            () => storageService.cacheFile(
              uri: validAudio.uri,
              fileName: validAudio.name,
            ),
          ).thenAnswer((_) async => tempFile.path);
          when(
            () => aiRepository.generateContentRemote(
              model: any(named: 'model'),
              systemInstruction: any(named: 'systemInstruction'),
              prompt: any(named: 'prompt'),
            ),
          ).thenThrow(exception);

          await expectLater(
            service.extractAudioTranscription(audio: validAudio),
            throwsA(exception),
          );

          verify(
            () => crashService.recordError(
              exception,
              any<StackTrace?>(),
              reason: 'AiService extractAudioTranscription error',
            ),
          ).called(1);
          verify(() => performance.stopTrace(trace)).called(1);
        },
      );
    });

    group('extractVideoTranscription', () {
      final validVideo = MultimediaMetadata(
        uri: 'content://video/1',
        name: 'VID-01.MP4',
        date: DateTime(2026),
        sizeBytes: 256,
        isVideo: true,
        videoDurationMs: 2000,
      );

      test(
        'returns null when uri empty, not video, or extension is not mp4',
        () async {
          final emptyUri = MultimediaMetadata(
            uri: '',
            name: 'v.mp4',
            date: DateTime(2026),
            sizeBytes: 10,
            isVideo: true,
          );
          final notVideo = MultimediaMetadata(
            uri: 'content://img/1',
            name: 'v.mp4',
            date: DateTime(2026),
            sizeBytes: 10,
            isVideo: false,
          );
          final wrongExt = MultimediaMetadata(
            uri: 'content://video/2',
            name: 'v.mov',
            date: DateTime(2026),
            sizeBytes: 10,
            isVideo: true,
          );

          expect(
            await service.extractVideoTranscription(video: emptyUri),
            isNull,
          );
          expect(
            await service.extractVideoTranscription(video: notVideo),
            isNull,
          );
          expect(
            await service.extractVideoTranscription(video: wrongExt),
            isNull,
          );
          verifyNever(() => performance.startTrace(any()));
        },
      );

      test('returns cached transcription when forceRefresh is false', () async {
        when(() => localStorage.getTranscription(fileName: validVideo.name))
            .thenReturn(
              TranscriptionMetadata(
                text: 'cached video text',
                timestamp: DateTime(2026),
              ),
            );

        final result = await service.extractVideoTranscription(
          video: validVideo,
        );

        expect(result, 'cached video text');
        verify(
          () => analyticsService.logEvent(
            name: 'video_transcription_source',
            parameters: {'source': 'cache_hit'},
          ),
        ).called(1);
        verifyNever(() => performance.startTrace(any()));
        verifyNever(
          () => storageService.cacheFile(
            uri: any(named: 'uri'),
            fileName: any(named: 'fileName'),
          ),
        );
      });

      test(
        'returns null and stops trace when cacheFile returns null',
        () async {
          when(() => localStorage.getTranscription(fileName: validVideo.name))
              .thenReturn(
                TranscriptionMetadata(text: '  ', timestamp: DateTime(2026)),
              );
          when(
            () => storageService.cacheFile(
              uri: validVideo.uri,
              fileName: validVideo.name,
            ),
          ).thenAnswer((_) async => null);

          final result = await service.extractVideoTranscription(
            video: validVideo,
          );

          expect(result, isNull);
          verify(
            () => performance.startTrace('gemini_extract_video_transcription'),
          ).called(1);
          verify(() => performance.stopTrace(trace)).called(1);
        },
      );

      test('bypasses cache on forceRefresh, reads file, generates and saves '
          'transcription', () async {
        final tempFile = File('${tempDir.path}/VID-01.mp4')
          ..writeAsBytesSync([9, 8, 7]);
        when(
          () => storageService.cacheFile(
            uri: validVideo.uri,
            fileName: validVideo.name,
          ),
        ).thenAnswer((_) async => tempFile.path);
        when(
          () => aiRepository.generateContentRemote(
            model: any(named: 'model'),
            systemInstruction: any(named: 'systemInstruction'),
            prompt: any(named: 'prompt'),
          ),
        ).thenAnswer((_) async => 'fresh video transcription');

        final result = await service.extractVideoTranscription(
          video: validVideo,
          forceRefresh: true,
        );

        expect(result, 'fresh video transcription');
        verify(
          () => analyticsService.logEvent(
            name: 'video_transcription_source',
            parameters: {'source': 'remote_call'},
          ),
        ).called(1);
        verifyNever(
          () => localStorage.getTranscription(fileName: any(named: 'fileName')),
        );
        final captured = verify(
          () => aiRepository.generateContentRemote(
            model: 'gemini-model',
            systemInstruction: 'sys-instruction',
            prompt: captureAny(named: 'prompt'),
          ),
        ).captured;
        final prompt = captured.first as List<PromptPart>;
        expect(prompt, hasLength(2));
        expect(prompt[0].type, PromptPartType.text);
        expect(prompt[0].text, 'extract video');
        expect(prompt[1].type, PromptPartType.file);
        expect(prompt[1].mimeType, 'video/mp4');
        expect(prompt[1].bytes, [9, 8, 7]);

        verify(
          () => localStorage.saveTranscription(
            fileName: validVideo.name,
            transcription: any(
              named: 'transcription',
              that: isA<TranscriptionMetadata>().having(
                (t) => t.text,
                'text',
                'fresh video transcription',
              ),
            ),
          ),
        ).called(1);
        verify(() => performance.stopTrace(trace)).called(1);
      });

      test(
        'does not save transcription when AI returns null or whitespace',
        () async {
          final tempFile = File('${tempDir.path}/v1.mp4')
            ..writeAsBytesSync([1, 2]);
          var callCount = 0;

          when(() => localStorage.getTranscription(fileName: validVideo.name))
              .thenReturn(null);
          when(
            () => storageService.cacheFile(
              uri: validVideo.uri,
              fileName: validVideo.name,
            ),
          ).thenAnswer((_) async => tempFile.path);
          when(
            () => aiRepository.generateContentRemote(
              model: any(named: 'model'),
              systemInstruction: any(named: 'systemInstruction'),
              prompt: any(named: 'prompt'),
            ),
          ).thenAnswer((_) async => callCount++ == 0 ? null : '   ');

          expect(
            await service.extractVideoTranscription(video: validVideo),
            isNull,
          );
          expect(
            await service.extractVideoTranscription(video: validVideo),
            '   ',
          );
          verifyNever(
            () => localStorage.saveTranscription(
              fileName: any(named: 'fileName'),
              transcription: any(named: 'transcription'),
            ),
          );
        },
      );

      test(
        'records error, stops trace, and rethrows when exception occurs',
        () async {
          final exception = Exception('video ai failed');
          final tempFile = File('${tempDir.path}/err.mp4')
            ..writeAsBytesSync([5]);
          when(() => localStorage.getTranscription(fileName: validVideo.name))
              .thenReturn(null);
          when(
            () => storageService.cacheFile(
              uri: validVideo.uri,
              fileName: validVideo.name,
            ),
          ).thenAnswer((_) async => tempFile.path);
          when(
            () => aiRepository.generateContentRemote(
              model: any(named: 'model'),
              systemInstruction: any(named: 'systemInstruction'),
              prompt: any(named: 'prompt'),
            ),
          ).thenThrow(exception);

          await expectLater(
            service.extractVideoTranscription(video: validVideo),
            throwsA(exception),
          );

          verify(
            () => crashService.recordError(
              exception,
              any<StackTrace?>(),
              reason: 'AiService extractVideoTranscription error',
            ),
          ).called(1);
          verify(() => performance.stopTrace(trace)).called(1);
        },
      );
    });
  });
}
