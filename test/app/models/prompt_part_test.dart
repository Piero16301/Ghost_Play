import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_play/app/app.dart';

void main() {
  group('PromptPart', () {
    test('primary const constructor sets all fields', () {
      const part = PromptPart(
        type: PromptPartType.text,
        text: 'hello',
        mimeType: 'text/plain',
      );

      expect(part.type, PromptPartType.text);
      expect(part.text, 'hello');
      expect(part.mimeType, 'text/plain');
      expect(part.bytes, isNull);
    });

    test('text constructor sets text fields', () {
      final part = PromptPart.text(text: 'hello');

      expect(part.type, PromptPartType.text);
      expect(part.text, 'hello');
      expect(part.mimeType, isNull);
      expect(part.bytes, isNull);
    });

    test('file constructor sets mimeType and bytes', () {
      final bytes = Uint8List.fromList([1, 2, 3]);
      final part = PromptPart.file(mimeType: 'audio/ogg', bytes: bytes);

      expect(part.type, PromptPartType.file);
      expect(part.mimeType, 'audio/ogg');
      expect(part.bytes, bytes);
      expect(part.text, isNull);
    });
  });

  group('PromptPartType', () {
    test('isText and isFile return expected values', () {
      expect(PromptPartType.text.isText, isTrue);
      expect(PromptPartType.text.isFile, isFalse);
      expect(PromptPartType.file.isText, isFalse);
      expect(PromptPartType.file.isFile, isTrue);
    });
  });
}
