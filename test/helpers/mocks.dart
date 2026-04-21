import 'package:bloc_test/bloc_test.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ghost_play/app/app.dart';
import 'package:ghost_play/home/home.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:mocktail/mocktail.dart';
import 'package:saf/saf.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAppCubit extends MockCubit<AppState> implements AppCubit {}

class MockHomeCubit extends MockCubit<HomeState> implements HomeCubit {}

class MockPlayerCubit extends MockCubit<PlayerState> implements PlayerCubit {}

class MocktailLocalStorageRepository extends Mock
    implements LocalStorageRepository {}

class MocktailAnalyticsRepository extends Mock implements AnalyticsRepository {}

class MocktailCrashRepository extends Mock implements CrashRepository {}

class MocktailPerformanceRepository extends Mock
    implements PerformanceRepository {}

class MockLocalStorageService extends Mock implements LocalStorageService {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

class MockCrashService extends Mock implements CrashService {}

class MockPerformanceService extends Mock implements PerformanceService {}

class MockAudioPlayer extends Mock implements ja.AudioPlayer {}

class MockSharedPreferences extends Mock implements SharedPreferences {}

class MockSaf extends Mock implements Saf {}

class MockGoRouter extends Mock implements GoRouter {}

class MockMethodChannel extends Mock implements MethodChannel {}

class MockStorageService extends Mock implements StorageService {}

class MockFirebaseAnalytics extends Mock implements FirebaseAnalytics {}

class MockFirebaseCrashlytics extends Mock implements FirebaseCrashlytics {}

class MockFirebasePerformance extends Mock implements FirebasePerformance {}

class MockTrace extends Mock implements Trace {}

class FakeAppState extends Fake implements AppState {}

class FakeHomeState extends Fake implements HomeState {}

class FakePlayerState extends Fake implements PlayerState {}

class FakeAudioMetadata extends Fake implements AudioMetadata {}

void registerFallbackValues() {
  registerFallbackValue(FakeAppState());
  registerFallbackValue(FakeHomeState());
  registerFallbackValue(FakePlayerState());
  registerFallbackValue(FakeAudioMetadata());
  registerFallbackValue(const Locale('en', 'US'));
  registerFallbackValue(ThemeMode.system);
  registerFallbackValue(Colors.blue);
  registerFallbackValue(StackTrace.empty);
  registerFallbackValue(MockTrace());
  registerFallbackValue(ja.PlayerState(false, ja.ProcessingState.idle));
  registerFallbackValue(ja.AudioSource.uri(Uri.parse('')));
  registerFallbackValue(Duration.zero);
}
