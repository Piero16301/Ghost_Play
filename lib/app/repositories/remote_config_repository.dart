import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:ghost_play/app/app.dart';

abstract class RemoteConfigRepository {
  /// CONFIG
  static const String configGeminiModelName = 'config_gemini_model_name';
  static const String configGeminiSystemInstruction =
      'config_gemini_system_instruction';
  static const String configGeminiPromptExtractAudio =
      'config_gemini_prompt_extract_audio';
  static const String configGeminiPromptExtractVideo =
      'config_gemini_prompt_extract_video';
  static const String configMaxDaysSavedTranscriptions =
      'config_max_days_saved_transcriptions';

  Future<void> initialize();

  String get geminiModelName;
  String get geminiSystemInstruction;
  String get geminiPromptExtractAudio;
  String get geminiPromptExtractVideo;
  int get maxDaysSavedTranscriptions;
}

class MockRemoteConfigRepository implements RemoteConfigRepository {
  @override
  Future<void> initialize() async {}

  @override
  String get geminiModelName => 'gemini-3.5-flash-lite';

  @override
  String get geminiSystemInstruction => 'config_gemini_system_instruction';

  @override
  String get geminiPromptExtractAudio => 'config_gemini_prompt_extract_audio';

  @override
  String get geminiPromptExtractVideo => 'config_gemini_prompt_extract_video';

  @override
  int get maxDaysSavedTranscriptions => 14;
}

class FirebaseRemoteConfigRepository implements RemoteConfigRepository {
  new({FirebaseRemoteConfig? remoteConfig})
    : _remoteConfig = remoteConfig ?? FirebaseRemoteConfig.instance;

  final FirebaseRemoteConfig _remoteConfig;

  @override
  Future<void> initialize() async {
    await _remoteConfig.setDefaults({
      RemoteConfigRepository.configGeminiModelName: 'gemini-3.5-flash-lite',
      RemoteConfigRepository.configGeminiSystemInstruction:
          'config_gemini_system_instruction',
      RemoteConfigRepository.configGeminiPromptExtractAudio:
          'config_gemini_prompt_extract_audio',
      RemoteConfigRepository.configGeminiPromptExtractVideo:
          'config_gemini_prompt_extract_video',
      RemoteConfigRepository.configMaxDaysSavedTranscriptions: 14,
    });

    await _remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: AppVariables.remoteConfigFetchTimeout,
        minimumFetchInterval: kDebugMode
            ? Duration.zero
            : AppVariables.remoteConfigMinimumFetchInterval,
      ),
    );
    await _remoteConfig.fetchAndActivate();
  }

  @override
  String get geminiModelName =>
      _remoteConfig.getString(RemoteConfigRepository.configGeminiModelName);

  @override
  String get geminiSystemInstruction => _remoteConfig.getString(
    RemoteConfigRepository.configGeminiSystemInstruction,
  );

  @override
  String get geminiPromptExtractAudio => _remoteConfig.getString(
    RemoteConfigRepository.configGeminiPromptExtractAudio,
  );

  @override
  String get geminiPromptExtractVideo => _remoteConfig.getString(
    RemoteConfigRepository.configGeminiPromptExtractVideo,
  );

  @override
  int get maxDaysSavedTranscriptions => _remoteConfig.getInt(
    RemoteConfigRepository.configMaxDaysSavedTranscriptions,
  );
}
