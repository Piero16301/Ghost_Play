import 'dart:io';
import 'dart:typed_data';

import 'package:ghost_play/app/app.dart';

class AiService {
  new({required this._aiRepository});

  final AiRepository _aiRepository;

  Future<String?> extractAudioTranscription({
    required AudioMetadata audio,
    bool forceRefresh = false,
  }) async {
    if (audio.uri.isEmpty || !audio.name.toLowerCase().endsWith('.opus')) {
      return null;
    }

    final localStorage = getIt<LocalStorageService>();
    if (!forceRefresh) {
      final cached = localStorage.getTranscription(fileName: audio.name);
      if (cached != null && cached.text.trim().isNotEmpty) {
        getIt<AnalyticsService>().logEvent(
          name: 'audio_transcription_source',
          parameters: {'source': 'cache_hit'},
        );
        return cached.text;
      }
    }

    final performance = getIt<PerformanceService>();
    final trace = performance.startTrace('gemini_extract_audio_transcription');

    try {
      final path = await getIt<StorageService>().cacheFile(
        uri: audio.uri,
        fileName: audio.name,
      );
      if (path == null) {
        return null;
      }

      final tempFile = File(path);
      final Uint8List bytes;
      try {
        bytes = await tempFile.readAsBytes();
      } finally {
        try {
          if (tempFile.existsSync()) {
            await tempFile.delete();
          }
        } on Object catch (_) {}
      }

      final remoteConfig = getIt<RemoteConfigService>();

      getIt<AnalyticsService>().logEvent(
        name: 'audio_transcription_source',
        parameters: {'source': 'remote_call'},
      );
      final result = await _aiRepository.generateContentRemote(
        model: remoteConfig.geminiModelName,
        systemInstruction: remoteConfig.geminiSystemInstruction,
        prompt: [
          PromptPart.text(text: remoteConfig.geminiPromptExtractAudio),
          PromptPart.file(mimeType: 'audio/ogg', bytes: bytes),
        ],
      );

      if (result != null && result.trim().isNotEmpty) {
        localStorage.saveTranscription(
          fileName: audio.name,
          transcription: TranscriptionMetadata(
            text: result,
            timestamp: DateTime.now(),
          ),
        );
      }

      return result;
    } catch (e, stackTrace) {
      getIt<CrashService>().recordError(
        e,
        stackTrace,
        reason: 'AiService extractAudioTranscription error',
      );
      rethrow;
    } finally {
      performance.stopTrace(trace);
    }
  }

  Future<String?> extractVideoTranscription({
    required MultimediaMetadata video,
    bool forceRefresh = false,
  }) async {
    if (video.uri.isEmpty ||
        !video.isVideo ||
        !video.name.toLowerCase().endsWith('.mp4')) {
      return null;
    }

    final localStorage = getIt<LocalStorageService>();
    if (!forceRefresh) {
      final cached = localStorage.getTranscription(fileName: video.name);
      if (cached != null && cached.text.trim().isNotEmpty) {
        getIt<AnalyticsService>().logEvent(
          name: 'video_transcription_source',
          parameters: {'source': 'cache_hit'},
        );
        return cached.text;
      }
    }

    final performance = getIt<PerformanceService>();
    final trace = performance.startTrace('gemini_extract_video_transcription');

    try {
      final path = await getIt<StorageService>().cacheFile(
        uri: video.uri,
        fileName: video.name,
      );
      if (path == null) {
        return null;
      }

      final bytes = await File(path).readAsBytes();
      final remoteConfig = getIt<RemoteConfigService>();

      getIt<AnalyticsService>().logEvent(
        name: 'video_transcription_source',
        parameters: {'source': 'remote_call'},
      );
      final result = await _aiRepository.generateContentRemote(
        model: remoteConfig.geminiModelName,
        systemInstruction: remoteConfig.geminiSystemInstruction,
        prompt: [
          PromptPart.text(text: remoteConfig.geminiPromptExtractVideo),
          PromptPart.file(mimeType: 'video/mp4', bytes: bytes),
        ],
      );

      if (result != null && result.trim().isNotEmpty) {
        localStorage.saveTranscription(
          fileName: video.name,
          transcription: TranscriptionMetadata(
            text: result,
            timestamp: DateTime.now(),
          ),
        );
      }

      return result;
    } catch (e, stackTrace) {
      getIt<CrashService>().recordError(
        e,
        stackTrace,
        reason: 'AiService extractVideoTranscription error',
      );
      rethrow;
    } finally {
      performance.stopTrace(trace);
    }
  }
}
