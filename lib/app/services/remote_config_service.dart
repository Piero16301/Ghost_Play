import 'package:ghost_play/app/app.dart';

class RemoteConfigService {
  new({required this._remoteConfigRepository});

  final RemoteConfigRepository _remoteConfigRepository;

  Future<void> initialize() async {
    final performance = getIt<PerformanceService>();
    final trace = performance.startTrace('remote_config_initialize');
    try {
      await _remoteConfigRepository.initialize();
    } on Exception catch (e, stackTrace) {
      getIt<CrashService>().recordError(
        e,
        stackTrace,
        reason: 'RemoteConfig initialization failed',
      );
    } finally {
      performance.stopTrace(trace);
    }
  }

  String get geminiModelName => _remoteConfigRepository.geminiModelName;
  String get geminiSystemInstruction =>
      _remoteConfigRepository.geminiSystemInstruction;
  String get geminiPromptExtractAudio =>
      _remoteConfigRepository.geminiPromptExtractAudio;
  String get geminiPromptExtractVideo =>
      _remoteConfigRepository.geminiPromptExtractVideo;
  int get maxDaysSavedTranscriptions =>
      _remoteConfigRepository.maxDaysSavedTranscriptions;
}
