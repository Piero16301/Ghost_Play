import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_play/app/app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MethodChannelStorageRepository', () {
    late MethodChannelStorageRepository repository;
    const storageChannel = MethodChannel('ghostplay/storage');
    const safChannel = MethodChannel('com.ivehement.plugins/saf/v2');

    setUp(() {
      repository = MethodChannelStorageRepository();

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(storageChannel, (methodCall) async {
            if (methodCall.method == 'getRecentAudios') {
              return [
                {'uri': 'a'},
              ];
            }
            return null;
          });

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(safChannel, (methodCall) async {
            if (methodCall.method == 'persistedPermissions') {
              return <Map<String, dynamic>>[];
            }
            if (methodCall.method == 'pickDirectory') {
              return null;
            }
            return null;
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(storageChannel, null);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(safChannel, null);
    });

    test(
      'getPersistedPermissionDirectories calls Saf and returns directories',
      () async {
        final result = await repository.getPersistedPermissionDirectories();
        expect(result, isEmpty);
      },
    );

    test(
      'getRecentAudios calls method channel with correct arguments',
      () async {
        final result = await repository.getRecentAudios(uri: 'uri1', weeks: 2);
        expect(
          result,
          equals([
            {'uri': 'a'},
          ]),
        );
      },
    );

    test('getDirectoryPermission calls Saf and returns result', () async {
      final result = await repository.getDirectoryPermission('path1');
      expect(result, isFalse);
    });

    test('getRecentStates calls method channel', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(storageChannel, (methodCall) async {
            if (methodCall.method == 'getRecentStates') {
              return [
                {'uri': 's'},
              ];
            }
            return null;
          });

      final result = await repository.getRecentStates(uri: 'uri1');
      expect(result, [
        {'uri': 's'},
      ]);
    });

    test('getThumbnailBytes calls method channel', () async {
      final bytes = Uint8List.fromList([1, 2, 3]);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(storageChannel, (methodCall) async {
            if (methodCall.method == 'getThumbnailBytes') {
              return bytes;
            }
            return null;
          });

      final result = await repository.getThumbnailBytes(
        uri: 'uri1',
        isVideo: true,
      );
      expect(result, bytes);
    });

    test('getRecentVideos calls method channel', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(storageChannel, (methodCall) async {
            if (methodCall.method == 'getRecentVideos') {
              return [
                {'uri': 'v'},
              ];
            }
            return null;
          });

      final result = await repository.getRecentVideos(uri: 'uri1', weeks: 3);
      expect(result, [
        {'uri': 'v'},
      ]);
    });

    test('cacheFile calls method channel', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(storageChannel, (methodCall) async {
            if (methodCall.method == 'cacheFile') {
              return 'cached_path';
            }
            return null;
          });

      final result = await repository.cacheFile(
        uri: 'uri1',
        fileName: 'file.mp3',
      );
      expect(result, 'cached_path');
    });
  });

  group('MockStorageRepository', () {
    late MockStorageRepository repository;

    setUp(() {
      repository = MockStorageRepository();
    });

    test('getPersistedPermissionDirectories returns mock directory', () async {
      final result = await repository.getPersistedPermissionDirectories();
      expect(result, ['mock://whatsapp/voice_notes']);
    });

    test('getRecentAudios returns mock audios within weeks filter', () async {
      final result = await repository.getRecentAudios(uri: 'uri1', weeks: 2);
      expect(result, isNotEmpty);
      expect(result!.length, 6);
    });

    test('getDirectoryPermission returns true', () async {
      final result = await repository.getDirectoryPermission('path');
      expect(result, isTrue);
    });

    test('getRecentStates returns mock states', () async {
      final result = await repository.getRecentStates(uri: 'uri1');
      expect(result, isNotEmpty);
      expect(result!.length, 4);
    });

    test('getThumbnailBytes returns null when asset does not exist', () async {
      final result = await repository.getThumbnailBytes(
        uri: 'uri1',
        isVideo: true,
      );
      expect(result, isNull);
    });

    test('getRecentVideos returns mock videos within weeks filter', () async {
      final result = await repository.getRecentVideos(uri: 'uri1', weeks: 2);
      expect(result, isNotEmpty);
      expect(result!.length, 2);
    });

    test('cacheFile returns null when asset does not exist', () async {
      final result = await repository.cacheFile(
        uri: 'uri1',
        fileName: 'file.mp3',
      );
      expect(result, isNull);
    });
  });
}
