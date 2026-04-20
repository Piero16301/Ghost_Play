import 'package:equatable/equatable.dart';

/// {@template audio_metadata}
/// A class that represents the metadata of an audio file.
/// {@endtemplate}
class AudioMetadata extends Equatable {
  // {@macro audio_metadata}
  const AudioMetadata({
    required this.uri,
    required this.name,
    required this.date,
    required this.sizeBytes,
    required this.durationMs,
  });

  /// Creates an instance of [AudioMetadata] from a [Map]
  factory AudioMetadata.fromMap(Map<String, dynamic> map) {
    return AudioMetadata(
      uri: map['uri'] as String? ?? '',
      name: map['name'] as String? ?? '',
      date: DateTime.fromMillisecondsSinceEpoch(
        map['date'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      ),
      sizeBytes: map['size'] as int? ?? 0,
      durationMs: map['duration'] as int? ?? 0,
    );
  }

  /// Creates a [Map] from an instance of [AudioMetadata]
  Map<String, dynamic> toMap() {
    return {
      'uri': uri,
      'name': name,
      'date': date.millisecondsSinceEpoch,
      'size': sizeBytes,
      'duration': durationMs,
    };
  }

  /// An empty instance of [AudioMetadata]
  static final empty = AudioMetadata(
    uri: '',
    name: '',
    date: DateTime.now(),
    sizeBytes: 0,
    durationMs: 0,
  );

  /// Get formatted duration of the audio file
  String get formattedDuration {
    final duration = Duration(milliseconds: durationMs);
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// Get formatted size of the audio file
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

  /// Uri of the audio file
  final String uri;

  /// Name of the audio file
  final String name;

  /// Date of the audio file
  final DateTime date;

  /// Size of the audio file in bytes
  final int sizeBytes;

  /// Duration of the audio file in milliseconds
  final int durationMs;

  @override
  List<Object?> get props => [
    uri,
    name,
    date,
    sizeBytes,
    durationMs,
  ];
}
