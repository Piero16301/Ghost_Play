import 'dart:async';
import 'dart:typed_data';

import 'package:ghost_play/app/app.dart';

class StorageService {
  new({required this._storageRepository});

  final StorageRepository _storageRepository;
  final Map<String, Uint8List> _thumbnailCache = {};
  final Map<String, Future<Uint8List?>> _pendingThumbnails = {};

  Uint8List? getCachedThumbnail(String uri) => _thumbnailCache[uri];

  Future<List<String>?> getPersistedPermissionDirectories() {
    return _storageRepository.getPersistedPermissionDirectories();
  }

  Future<List<dynamic>?> getRecentAudios({
    required String uri,
    required int weeks,
  }) {
    return _storageRepository.getRecentAudios(uri: uri, weeks: weeks);
  }

  Future<List<dynamic>?> getRecentStates({required String uri}) {
    return _storageRepository.getRecentStates(uri: uri);
  }

  Future<List<dynamic>?> getRecentVideos({
    required String uri,
    required int weeks,
  }) {
    return _storageRepository.getRecentVideos(uri: uri, weeks: weeks);
  }

  Future<Uint8List?> getThumbnailBytes({
    required String uri,
    required bool isVideo,
  }) {
    final cached = _thumbnailCache[uri];
    if (cached != null) {
      return Future.value(cached);
    }

    return _pendingThumbnails.putIfAbsent(uri, () async {
      try {
        final bytes = await _storageRepository.getThumbnailBytes(
          uri: uri,
          isVideo: isVideo,
        );
        if (bytes != null) {
          _thumbnailCache[uri] = bytes;
        }
        return bytes;
      } finally {
        unawaited(_pendingThumbnails.remove(uri));
      }
    });
  }

  Future<String?> cacheFile({required String uri, required String fileName}) {
    return _storageRepository.cacheFile(uri: uri, fileName: fileName);
  }

  Future<bool?> getDirectoryPermission(String path) {
    return _storageRepository.getDirectoryPermission(path);
  }
}
