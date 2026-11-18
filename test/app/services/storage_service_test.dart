import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_play/app/app.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';

class MocktailStorageRepository extends Mock implements StorageRepository;

void main() {
  setUpAll(registerFallbackValues);

  group('StorageService', () {
    late StorageService service;
    late StorageRepository repository;
    late MockPerformanceService performanceService;
    late MockCrashService crashService;
    late MockTrace trace;

    setUp(() async {
      await getIt.reset();
      repository = MocktailStorageRepository();
      performanceService = MockPerformanceService();
      crashService = MockCrashService();
      trace = MockTrace();

      getIt
        ..registerSingleton<PerformanceService>(performanceService)
        ..registerSingleton<CrashService>(crashService);

      when(() => performanceService.startTrace(any())).thenReturn(trace);
      when(() => performanceService.stopTrace(any())).thenReturn(null);
      when(
        () => crashService.recordError(
          any<dynamic>(),
          any<StackTrace?>(),
          reason: any<dynamic>(named: 'reason'),
        ),
      ).thenReturn(null);

      service = StorageService(storageRepository: repository);
    });

    tearDown(() async {
      await getIt.reset();
    });

    test('getPersistedPermissionDirectories delegates to repository', () async {
      when(() => repository.getPersistedPermissionDirectories())
          .thenAnswer((_) async => ['a']);
      final result = await service.getPersistedPermissionDirectories();
      expect(result, ['a']);
      verify(() => repository.getPersistedPermissionDirectories()).called(1);
    });

    test('getRecentAudios delegates to repository', () async {
      when(() => repository.getRecentAudios(uri: 'uri1', weeks: 2)).thenAnswer(
        (_) async => [
          {'a': 'b'},
        ],
      );
      final result = await service.getRecentAudios(uri: 'uri1', weeks: 2);
      expect(result, [
        {'a': 'b'},
      ]);
      verify(() => repository.getRecentAudios(uri: 'uri1', weeks: 2)).called(1);
    });

    test('getDirectoryPermission delegates to repository', () async {
      when(() => repository.getDirectoryPermission('path'))
          .thenAnswer((_) async => true);
      final result = await service.getDirectoryPermission('path');
      expect(result, isTrue);
      verify(() => repository.getDirectoryPermission('path')).called(1);
    });

    test('getRecentStates delegates to repository', () async {
      when(() => repository.getRecentStates(uri: 'uri1')).thenAnswer(
        (_) async => [
          {'a': 'b'},
        ],
      );
      final result = await service.getRecentStates(uri: 'uri1');
      expect(result, [
        {'a': 'b'},
      ]);
      verify(() => repository.getRecentStates(uri: 'uri1')).called(1);
    });

    test(
      'getThumbnailBytes delegates to repository and caches result',
      () async {
        final bytes = Uint8List.fromList([1, 2, 3]);
        when(() => repository.getThumbnailBytes(uri: 'uri1', isVideo: true))
            .thenAnswer((_) async => bytes);
        final result = await service.getThumbnailBytes(
          uri: 'uri1',
          isVideo: true,
        );
        expect(result, bytes);
        expect(service.getCachedThumbnail('uri1'), bytes);
        verify(
          () => performanceService.startTrace('thumbnail_generation_latency'),
        ).called(1);
        verify(() => performanceService.stopTrace(trace)).called(1);

        final cachedResult = await service.getThumbnailBytes(
          uri: 'uri1',
          isVideo: true,
        );
        expect(cachedResult, bytes);
        verify(() => repository.getThumbnailBytes(uri: 'uri1', isVideo: true))
            .called(1);
      },
    );

    test(
      'getThumbnailBytes records error and returns null on exception',
      () async {
        final exception = Exception('thumb failed');
        when(() => repository.getThumbnailBytes(uri: 'uri_err', isVideo: true))
            .thenThrow(exception);

        final result = await service.getThumbnailBytes(
          uri: 'uri_err',
          isVideo: true,
        );

        expect(result, isNull);
        verify(
          () => crashService.recordError(
            exception,
            any<StackTrace?>(),
            reason: 'Error getting thumbnail bytes for uri_err',
          ),
        ).called(1);
        verify(() => performanceService.stopTrace(trace)).called(1);
      },
    );

    test('getRecentVideos delegates to repository', () async {
      when(() => repository.getRecentVideos(uri: 'uri1', weeks: 3)).thenAnswer(
        (_) async => [
          {'v': 'w'},
        ],
      );
      final result = await service.getRecentVideos(uri: 'uri1', weeks: 3);
      expect(result, [
        {'v': 'w'},
      ]);
      verify(() => repository.getRecentVideos(uri: 'uri1', weeks: 3)).called(1);
    });

    test('cacheFile delegates to repository', () async {
      when(() => repository.cacheFile(uri: 'uri1', fileName: 'file.mp3'))
          .thenAnswer((_) async => 'cached_path');
      final result = await service.cacheFile(uri: 'uri1', fileName: 'file.mp3');
      expect(result, 'cached_path');
      verify(() => repository.cacheFile(uri: 'uri1', fileName: 'file.mp3'))
          .called(1);
    });
  });
}
