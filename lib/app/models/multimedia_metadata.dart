import 'package:equatable/equatable.dart';

/// {@template multimedia_metadata}
/// A class that represents the metadata of a multimedia file.
/// {@endtemplate}
class MultimediaMetadata extends Equatable {
  // {@macro multimedia_metadata}
  const MultimediaMetadata({
    required this.uri,
    required this.name,
    required this.date,
    required this.sizeBytes,
    required this.isVideo,
    this.videoDurationMs = 0,
  });

  /// Creates an instance of [MultimediaMetadata] from a [Map]
  factory MultimediaMetadata.fromMap(Map<String, dynamic> map) {
    return MultimediaMetadata(
      uri: map['uri'] as String? ?? '',
      name: map['name'] as String? ?? '',
      date: DateTime.fromMillisecondsSinceEpoch(
        map['date'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      ),
      sizeBytes: map['size'] as int? ?? 0,
      isVideo: map['is_video'] as bool? ?? false,
      videoDurationMs: map['duration'] as int? ?? 0,
    );
  }

  /// Creates a [Map] from an instance of [MultimediaMetadata]
  Map<String, dynamic> toMap() {
    return {
      'uri': uri,
      'name': name,
      'date': date.millisecondsSinceEpoch,
      'size': sizeBytes,
      'isVideo': isVideo,
      'duration': videoDurationMs,
    };
  }

  /// An empty instance of [MultimediaMetadata]
  static final empty = MultimediaMetadata(
    uri: '',
    name: '',
    date: DateTime.now(),
    sizeBytes: 0,
    isVideo: false,
  );

  /// Get formatted duration of the multimedia file
  String get formattedDuration {
    if (isVideo) {
      final duration = Duration(milliseconds: videoDurationMs);
      final hours = duration.inHours.remainder(24).toString().padLeft(2, '0');
      final minutes = duration.inMinutes
          .remainder(60)
          .toString()
          .padLeft(2, '0');
      final seconds = duration.inSeconds
          .remainder(60)
          .toString()
          .padLeft(2, '0');
      if (hours != '00') {
        return '$hours:$minutes:$seconds';
      }
      return '$minutes:$seconds';
    }
    return '';
  }

  /// Get formatted size of the multimedia file
  String get formattedSize {
    if (sizeBytes < 1024) {
      return '$sizeBytes B';
    } else if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(2)} KB';
    } else if (sizeBytes < 1024 * 1024 * 1024) {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else {
      return '${(sizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }

  /// Uri of the multimedia file
  final String uri;

  /// Name of the multimedia file
  final String name;

  /// Date of the multimedia file
  final DateTime date;

  /// Size of the multimedia file in bytes
  final int sizeBytes;

  /// Whether the multimedia file is a video
  final bool isVideo;

  /// Duration of the multimedia file in milliseconds
  final int videoDurationMs;

  @override
  List<Object?> get props => [
    uri,
    name,
    date,
    sizeBytes,
    isVideo,
    videoDurationMs,
  ];
}
