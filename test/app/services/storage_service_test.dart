import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_play/app/app.dart';
import 'package:mocktail/mocktail.dart';

class MocktailStorageRepository extends Mock implements StorageRepository {}

void main() {
  group('StorageService', () {
    late StorageService service;
    late StorageRepository repository;

    setUp(() {
      repository = MocktailStorageRepository();
      service = StorageService(storageRepository: repository);
    });

    test('getPersistedPermissionDirectories delegates to repository', () async {
      when(
        () => repository.getPersistedPermissionDirectories(),
      ).thenAnswer((_) async => ['a']);
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
      when(
        () => repository.getDirectoryPermission('path'),
      ).thenAnswer((_) async => true);
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

    test('getThumbnailBytes delegates to repository', () async {
      final bytes = Uint8List.fromList([1, 2, 3]);
      when(
        () => repository.getThumbnailBytes(uri: 'uri1', isVideo: true),
      ).thenAnswer((_) async => bytes);
      final result = await service.getThumbnailBytes(
        uri: 'uri1',
        isVideo: true,
      );
      expect(result, bytes);
      verify(
        () => repository.getThumbnailBytes(uri: 'uri1', isVideo: true),
      ).called(1);
    });

    test('cacheFile delegates to repository', () async {
      when(
        () => repository.cacheFile(uri: 'uri1', fileName: 'file.mp3'),
      ).thenAnswer((_) async => 'cached_path');
      final result = await service.cacheFile(uri: 'uri1', fileName: 'file.mp3');
      expect(result, 'cached_path');
      verify(
        () => repository.cacheFile(uri: 'uri1', fileName: 'file.mp3'),
      ).called(1);
    });
  });
}
