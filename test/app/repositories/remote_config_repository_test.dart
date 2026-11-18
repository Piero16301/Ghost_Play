import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_play/app/app.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';

void main() {
  setUpAll(registerFallbackValues);

  group('MockRemoteConfigRepository', () {
    test('returns expected defaults and initializes cleanly', () async {
      final repository = MockRemoteConfigRepository();

      await expectLater(repository.initialize(), completes);
      expect(repository.geminiModelName, 'gemini-3.5-flash-lite');
      expect(
        repository.geminiSystemInstruction,
        'config_gemini_system_instruction',
      );
      expect(
        repository.geminiPromptExtractAudio,
        'config_gemini_prompt_extract_audio',
      );
      expect(
        repository.geminiPromptExtractVideo,
        'config_gemini_prompt_extract_video',
      );
      expect(repository.maxDaysSavedTranscriptions, 14);
    });
  });

  group('FirebaseRemoteConfigRepository', () {
    late MockFirebaseRemoteConfig remoteConfig;
    late FirebaseRemoteConfigRepository repository;

    setUp(() {
      remoteConfig = MockFirebaseRemoteConfig();
      repository = FirebaseRemoteConfigRepository(remoteConfig: remoteConfig);
    });

    test('default constructor hits FirebaseRemoteConfig.instance', () {
      try {
        FirebaseRemoteConfigRepository();
      } on Object catch (_) {}
    });

    test('initialize sets defaults, config settings, and fetches', () async {
      when(() => remoteConfig.setDefaults(any())).thenAnswer((_) async {});
      when(() => remoteConfig.setConfigSettings(any()))
          .thenAnswer((_) async {});
      when(() => remoteConfig.fetchAndActivate()).thenAnswer((_) async => true);

      await repository.initialize();

      verify(
        () => remoteConfig.setDefaults({
          RemoteConfigRepository.configGeminiModelName: 'gemini-3.5-flash-lite',
          RemoteConfigRepository.configGeminiSystemInstruction:
              'config_gemini_system_instruction',
          RemoteConfigRepository.configGeminiPromptExtractAudio:
              'config_gemini_prompt_extract_audio',
          RemoteConfigRepository.configGeminiPromptExtractVideo:
              'config_gemini_prompt_extract_video',
          RemoteConfigRepository.configMaxDaysSavedTranscriptions: 14,
        }),
      ).called(1);

      final captured = verify(
        () => remoteConfig.setConfigSettings(captureAny()),
      ).captured;
      expect(captured, hasLength(1));
      final settings = captured.first as RemoteConfigSettings;
      expect(settings.fetchTimeout, AppVariables.remoteConfigFetchTimeout);
      expect(
        settings.minimumFetchInterval,
        kDebugMode
            ? Duration.zero
            : AppVariables.remoteConfigMinimumFetchInterval,
      );

      verify(() => remoteConfig.fetchAndActivate()).called(1);
    });

    test('getters delegate to FirebaseRemoteConfig', () {
      when(
        () => remoteConfig.getString(
          RemoteConfigRepository.configGeminiModelName,
        ),
      ).thenReturn('gemini-model');
      when(
        () => remoteConfig.getString(
          RemoteConfigRepository.configGeminiSystemInstruction,
        ),
      ).thenReturn('sys-instruction');
      when(
        () => remoteConfig.getString(
          RemoteConfigRepository.configGeminiPromptExtractAudio,
        ),
      ).thenReturn('audio-prompt');
      when(
        () => remoteConfig.getString(
          RemoteConfigRepository.configGeminiPromptExtractVideo,
        ),
      ).thenReturn('video-prompt');
      when(
        () => remoteConfig.getInt(
          RemoteConfigRepository.configMaxDaysSavedTranscriptions,
        ),
      ).thenReturn(30);

      expect(repository.geminiModelName, 'gemini-model');
      expect(repository.geminiSystemInstruction, 'sys-instruction');
      expect(repository.geminiPromptExtractAudio, 'audio-prompt');
      expect(repository.geminiPromptExtractVideo, 'video-prompt');
      expect(repository.maxDaysSavedTranscriptions, 30);
    });
  });
}
