import 'dart:typed_data';

import 'package:ghost_play/app/app.dart';

class StorageService {
  StorageService({required this._storageRepository});

  final StorageRepository _storageRepository;

  Future<List<String>?> getPersistedPermissionDirectories() {
    return _storageRepository.getPersistedPermissionDirectories();
  }

  Future<List<dynamic>?> getRecentAudios({
    required String uri,
    required int weeks,
  }) {
    return _storageRepository.getRecentAudios(
      uri: uri,
      weeks: weeks,
    );
  }

  Future<List<dynamic>?> getRecentStates({
    required String uri,
  }) {
    return _storageRepository.getRecentStates(
      uri: uri,
    );
  }

  Future<List<dynamic>?> getRecentVideos({
    required String uri,
    required int weeks,
  }) {
    return _storageRepository.getRecentVideos(
      uri: uri,
      weeks: weeks,
    );
  }

  Future<Uint8List?> getThumbnailBytes({
    required String uri,
    required bool isVideo,
  }) {
    return _storageRepository.getThumbnailBytes(
      uri: uri,
      isVideo: isVideo,
    );
  }

  Future<String?> cacheFile({
    required String uri,
    required String fileName,
  }) {
    return _storageRepository.cacheFile(
      uri: uri,
      fileName: fileName,
    );
  }

  Future<bool?> getDirectoryPermission(String path) {
    return _storageRepository.getDirectoryPermission(path);
  }
}
