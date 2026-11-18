import 'dart:convert';

import 'package:equatable/equatable.dart';

class TranscriptionMetadata extends Equatable {
  const new({required this.text, required this.timestamp});

  factory fromMap(Map<String, dynamic> map) {
    return TranscriptionMetadata(
      text: map['text'] as String? ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        map['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  factory fromJson(String source) =>
      TranscriptionMetadata.fromMap(jsonDecode(source) as Map<String, dynamic>);

  Map<String, dynamic> toMap() {
    return {'text': text, 'timestamp': timestamp.millisecondsSinceEpoch};
  }

  String toJson() => jsonEncode(toMap());

  final String text;
  final DateTime timestamp;

  @override
  List<Object?> get props => [text, timestamp];
}
