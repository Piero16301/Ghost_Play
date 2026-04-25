import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_play/app/models/multimedia_metadata.dart';

void main() {
  group('MultimediaMetadata', () {
    final date = DateTime(2023, 10, 27, 10, 30);
    final state = MultimediaMetadata(
      uri: 'uri1',
      name: 'name1',
      date: date,
      sizeBytes: 1024 * 1024 * 2,
      isVideo: true,
      videoDurationMs: 125000,
    );

    test('supports value equality', () {
      final state2 = MultimediaMetadata(
        uri: 'uri1',
        name: 'name1',
        date: date,
        sizeBytes: 1024 * 1024 * 2,
        isVideo: true,
        videoDurationMs: 125000,
      );
      expect(state, equals(state2));
    });

    test('fromMap creates correct instance', () {
      final map = {
        'uri': 'uri1',
        'name': 'name1',
        'date': date.millisecondsSinceEpoch,
        'size': 2097152,
        'is_video': true,
        'duration': 125000,
      };
      final fromMap = MultimediaMetadata.fromMap(map);
      expect(fromMap, equals(state));
    });

    test('fromMap use defaults for empty map', () {
      final fromMap = MultimediaMetadata.fromMap(const {});
      expect(fromMap.uri, '');
      expect(fromMap.name, '');
      expect(fromMap.sizeBytes, 0);
      expect(fromMap.isVideo, false);
      expect(fromMap.videoDurationMs, 0);
      expect(fromMap.date, isA<DateTime>());
    });

    test('toMap returns correct map', () {
      final map = state.toMap();
      expect(map['uri'], 'uri1');
      expect(map['name'], 'name1');
      expect(map['date'], date.millisecondsSinceEpoch);
      expect(map['size'], 1024 * 1024 * 2);
      expect(map['isVideo'], true);
      expect(map['duration'], 125000);
    });

    test('empty static instance is valid', () {
      final empty = MultimediaMetadata.empty;
      expect(empty.uri, '');
      expect(empty.name, '');
      expect(empty.sizeBytes, 0);
      expect(empty.isVideo, false);
      expect(empty.videoDurationMs, 0);
    });

    group('formattedDuration', () {
      test('returns empty string if not video', () {
        final nonVideo = MultimediaMetadata(
          uri: '',
          name: '',
          date: DateTime.now(),
          sizeBytes: 0,
          isVideo: false,
        );
        expect(nonVideo.formattedDuration, '');
      });

      test('returns mm:ss for short video', () {
        final video = MultimediaMetadata(
          uri: '',
          name: '',
          date: DateTime.now(),
          sizeBytes: 0,
          isVideo: true,
          videoDurationMs: 65000,
        );
        expect(video.formattedDuration, '01:05');
      });

      test('returns hh:mm:ss for long video', () {
        final video = MultimediaMetadata(
          uri: '',
          name: '',
          date: DateTime.now(),
          sizeBytes: 0,
          isVideo: true,
          videoDurationMs: 3665000,
        );
        expect(video.formattedDuration, '01:01:05');
      });
    });

    group('formattedSize', () {
      test('returns bytes', () {
        final s = MultimediaMetadata(
          uri: '',
          name: '',
          date: DateTime.now(),
          sizeBytes: 500,
          isVideo: false,
        );
        expect(s.formattedSize, '500 B');
      });

      test('returns KB', () {
        final s = MultimediaMetadata(
          uri: '',
          name: '',
          date: DateTime.now(),
          sizeBytes: 1024 * 5,
          isVideo: false,
        );
        expect(s.formattedSize, '5.00 KB');
      });

      test('returns MB', () {
        final s = MultimediaMetadata(
          uri: '',
          name: '',
          date: DateTime.now(),
          sizeBytes: 1024 * 1024 * 5,
          isVideo: false,
        );
        expect(s.formattedSize, '5.00 MB');
      });

      test('returns GB', () {
        final s = MultimediaMetadata(
          uri: '',
          name: '',
          date: DateTime.now(),
          sizeBytes: 1024 * 1024 * 1024 * 5,
          isVideo: false,
        );
        expect(s.formattedSize, '5.00 GB');
      });
    });
  });
}
