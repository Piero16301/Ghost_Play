import 'dart:io';

import 'package:flutter/services.dart';
import 'package:saf/saf.dart';

abstract class StorageRepository {
  Future<List<String>?> getPersistedPermissionDirectories();
  Future<List<dynamic>?> getRecentAudios({
    required String uri,
    required int weeks,
  });
  Future<List<dynamic>?> getRecentStates({required String uri});
  Future<List<dynamic>?> getRecentVideos({
    required String uri,
    required int weeks,
  });
  Future<Uint8List?> getThumbnailBytes({
    required String uri,
    required bool isVideo,
  });
  Future<String?> cacheFile({required String uri, required String fileName});
  Future<bool?> getDirectoryPermission(String path);
}

class MockStorageRepository implements StorageRepository {
  @override
  Future<List<String>?> getPersistedPermissionDirectories() async {
    return ['mock://whatsapp/voice_notes'];
  }

  @override
  Future<List<dynamic>?> getRecentAudios({
    required String uri,
    required int weeks,
  }) async {
    final now = DateTime.now();
    final cutoff = now.subtract(Duration(days: weeks * 7));

    final mockAudios = <Map<String, dynamic>>[
      {
        'uri': 'asset:///mocks/audios/PTT-20230313-WA0015.opus',
        'name': 'PTT-20230313-WA0015.opus',
        'date': now.subtract(const Duration(hours: 2)).millisecondsSinceEpoch,
        'size': 50880,
        'duration': 8000,
      },
      {
        'uri': 'asset:///mocks/audios/PTT-20230314-WA0003.opus',
        'name': 'PTT-20230314-WA0003.opus',
        'date': now.subtract(const Duration(days: 1)).millisecondsSinceEpoch,
        'size': 104562,
        'duration': 15000,
      },
      {
        'uri': 'asset:///mocks/audios/PTT-20230315-WA0018.opus',
        'name': 'PTT-20230315-WA0018.opus',
        'date': now.subtract(const Duration(days: 2)).millisecondsSinceEpoch,
        'size': 216160,
        'duration': 28000,
      },
      {
        'uri': 'asset:///mocks/audios/PTT-20230316-WA0040.opus',
        'name': 'PTT-20230316-WA0040.opus',
        'date': now.subtract(const Duration(days: 3)).millisecondsSinceEpoch,
        'size': 254857,
        'duration': 34000,
      },
      {
        'uri': 'asset:///mocks/audios/PTT-20250101-WA0045.opus',
        'name': 'PTT-20250101-WA0045.opus',
        'date': now.subtract(const Duration(days: 4)).millisecondsSinceEpoch,
        'size': 33430,
        'duration': 5000,
      },
      {
        'uri': 'asset:///mocks/audios/PTT-20250102-WA0000.opus',
        'name': 'PTT-20250102-WA0000.opus',
        'date': now.subtract(const Duration(days: 5)).millisecondsSinceEpoch,
        'size': 187107,
        'duration': 24000,
      },
    ];

    return mockAudios.where((audio) {
      final date = DateTime.fromMillisecondsSinceEpoch(audio['date'] as int);
      return date.isAfter(cutoff);
    }).toList();
  }

  @override
  Future<List<dynamic>?> getRecentStates({required String uri}) async {
    final now = DateTime.now();

    return <Map<String, dynamic>>[
      {
        'uri': 'asset:///mocks/stories/03c1c7a36b554be8b06d3bf36f143a23.mp4',
        'name': '03c1c7a36b554be8b06d3bf36f143a23.mp4',
        'date': now.subtract(const Duration(hours: 2)).millisecondsSinceEpoch,
        'size': 1154829,
        'is_video': true,
        'duration': 7633,
      },
      {
        'uri': 'asset:///mocks/stories/07aba597c33349cd884c6694e71b3cdb.jpg',
        'name': '07aba597c33349cd884c6694e71b3cdb.jpg',
        'date': now.subtract(const Duration(hours: 5)).millisecondsSinceEpoch,
        'size': 160184,
        'is_video': false,
        'duration': 0,
      },
      {
        'uri': 'asset:///mocks/stories/79d653525fc34590adb611a7efe62c7a.jpg',
        'name': '79d653525fc34590adb611a7efe62c7a.jpg',
        'date': now.subtract(const Duration(hours: 9)).millisecondsSinceEpoch,
        'size': 81360,
        'is_video': false,
        'duration': 0,
      },
      {
        'uri': 'asset:///mocks/stories/e1843491c5a04da9af223632a7b328b0.mp4',
        'name': 'e1843491c5a04da9af223632a7b328b0.mp4',
        'date': now.subtract(const Duration(hours: 14)).millisecondsSinceEpoch,
        'size': 5523495,
        'is_video': true,
        'duration': 23043,
      },
    ];
  }

  @override
  Future<List<dynamic>?> getRecentVideos({
    required String uri,
    required int weeks,
  }) async {
    final now = DateTime.now();
    final cutoff = now.subtract(Duration(days: weeks * 7));

    final mockVideos = <Map<String, dynamic>>[
      {
        'uri': 'asset:///mocks/videos/PTV-20261113-WA0046.mp4',
        'name': 'PTV-20261113-WA0046.mp4',
        'date': now.subtract(const Duration(days: 1)).millisecondsSinceEpoch,
        'size': 6723365,
        'is_video': true,
        'duration': 35866,
      },
      {
        'uri': 'asset:///mocks/videos/PTV-20261103-WA0054.mp4',
        'name': 'PTV-20261103-WA0054.mp4',
        'date': now.subtract(const Duration(days: 4)).millisecondsSinceEpoch,
        'size': 5034867,
        'is_video': true,
        'duration': 26795,
      },
    ];

    return mockVideos.where((video) {
      final date = DateTime.fromMillisecondsSinceEpoch(video['date'] as int);
      return date.isAfter(cutoff);
    }).toList();
  }

  @override
  Future<Uint8List?> getThumbnailBytes({
    required String uri,
    required bool isVideo,
  }) async {
    try {
      final assetPath = uri.replaceFirst('asset:///', '');
      if (!isVideo) {
        final data = await rootBundle.load(assetPath);
        return data.buffer.asUint8List();
      }

      final fileName = assetPath.split('/').last;
      final dotIndex = fileName.lastIndexOf('.');
      final baseName = dotIndex != -1
          ? fileName.substring(0, dotIndex)
          : fileName;
      final thumbData = await rootBundle.load('mocks/thumbnails/$baseName.jpg');
      return thumbData.buffer.asUint8List();
    } on Object {
      return null;
    }
  }

  @override
  Future<String?> cacheFile({
    required String uri,
    required String fileName,
  }) async {
    try {
      final assetPath = uri.replaceFirst('asset:///', '');
      final data = await rootBundle.load(assetPath);
      final file = File('${Directory.systemTemp.path}/$fileName');
      await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
      return file.path;
    } on Object {
      return null;
    }
  }

  @override
  Future<bool?> getDirectoryPermission(String path) async {
    return true;
  }
}

class MethodChannelStorageRepository implements StorageRepository {
  static const _platform = MethodChannel('ghostplay/storage');

  @override
  Future<List<String>?> getPersistedPermissionDirectories() async {
    final permissions = await Saf().persistedPermissions();
    return permissions.map((p) => p.uri).toList();
  }

  @override
  Future<List<dynamic>?> getRecentAudios({
    required String uri,
    required int weeks,
  }) {
    return _platform.invokeMethod<List<dynamic>>('getRecentAudios', {
      'uri': uri,
      'weeks': weeks,
    });
  }

  @override
  Future<List<dynamic>?> getRecentStates({required String uri}) {
    return _platform.invokeMethod<List<dynamic>>('getRecentStates', {
      'uri': uri,
    });
  }

  @override
  Future<List<dynamic>?> getRecentVideos({
    required String uri,
    required int weeks,
  }) {
    return _platform.invokeMethod<List<dynamic>>('getRecentVideos', {
      'uri': uri,
      'weeks': weeks,
    });
  }

  @override
  Future<Uint8List?> getThumbnailBytes({
    required String uri,
    required bool isVideo,
  }) {
    return _platform.invokeMethod<Uint8List>('getThumbnailBytes', {
      'uri': uri,
      'isVideo': isVideo,
    });
  }

  @override
  Future<String?> cacheFile({required String uri, required String fileName}) {
    return _platform.invokeMethod<String>('cacheFile', {
      'uri': uri,
      'fileName': fileName,
    });
  }

  @override
  Future<bool?> getDirectoryPermission(String path) async {
    final picked = await Saf().pickDirectory(
      initialUri: path,
      writePermission: false,
    );
    return picked != null;
  }
}
