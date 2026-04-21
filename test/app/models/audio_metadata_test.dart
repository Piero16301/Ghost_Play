import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_play/app/app.dart';

void main() {
  group('AudioMetadata', () {
    final date = DateTime(2023, 10, 27, 10, 30);
    final audio = AudioMetadata(
      uri: 'uri1',
      name: 'name1',
      date: date,
      sizeBytes: 1024 * 1024 * 2,
      durationMs: 125000,
    );

    test('supports value equality', () {
      final audio2 = AudioMetadata(
        uri: 'uri1',
        name: 'name1',
        date: date,
        sizeBytes: 1024 * 1024 * 2,
        durationMs: 125000,
      );
      expect(audio, equals(audio2));
    });

    test('fromMap creates correct instance', () {
      final map = {
        'uri': 'uri1',
        'name': 'name1',
        'date': date.millisecondsSinceEpoch,
        'size': 2097152,
        'duration': 125000,
      };
      final fromMap = AudioMetadata.fromMap(map);
      expect(fromMap, equals(audio));
    });

    test('fromMap use defaults for empty map', () {
      final fromMap = AudioMetadata.fromMap(const {});
      expect(fromMap.uri, '');
      expect(fromMap.name, '');
      expect(fromMap.sizeBytes, 0);
      expect(fromMap.durationMs, 0);
      expect(fromMap.date, isA<DateTime>());
    });

    test('toMap returns correct map', () {
      final map = audio.toMap();
      expect(map['uri'], 'uri1');
      expect(map['name'], 'name1');
      expect(map['date'], date.millisecondsSinceEpoch);
      expect(map['size'], 1024 * 1024 * 2);
      expect(map['duration'], 125000);
    });

    test('empty static instance is valid', () {
      final empty = AudioMetadata.empty;
      expect(empty.uri, '');
      expect(empty.name, '');
      expect(empty.sizeBytes, 0);
      expect(empty.durationMs, 0);
    });

    test('formattedDuration returns correct string', () {
      expect(audio.formattedDuration, '02:05');

      final audioShort = AudioMetadata(
        uri: '',
        name: '',
        date: DateTime.now(),
        sizeBytes: 0,
        durationMs: 5000,
      );
      expect(audioShort.formattedDuration, '00:05');
    });

    group('formattedSize', () {
      test('returns bytes', () {
        final a = AudioMetadata(
          uri: '',
          name: '',
          date: DateTime.now(),
          sizeBytes: 500,
          durationMs: 0,
        );
        expect(a.formattedSize, '500 B');
      });

      test('returns KB', () {
        final a = AudioMetadata(
          uri: '',
          name: '',
          date: DateTime.now(),
          sizeBytes: 1024 * 5,
          durationMs: 0,
        );
        expect(a.formattedSize, '5.00 KB');
      });

      test('returns MB', () {
        final a = AudioMetadata(
          uri: '',
          name: '',
          date: DateTime.now(),
          sizeBytes: 1024 * 1024 * 5,
          durationMs: 0,
        );
        expect(a.formattedSize, '5.00 MB');
      });

      test('returns GB', () {
        final a = AudioMetadata(
          uri: '',
          name: '',
          date: DateTime.now(),
          sizeBytes: 1024 * 1024 * 1024 * 5,
          durationMs: 0,
        );
        expect(a.formattedSize, '5.00 GB');
      });
    });
  });
}
