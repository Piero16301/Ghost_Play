import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_play/app/app.dart';
import 'package:ghost_play/home/home.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';

void main() {
  late HomeCubit homeCubit;
  late MockStorageService storageService;
  late MockAnalyticsService analyticsService;
  late MockCrashService crashService;
  late MockPerformanceService performanceService;
  late MockSaf mockSaf;

  setUpAll(registerFallbackValues);

  setUp(() {
    storageService = MockStorageService();
    analyticsService = MockAnalyticsService();
    crashService = MockCrashService();
    performanceService = MockPerformanceService();
    mockSaf = MockSaf();

    unawaited(getIt.reset());
    getIt
      ..registerSingleton<StorageService>(storageService)
      ..registerSingleton<AnalyticsService>(analyticsService)
      ..registerSingleton<CrashService>(crashService)
      ..registerSingleton<PerformanceService>(performanceService);

    when(
      () => performanceService.startTrace(any<String>()),
    ).thenReturn(MockTrace());
    when(() => crashService.log(any<String>())).thenReturn(null);
    when(
      () => crashService.recordError(
        any<dynamic>(),
        any<StackTrace?>(),
        reason: any<dynamic>(named: 'reason'),
      ),
    ).thenReturn(null);
    when(
      () => analyticsService.logEvent(
        name: any<String>(named: 'name'),
        parameters: any<Map<String, Object>?>(named: 'parameters'),
      ),
    ).thenAnswer((_) async {});

    homeCubit = HomeCubit(storageService: storageService);
  });

  tearDown(() {
    unawaited(homeCubit.close());
  });

  group('HomeCubit constructor', () {
    test('uses getIt when storageService is null', () {
      final cubit = HomeCubit();
      expect(cubit.state, const HomeState());
      unawaited(cubit.close());
    });
  });

  group('HomeStatus', () {
    test('getters return correct values', () {
      expect(HomeStatus.initial.isInitial, isTrue);
      expect(HomeStatus.initial.isLoading, isFalse);
      expect(HomeStatus.loading.isLoading, isTrue);
      expect(HomeStatus.success.isSuccess, isTrue);
      expect(HomeStatus.failure.isFailure, isTrue);
    });
  });

  group('HomeState', () {
    test('supports value equality', () {
      expect(const HomeState(), equals(const HomeState()));
    });

    test('copyWith returns object with updated values', () {
      expect(
        const HomeState().copyWith(selectedIndex: 1),
        const HomeState(selectedIndex: 1),
      );
    });

    test('props are correct', () {
      expect(const HomeState().props, [
        0,
        HomeStatus.initial,
        HomeStatus.initial,
        HomeStatus.initial,
        null,
        false,
        '',
        const <AudioMetadata>[],
        1,
        const <MultimediaMetadata>[],
        const <MultimediaMetadata>[],
        1,
      ]);
    });
  });

  group('HomeCubit', () {
    test('initial state is correct', () {
      expect(homeCubit.state, const HomeState());
    });

    blocTest<HomeCubit, HomeState>(
      'toggleSelectedIndex emits state with updated index',
      build: () => homeCubit,
      act: (cubit) => cubit.toggleSelectedIndex(1),
      expect: () => [const HomeState(selectedIndex: 1)],
    );

    group('initStorage', () {
      blocTest<HomeCubit, HomeState>(
        'emits success when persisted directories exist',
        setUp: () {
          when(
            () => storageService.getPersistedPermissionDirectories(),
          ).thenAnswer((_) async => ['uri1']);
          when(
            () => storageService.getRecentAudios(
              uri: any<String>(named: 'uri'),
              weeks: any<int>(named: 'weeks'),
            ),
          ).thenAnswer((_) async => []);
          when(
            () =>
                storageService.getRecentStates(uri: any<String>(named: 'uri')),
          ).thenAnswer((_) async => []);
          when(
            () => storageService.getRecentVideos(
              uri: any<String>(named: 'uri'),
              weeks: any<int>(named: 'weeks'),
            ),
          ).thenAnswer((_) async => []);
        },
        build: () => homeCubit,
        act: (cubit) => cubit.initStorage(),
        verify: (_) {
          verify(
            () => storageService.getPersistedPermissionDirectories(),
          ).called(1);
        },
      );

      blocTest<HomeCubit, HomeState>(
        'emits hasPermission false when no persisted directories',
        setUp: () {
          when(
            () => storageService.getPersistedPermissionDirectories(),
          ).thenAnswer((_) async => []);
        },
        build: () => homeCubit,
        act: (cubit) => cubit.initStorage(),
        expect: () => [const HomeState()],
      );

      blocTest<HomeCubit, HomeState>(
        'emits hasPermission false on exception',
        setUp: () {
          when(
            () => storageService.getPersistedPermissionDirectories(),
          ).thenThrow(Exception('error'));
        },
        build: () => homeCubit,
        act: (cubit) => cubit.initStorage(),
        expect: () => [const HomeState()],
      );
    });

    group('loadAudios', () {
      blocTest<HomeCubit, HomeState>(
        'returns early if saf is null',
        build: () => homeCubit,
        act: (cubit) => cubit.loadAudios(),
        expect: () => <HomeState>[],
      );

      blocTest<HomeCubit, HomeState>(
        'returns early if savedDirectoryUri is empty',
        seed: () => HomeState(saf: mockSaf),
        build: () => homeCubit,
        act: (cubit) => cubit.loadAudios(),
        expect: () => <HomeState>[],
      );

      blocTest<HomeCubit, HomeState>(
        'emits success with loaded audios',
        seed: () => HomeState(
          saf: mockSaf,
          savedDirectoryUri: 'uri1',
          hasPermission: true,
        ),
        setUp: () {
          when(
            () => storageService.getRecentAudios(uri: 'uri1', weeks: 1),
          ).thenAnswer(
            (_) async => [
              {
                'uri': 'a',
                'name': 'n',
                'date': 123,
                'size': 100,
                'duration': 1000,
              },
            ],
          );
        },
        build: () => homeCubit,
        act: (cubit) => cubit.loadAudios(),
        expect: () => [
          HomeState(
            audiosStatus: HomeStatus.loading,
            saf: mockSaf,
            savedDirectoryUri: 'uri1',
            hasPermission: true,
          ),
          HomeState(
            audiosStatus: HomeStatus.success,
            saf: mockSaf,
            savedDirectoryUri: 'uri1',
            hasPermission: true,
            audios: [
              AudioMetadata(
                uri: 'a',
                name: 'n',
                date: DateTime.fromMillisecondsSinceEpoch(123),
                sizeBytes: 100,
                durationMs: 1000,
              ),
            ],
          ),
        ],
      );

      blocTest<HomeCubit, HomeState>(
        'emits failure on PlatformException',
        seed: () => HomeState(
          savedDirectoryUri: 'uri1',
          saf: mockSaf,
        ),
        setUp: () {
          when(
            () => storageService.getRecentAudios(uri: 'uri1', weeks: 1),
          ).thenThrow(PlatformException(code: 'error'));
        },
        build: () => homeCubit,
        act: (cubit) => cubit.loadAudios(),
        expect: () => [
          HomeState(
            audiosStatus: HomeStatus.loading,
            saf: mockSaf,
            savedDirectoryUri: 'uri1',
          ),
          HomeState(
            audiosStatus: HomeStatus.failure,
            saf: mockSaf,
            savedDirectoryUri: 'uri1',
          ),
        ],
      );

      blocTest<HomeCubit, HomeState>(
        'emits failure on Exception',
        seed: () => HomeState(
          savedDirectoryUri: 'uri1',
          saf: mockSaf,
        ),
        setUp: () {
          when(
            () => storageService.getRecentAudios(uri: 'uri1', weeks: 1),
          ).thenThrow(Exception('error'));
        },
        build: () => homeCubit,
        act: (cubit) => cubit.loadAudios(),
        expect: () => [
          HomeState(
            audiosStatus: HomeStatus.loading,
            saf: mockSaf,
            savedDirectoryUri: 'uri1',
          ),
          HomeState(
            audiosStatus: HomeStatus.failure,
            saf: mockSaf,
            savedDirectoryUri: 'uri1',
          ),
        ],
      );
    });

    group('requestPermission', () {
      blocTest<HomeCubit, HomeState>(
        'emits hasPermission true when granted',
        setUp: () {
          when(
            () => storageService.getDirectoryPermission(any<String>()),
          ).thenAnswer((_) async => true);
          when(
            () => storageService.getPersistedPermissionDirectories(),
          ).thenAnswer((_) async => ['uri1']);
          when(
            () => storageService.getRecentAudios(
              uri: any<String>(named: 'uri'),
              weeks: any<int>(named: 'weeks'),
            ),
          ).thenAnswer((_) async => []);
          when(
            () =>
                storageService.getRecentStates(uri: any<String>(named: 'uri')),
          ).thenAnswer((_) async => []);
          when(
            () => storageService.getRecentVideos(
              uri: any<String>(named: 'uri'),
              weeks: any<int>(named: 'weeks'),
            ),
          ).thenAnswer((_) async => []);
        },
        build: () => homeCubit,
        act: (cubit) => cubit.requestPermission(),
        verify: (_) {
          verify(
            () => storageService.getDirectoryPermission(any<String>()),
          ).called(1);
        },
      );

      blocTest<HomeCubit, HomeState>(
        'does nothing when denied',
        setUp: () {
          when(
            () => storageService.getDirectoryPermission(any<String>()),
          ).thenAnswer((_) async => false);
        },
        build: () => homeCubit,
        act: (cubit) => cubit.requestPermission(),
        expect: () => <HomeState>[],
      );

      blocTest<HomeCubit, HomeState>(
        'does nothing when isGranted is null',
        setUp: () {
          when(
            () => storageService.getDirectoryPermission(any<String>()),
          ).thenAnswer((_) async => null);
        },
        build: () => homeCubit,
        act: (cubit) => cubit.requestPermission(),
        expect: () => <HomeState>[],
      );

      blocTest<HomeCubit, HomeState>(
        'does nothing when granted but persistedDirs is empty',
        setUp: () {
          when(
            () => storageService.getDirectoryPermission(any<String>()),
          ).thenAnswer((_) async => true);
          when(
            () => storageService.getPersistedPermissionDirectories(),
          ).thenAnswer((_) async => []);
        },
        build: () => homeCubit,
        act: (cubit) => cubit.requestPermission(),
        expect: () => <HomeState>[],
      );
    });

    group('setWeeks', () {
      blocTest<HomeCubit, HomeState>(
        'emits updated audio weeks and loads audios',
        setUp: () {
          when(
            () => storageService.getRecentAudios(
              uri: any<String>(named: 'uri'),
              weeks: any<int>(named: 'weeks'),
            ),
          ).thenAnswer((_) async => []);
        },
        build: () => homeCubit,
        act: (cubit) => cubit.setAudiosWeeks(2),
        expect: () => [
          const HomeState(audioWeeksFilter: 2),
        ],
      );

      blocTest<HomeCubit, HomeState>(
        'emits updated video weeks and loads videos',
        setUp: () {
          when(
            () => storageService.getRecentVideos(
              uri: any<String>(named: 'uri'),
              weeks: any<int>(named: 'weeks'),
            ),
          ).thenAnswer((_) async => []);
        },
        build: () => homeCubit,
        act: (cubit) => cubit.setVideosWeeks(2),
        expect: () => [
          const HomeState(videoWeeksFilter: 2),
        ],
      );

      blocTest<HomeCubit, HomeState>(
        'does nothing if audio weeks are the same',
        build: () => homeCubit,
        act: (cubit) => cubit.setAudiosWeeks(1),
        expect: () => <HomeState>[],
      );

      blocTest<HomeCubit, HomeState>(
        'does nothing if video weeks are the same',
        build: () => homeCubit,
        act: (cubit) => cubit.setVideosWeeks(1),
        expect: () => <HomeState>[],
      );
    });

    group('loadStates', () {
      blocTest<HomeCubit, HomeState>(
        'emits success with loaded states',
        seed: () => HomeState(
          savedDirectoryUri: 'uri1',
          saf: mockSaf,
        ),
        setUp: () {
          when(() => storageService.getRecentStates(uri: 'uri1')).thenAnswer(
            (_) async => [
              {
                'uri': 'a',
                'name': 'n',
                'date': 123,
                'size': 100,
                'is_video': true,
                'duration': 1000,
              },
            ],
          );
        },
        build: () => homeCubit,
        act: (cubit) => cubit.loadStates(),
        expect: () => [
          HomeState(
            statesStatus: HomeStatus.loading,
            saf: mockSaf,
            savedDirectoryUri: 'uri1',
          ),
          HomeState(
            statesStatus: HomeStatus.success,
            saf: mockSaf,
            savedDirectoryUri: 'uri1',
            states: [
              MultimediaMetadata(
                uri: 'a',
                name: 'n',
                date: DateTime.fromMillisecondsSinceEpoch(123),
                sizeBytes: 100,
                isVideo: true,
                videoDurationMs: 1000,
              ),
            ],
          ),
        ],
      );

      blocTest<HomeCubit, HomeState>(
        'emits failure on PlatformException',
        seed: () => HomeState(
          savedDirectoryUri: 'uri1',
          saf: mockSaf,
        ),
        setUp: () {
          when(
            () => storageService.getRecentStates(uri: 'uri1'),
          ).thenThrow(PlatformException(code: 'error'));
        },
        build: () => homeCubit,
        act: (cubit) => cubit.loadStates(),
        expect: () => [
          HomeState(
            statesStatus: HomeStatus.loading,
            saf: mockSaf,
            savedDirectoryUri: 'uri1',
          ),
          HomeState(
            statesStatus: HomeStatus.failure,
            saf: mockSaf,
            savedDirectoryUri: 'uri1',
          ),
        ],
      );

      blocTest<HomeCubit, HomeState>(
        'emits failure on Exception',
        seed: () => HomeState(
          savedDirectoryUri: 'uri1',
          saf: mockSaf,
        ),
        setUp: () {
          when(
            () => storageService.getRecentStates(uri: 'uri1'),
          ).thenThrow(Exception('error'));
        },
        build: () => homeCubit,
        act: (cubit) => cubit.loadStates(),
        expect: () => [
          HomeState(
            statesStatus: HomeStatus.loading,
            saf: mockSaf,
            savedDirectoryUri: 'uri1',
          ),
          HomeState(
            statesStatus: HomeStatus.failure,
            saf: mockSaf,
            savedDirectoryUri: 'uri1',
          ),
        ],
      );

      blocTest<HomeCubit, HomeState>(
        'returns early if saf is null',
        build: () => homeCubit,
        act: (cubit) => cubit.loadStates(),
        expect: () => <HomeState>[],
      );

      blocTest<HomeCubit, HomeState>(
        'returns early if savedDirectoryUri is empty',
        seed: () => HomeState(saf: mockSaf),
        build: () => homeCubit,
        act: (cubit) => cubit.loadStates(),
        expect: () => <HomeState>[],
      );
    });

    group('loadVideos', () {
      blocTest<HomeCubit, HomeState>(
        'returns early if saf is null',
        build: () => homeCubit,
        act: (cubit) => cubit.loadVideos(),
        expect: () => <HomeState>[],
      );

      blocTest<HomeCubit, HomeState>(
        'returns early if savedDirectoryUri is empty',
        seed: () => HomeState(saf: mockSaf),
        build: () => homeCubit,
        act: (cubit) => cubit.loadVideos(),
        expect: () => <HomeState>[],
      );

      blocTest<HomeCubit, HomeState>(
        'emits success with loaded videos',
        seed: () => HomeState(
          savedDirectoryUri: 'uri1',
          saf: mockSaf,
        ),
        setUp: () {
          when(
            () => storageService.getRecentVideos(uri: 'uri1', weeks: 1),
          ).thenAnswer(
            (_) async => [
              {
                'uri': 'v',
                'name': 'n',
                'date': 123,
                'size': 100,
                'is_video': true,
              },
            ],
          );
        },
        build: () => homeCubit,
        act: (cubit) => cubit.loadVideos(),
        expect: () => [
          HomeState(
            videosStatus: HomeStatus.loading,
            saf: mockSaf,
            savedDirectoryUri: 'uri1',
          ),
          HomeState(
            videosStatus: HomeStatus.success,
            saf: mockSaf,
            savedDirectoryUri: 'uri1',
            videos: [
              MultimediaMetadata(
                uri: 'v',
                name: 'n',
                date: DateTime.fromMillisecondsSinceEpoch(123),
                sizeBytes: 100,
                isVideo: true,
              ),
            ],
          ),
        ],
      );

      blocTest<HomeCubit, HomeState>(
        'emits failure on PlatformException',
        seed: () => HomeState(
          savedDirectoryUri: 'uri1',
          saf: mockSaf,
        ),
        setUp: () {
          when(
            () => storageService.getRecentVideos(uri: 'uri1', weeks: 1),
          ).thenThrow(PlatformException(code: 'error'));
        },
        build: () => homeCubit,
        act: (cubit) => cubit.loadVideos(),
        expect: () => [
          HomeState(
            videosStatus: HomeStatus.loading,
            saf: mockSaf,
            savedDirectoryUri: 'uri1',
          ),
          HomeState(
            videosStatus: HomeStatus.failure,
            saf: mockSaf,
            savedDirectoryUri: 'uri1',
          ),
        ],
      );

      blocTest<HomeCubit, HomeState>(
        'emits failure on Exception',
        seed: () => HomeState(
          savedDirectoryUri: 'uri1',
          saf: mockSaf,
        ),
        setUp: () {
          when(
            () => storageService.getRecentVideos(uri: 'uri1', weeks: 1),
          ).thenThrow(Exception('error'));
        },
        build: () => homeCubit,
        act: (cubit) => cubit.loadVideos(),
        expect: () => [
          HomeState(
            videosStatus: HomeStatus.loading,
            saf: mockSaf,
            savedDirectoryUri: 'uri1',
          ),
          HomeState(
            videosStatus: HomeStatus.failure,
            saf: mockSaf,
            savedDirectoryUri: 'uri1',
          ),
        ],
      );
    });
  });
}
