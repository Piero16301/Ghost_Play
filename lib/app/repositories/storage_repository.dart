import 'package:flutter/services.dart';
import 'package:saf/saf.dart';

abstract class StorageRepository {
  Future<List<String>?> getPersistedPermissionDirectories();
  Future<List<dynamic>?> getRecentAudios({
    required String uri,
    required int weeks,
  });
  Future<List<dynamic>?> getRecentStates({
    required String uri,
  });
  Future<Uint8List?> getThumbnailBytes({
    required String uri,
    required bool isVideo,
  });
  Future<String?> cacheFile({
    required String uri,
    required String fileName,
  });
  Future<bool?> getDirectoryPermission(String path);
}

class MockStorageRepository implements StorageRepository {
  @override
  Future<List<String>?> getPersistedPermissionDirectories() async {
    return [];
  }

  @override
  Future<List<dynamic>?> getRecentAudios({
    required String uri,
    required int weeks,
  }) async {
    return [];
  }

  @override
  Future<List<dynamic>?> getRecentStates({
    required String uri,
  }) async {
    return [];
  }

  @override
  Future<Uint8List?> getThumbnailBytes({
    required String uri,
    required bool isVideo,
  }) async {
    return null;
  }

  @override
  Future<String?> cacheFile({
    required String uri,
    required String fileName,
  }) async {
    return null;
  }

  @override
  Future<bool?> getDirectoryPermission(String path) async {
    return true;
  }
}

class MethodChannelStorageRepository implements StorageRepository {
  static const _platform = MethodChannel('ghostplay/storage');

  @override
  Future<List<String>?> getPersistedPermissionDirectories() {
    return Saf.getPersistedPermissionDirectories();
  }

  @override
  Future<List<dynamic>?> getRecentAudios({
    required String uri,
    required int weeks,
  }) {
    return _platform.invokeMethod<List<dynamic>>(
      'getRecentAudios',
      {
        'uri': uri,
        'weeks': weeks,
      },
    );
  }

  @override
  Future<List<dynamic>?> getRecentStates({
    required String uri,
  }) {
    return _platform.invokeMethod<List<dynamic>>(
      'getRecentStates',
      {
        'uri': uri,
      },
    );
  }

  @override
  Future<Uint8List?> getThumbnailBytes({
    required String uri,
    required bool isVideo,
  }) {
    return _platform.invokeMethod<Uint8List>(
      'getThumbnailBytes',
      {
        'uri': uri,
        'isVideo': isVideo,
      },
    );
  }

  @override
  Future<String?> cacheFile({
    required String uri,
    required String fileName,
  }) {
    return _platform.invokeMethod<String>(
      'cacheFile',
      {
        'uri': uri,
        'fileName': fileName,
      },
    );
  }

  @override
  Future<bool?> getDirectoryPermission(String path) {
    final saf = Saf(path);
    return saf.getDirectoryPermission(grantWritePermission: false);
  }
}
