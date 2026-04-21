import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_play/home/home.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';

void main() {
  group('HomeCubit', () {
    late StorageService storageService;
    late HomeCubit homeCubit;
    late MockSaf mockSaf;

    setUpAll(registerFallbackValues);

    setUp(() {
      storageService = MockStorageService();
      homeCubit = HomeCubit(storageService: storageService);
      mockSaf = MockSaf();
    });

    tearDown(() {
      unawaited(homeCubit.close());
    });

    test('initial state is HomeState()', () {
      expect(homeCubit.state, const HomeState());
    });

    group('initStorage', () {
      blocTest<HomeCubit, HomeState>(
        'emits failure status when exception is thrown',
        build: () {
          when(
            () => storageService.getPersistedPermissionDirectories(),
          ).thenThrow(Exception('error'));
          return homeCubit;
        },
        act: (cubit) => cubit.initStorage(),
        expect: () => [
          const HomeState(status: HomeStatus.failure),
        ],
      );

      blocTest<HomeCubit, HomeState>(
        'emits hasPermission false when no directories found',
        build: () {
          when(
            () => storageService.getPersistedPermissionDirectories(),
          ).thenAnswer((_) async => []);
          return homeCubit;
        },
        act: (cubit) => cubit.initStorage(),
        expect: () => [
          const HomeState(),
        ],
      );

      blocTest<HomeCubit, HomeState>(
        'emits success and loads audios when directories found',
        build: () {
          when(
            () => storageService.getPersistedPermissionDirectories(),
          ).thenAnswer((_) async => ['uri1']);
          when(
            () => storageService.getRecentAudios(
              uri: 'uri1',
              weeks: any(named: 'weeks'),
            ),
          ).thenAnswer((_) async => []);
          return homeCubit;
        },
        act: (cubit) => cubit.initStorage(),
        expect: () => [
          predicate<HomeState>(
            (state) =>
                state.status == HomeStatus.success &&
                state.hasPermission &&
                state.savedDirectoryUri == 'uri1' &&
                state.saf != null,
          ),
          predicate<HomeState>((state) => state.status == HomeStatus.loading),
          predicate<HomeState>(
            (state) =>
                state.status == HomeStatus.success && state.audios.isEmpty,
          ),
        ],
      );
    });

    group('loadAudios', () {
      blocTest<HomeCubit, HomeState>(
        'does nothing if saf is null',
        build: () => homeCubit,
        act: (cubit) => cubit.loadAudios(),
        expect: () => <HomeState>[],
      );

      blocTest<HomeCubit, HomeState>(
        'does nothing if savedDirectoryUri is empty',
        seed: () => HomeState(saf: mockSaf),
        build: () => homeCubit,
        act: (cubit) => cubit.loadAudios(),
        expect: () => <HomeState>[],
      );

      blocTest<HomeCubit, HomeState>(
        'emits success with loaded audios',
        seed: () => HomeState(saf: mockSaf, savedDirectoryUri: 'uri1'),
        build: () {
          when(
            () => storageService.getRecentAudios(
              uri: 'uri1',
              weeks: any(named: 'weeks'),
            ),
          ).thenAnswer(
            (_) async => [
              {
                'uri': 'a1',
                'name': 'n1',
                'date': DateTime(2023).millisecondsSinceEpoch,
                'size': 100,
                'duration': 1000,
              },
            ],
          );
          return homeCubit;
        },
        act: (cubit) => cubit.loadAudios(),
        expect: () => [
          HomeState(
            status: HomeStatus.loading,
            savedDirectoryUri: 'uri1',
            saf: mockSaf,
          ),
          predicate<HomeState>(
            (state) =>
                state.status == HomeStatus.success &&
                state.audios.length == 1 &&
                state.saf == mockSaf,
          ),
        ],
      );

      blocTest<HomeCubit, HomeState>(
        'emits failure on PlatformException',
        seed: () => HomeState(saf: mockSaf, savedDirectoryUri: 'uri1'),
        build: () {
          when(
            () => storageService.getRecentAudios(
              uri: 'uri1',
              weeks: any(named: 'weeks'),
            ),
          ).thenThrow(PlatformException(code: 'error'));
          return homeCubit;
        },
        act: (cubit) => cubit.loadAudios(),
        expect: () => [
          HomeState(
            status: HomeStatus.loading,
            savedDirectoryUri: 'uri1',
            saf: mockSaf,
          ),
          HomeState(
            status: HomeStatus.failure,
            savedDirectoryUri: 'uri1',
            saf: mockSaf,
          ),
        ],
      );

      blocTest<HomeCubit, HomeState>(
        'emits failure on Exception',
        seed: () => HomeState(saf: mockSaf, savedDirectoryUri: 'uri1'),
        build: () {
          when(
            () => storageService.getRecentAudios(
              uri: 'uri1',
              weeks: any(named: 'weeks'),
            ),
          ).thenThrow(Exception('error'));
          return homeCubit;
        },
        act: (cubit) => cubit.loadAudios(),
        expect: () => [
          HomeState(
            status: HomeStatus.loading,
            savedDirectoryUri: 'uri1',
            saf: mockSaf,
          ),
          HomeState(
            status: HomeStatus.failure,
            savedDirectoryUri: 'uri1',
            saf: mockSaf,
          ),
        ],
      );
    });

    group('requestPermission', () {
      blocTest<HomeCubit, HomeState>(
        'does nothing when isGranted is false',
        build: () {
          when(
            () => storageService.getDirectoryPermission(any()),
          ).thenAnswer((_) async => false);
          return homeCubit;
        },
        act: (cubit) => cubit.requestPermission(),
        expect: () => <HomeState>[],
      );

      blocTest<HomeCubit, HomeState>(
        'emits success when isGranted is true and directories found',
        build: () {
          when(
            () => storageService.getDirectoryPermission(any()),
          ).thenAnswer((_) async => true);
          when(
            () => storageService.getPersistedPermissionDirectories(),
          ).thenAnswer((_) async => ['uri1']);
          when(
            () => storageService.getRecentAudios(
              uri: 'uri1',
              weeks: any(named: 'weeks'),
            ),
          ).thenAnswer((_) async => []);
          return homeCubit;
        },
        act: (cubit) => cubit.requestPermission(),
        expect: () => [
          predicate<HomeState>(
            (state) =>
                state.status == HomeStatus.success &&
                state.hasPermission &&
                state.savedDirectoryUri == 'uri1',
          ),
          predicate<HomeState>((state) => state.status == HomeStatus.loading),
          predicate<HomeState>(
            (state) =>
                state.status == HomeStatus.success && state.audios.isEmpty,
          ),
        ],
      );

      blocTest<HomeCubit, HomeState>(
        'does nothing extra when isGranted is true but no directories found',
        build: () {
          when(
            () => storageService.getDirectoryPermission(any()),
          ).thenAnswer((_) async => true);
          when(
            () => storageService.getPersistedPermissionDirectories(),
          ).thenAnswer((_) async => []);
          return homeCubit;
        },
        act: (cubit) => cubit.requestPermission(),
        expect: () => <HomeState>[],
      );
    });

    group('setWeeks', () {
      blocTest<HomeCubit, HomeState>(
        'does nothing if weeks are the same',
        seed: () => const HomeState(weeks: 2),
        build: () => homeCubit,
        act: (cubit) => cubit.setWeeks(2),
        expect: () => <HomeState>[],
      );

      blocTest<HomeCubit, HomeState>(
        'updates weeks and loads audios',
        seed: () =>
            HomeState(weeks: 2, saf: mockSaf, savedDirectoryUri: 'uri1'),
        build: () {
          when(
            () => storageService.getRecentAudios(
              uri: 'uri1',
              weeks: 3,
            ),
          ).thenAnswer((_) async => []);
          return homeCubit;
        },
        act: (cubit) => cubit.setWeeks(3),
        expect: () => [
          HomeState(weeks: 3, savedDirectoryUri: 'uri1', saf: mockSaf),
          HomeState(
            status: HomeStatus.loading,
            weeks: 3,
            savedDirectoryUri: 'uri1',
            saf: mockSaf,
          ),
          HomeState(
            status: HomeStatus.success,
            weeks: 3,
            savedDirectoryUri: 'uri1',
            saf: mockSaf,
          ),
        ],
      );
    });

    test('default constructor uses MethodChannelStorageService', () {
      final cubit = HomeCubit();
      expect(cubit, isA<HomeCubit>());
      unawaited(cubit.close());
    });
  });
}
