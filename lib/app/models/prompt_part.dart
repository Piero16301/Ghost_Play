import 'dart:typed_data';

class PromptPart {
  const new({required this.type, this.text, this.mimeType, this.bytes});

  new text({required String text})
    : this(type: PromptPartType.text, text: text);

  new file({required String mimeType, required Uint8List bytes})
    : this(type: PromptPartType.file, mimeType: mimeType, bytes: bytes);

  final PromptPartType type;
  final String? text;
  final String? mimeType;
  final Uint8List? bytes;
}

enum PromptPartType {
  text,
  file;

  bool get isText => this == PromptPartType.text;
  bool get isFile => this == PromptPartType.file;
}
