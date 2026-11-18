import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_play/app/app.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';

class _FakeHttpHeaders extends Fake implements HttpHeaders {
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}

  @override
  void forEach(void Function(String name, List<String> values) action) {}
}

class _FakeHttpClientResponse extends Fake implements HttpClientResponse {
  new(this._bytes);

  final List<int> _bytes;

  @override
  int get statusCode => HttpStatus.ok;

  @override
  int get contentLength => _bytes.length;

  @override
  bool get isRedirect => false;

  @override
  List<RedirectInfo> get redirects => const [];

  @override
  bool get persistentConnection => false;

  @override
  String get reasonPhrase => 'OK';

  @override
  HttpHeaders get headers => _FakeHttpHeaders();

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable([_bytes]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

class _FakeHttpClientRequest extends Fake implements HttpClientRequest {
  new(this._responseBytes);

  final List<int> _responseBytes;

  @override
  final HttpHeaders headers = _FakeHttpHeaders();

  @override
  bool followRedirects = true;

  @override
  int maxRedirects = 5;

  @override
  int contentLength = -1;

  @override
  bool persistentConnection = true;

  @override
  Future<void> addStream(Stream<List<int>> stream) async {
    await stream.drain<void>();
  }

  @override
  Future<HttpClientResponse> close() async =>
      _FakeHttpClientResponse(_responseBytes);
}

class _FakeHttpClient extends Fake implements HttpClient {
  new(this._responseBytes);

  final List<int> _responseBytes;

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async =>
      _FakeHttpClientRequest(_responseBytes);

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MockAiRepository', () {
    test('generateContentRemote returns null', () async {
      final repository = MockAiRepository();

      final result = await repository.generateContentRemote(
        model: 'gemini-3.5-flash-lite',
        systemInstruction: 'system',
        prompt: [PromptPart.text(text: 'hello')],
      );

      expect(result, isNull);
    });
  });

  group('FirebaseAiRepository', () {
    test('returns null when prompt is empty', () async {
      final repository = FirebaseAiRepository();

      final result = await repository.generateContentRemote(
        model: 'gemini-3.5-flash-lite',
        systemInstruction: 'system',
        prompt: const [],
      );

      expect(result, isNull);
    });

    test('returns null when prompt parts have no text or bytes', () async {
      final repository = FirebaseAiRepository();

      final result = await repository.generateContentRemote(
        model: 'gemini-3.5-flash-lite',
        systemInstruction: 'system',
        prompt: const [
          PromptPart(type: PromptPartType.text),
          PromptPart(type: PromptPartType.file),
        ],
      );

      expect(result, isNull);
    });

    test(
      'uses default FirebaseAI.agentPlatform when remoteModel omitted',
      () async {
        final repository = FirebaseAiRepository();

        try {
          await repository.generateContentRemote(
            model: 'gemini-3.5-flash-lite',
            systemInstruction: 'system',
            prompt: [PromptPart.text(text: 'hello')],
          );
        } on Object catch (_) {}
      },
    );

    test('generates content for text and file parts', () async {
      final app = MockFirebaseApp();
      when(() => app.name).thenReturn('test-ai-app');
      when(() => app.options).thenReturn(
        const FirebaseOptions(
          apiKey: 'k',
          appId: 'id',
          messagingSenderId: 's',
          projectId: 'p',
        ),
      );
      when(() => app.isAutomaticDataCollectionEnabled).thenReturn(false);

      final payload = jsonEncode({
        'candidates': [
          {
            'content': {
              'role': 'model',
              'parts': [
                {'text': 'transcribed result'},
              ],
            },
          },
        ],
      });
      final responseBytes = utf8.encode(payload);

      final firebaseAi = FirebaseAI.agentPlatform(app: app);
      final repository = FirebaseAiRepository(remoteModel: firebaseAi);

      final result = await HttpOverrides.runZoned(
        () => repository.generateContentRemote(
          model: 'gemini-3.5-flash-lite',
          systemInstruction: 'system',
          prompt: [
            PromptPart.text(text: 'transcribe'),
            PromptPart.file(
              mimeType: 'audio/ogg',
              bytes: Uint8List.fromList([1, 2]),
            ),
            PromptPart.file(mimeType: '', bytes: Uint8List.fromList([3, 4])),
          ],
        ),
        createHttpClient: (_) => _FakeHttpClient(responseBytes),
      );

      expect(result, 'transcribed result');
    });
  });
}
