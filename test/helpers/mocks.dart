import 'package:bloc_test/bloc_test.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/services.dart';
import 'package:ghost_play/app/app.dart';
import 'package:ghost_play/home/home.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saf/saf.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAppCubit extends MockCubit<AppState> implements AppCubit;

class MockHomeCubit extends MockCubit<HomeState> implements HomeCubit;

class MockAudiosHomeCubit extends MockCubit<AudiosHomeState>
    implements AudiosHomeCubit;

class MocktailLocalStorageRepository extends Mock
    implements LocalStorageRepository;

class MocktailAnalyticsRepository extends Mock implements AnalyticsRepository;

class MocktailCrashRepository extends Mock implements CrashRepository;

class MocktailPerformanceRepository extends Mock
    implements PerformanceRepository;

class MocktailAiRepository extends Mock implements AiRepository;

class MocktailRemoteConfigRepository extends Mock
    implements RemoteConfigRepository;

class MockLocalStorageService extends Mock implements LocalStorageService;

class MockAnalyticsService extends Mock implements AnalyticsService;

class MockCrashService extends Mock implements CrashService;

class MockPerformanceService extends Mock implements PerformanceService;

class MockRemoteConfigService extends Mock implements RemoteConfigService;

class MockAiService extends Mock implements AiService;

class MockAudioPlayer extends Mock implements ja.AudioPlayer;

class MockSharedPreferences extends Mock implements SharedPreferences;

class MockSaf extends Mock implements Saf;

class MockGoRouter extends Mock implements GoRouter;

class MockMethodChannel extends Mock implements MethodChannel;

class MockStorageService extends Mock implements StorageService;

class MockFirebaseAI extends Mock implements FirebaseAI;

class MockFirebaseAnalytics extends Mock implements FirebaseAnalytics;

class MockFirebaseApp extends Mock implements FirebaseApp;

class MockFirebaseCrashlytics extends Mock implements FirebaseCrashlytics;

class MockFirebasePerformance extends Mock implements FirebasePerformance;

class MockFirebaseRemoteConfig extends Mock implements FirebaseRemoteConfig;

class MockTrace extends Mock implements Trace;

class FakeAppState extends Fake implements AppState;

class FakeHomeState extends Fake implements HomeState;

class FakeAudiosHomeState extends Fake implements AudiosHomeState;

class FakeAudioMetadata extends Fake implements AudioMetadata;

class FakeMultimediaMetadata extends Fake implements MultimediaMetadata;

class FakeTranscriptionMetadata extends Fake implements TranscriptionMetadata;

class FakeRemoteConfigSettings extends Fake implements RemoteConfigSettings;

void registerFallbackValues() {
  registerFallbackValue(FakeAppState());
  registerFallbackValue(FakeHomeState());
  registerFallbackValue(FakeAudiosHomeState());
  registerFallbackValue(FakeAudioMetadata());
  registerFallbackValue(FakeMultimediaMetadata());
  registerFallbackValue(FakeTranscriptionMetadata());
  registerFallbackValue(FakeRemoteConfigSettings());
  registerFallbackValue(<PromptPart>[]);
  registerFallbackValue(const Locale('en', 'US'));
  registerFallbackValue(ThemeMode.system);
  registerFallbackValue(Colors.blue);
  registerFallbackValue(StackTrace.empty);
  registerFallbackValue(MockTrace());
  registerFallbackValue(ja.PlayerState(false, ja.ProcessingState.idle));
  registerFallbackValue(ja.AudioSource.uri(Uri.parse('')));
  registerFallbackValue(Duration.zero);
}
