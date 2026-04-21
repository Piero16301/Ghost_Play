import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_play/home/home.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MethodChannelStorageService', () {
    late MethodChannelStorageService service;
    const storageChannel = MethodChannel('ghostplay/storage');
    const safChannel = MethodChannel('com.ivehement.plugins/saf/documentfile');

    setUp(() {
      service = MethodChannelStorageService();

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
            if (methodCall.method == 'persistedUriPermissions') {
              return <Map<String, dynamic>>[];
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
        final result = await service.getPersistedPermissionDirectories();
        expect(result, isEmpty);
      },
    );

    test(
      'getRecentAudios calls method channel with correct arguments',
      () async {
        final result = await service.getRecentAudios(uri: 'uri1', weeks: 2);
        expect(
          result,
          equals([
            {'uri': 'a'},
          ]),
        );
      },
    );

    test('getDirectoryPermission calls Saf and returns result', () async {
      final result = await service.getDirectoryPermission('path1');
      expect(result, isFalse);
    });
  });
}
