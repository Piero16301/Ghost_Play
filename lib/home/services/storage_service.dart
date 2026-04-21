import 'package:flutter/services.dart';
import 'package:saf/saf.dart';

abstract class StorageService {
  Future<List<String>?> getPersistedPermissionDirectories();
  Future<List<dynamic>?> getRecentAudios({
    required String uri,
    required int weeks,
  });
  Future<bool?> getDirectoryPermission(String path);
}

class MethodChannelStorageService implements StorageService {
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
  Future<bool?> getDirectoryPermission(String path) {
    final saf = Saf(path);
    return saf.getDirectoryPermission(grantWritePermission: false);
  }
}
