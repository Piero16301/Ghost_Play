import 'package:firebase_ai/firebase_ai.dart';
import 'package:ghost_play/app/app.dart';

abstract class AiRepository {
  Future<String?> generateContentRemote({
    required String model,
    required String systemInstruction,
    required List<PromptPart> prompt,
    String responseMimeType = 'text/plain',
  });
}

class MockAiRepository implements AiRepository {
  @override
  Future<String?> generateContentRemote({
    required String model,
    required String systemInstruction,
    required List<PromptPart> prompt,
    String responseMimeType = 'text/plain',
  }) async => null;
}

class FirebaseAiRepository implements AiRepository {
  new({FirebaseAI? remoteModel}) : _remoteAi = remoteModel;

  final FirebaseAI? _remoteAi;

  @override
  Future<String?> generateContentRemote({
    required String model,
    required String systemInstruction,
    required List<PromptPart> prompt,
    String responseMimeType = 'text/plain',
  }) async {
    final parts = <Part>[
      for (final item in prompt)
        if (item.type.isText && item.text != null)
          TextPart(item.text!)
        else if (item.type.isFile && item.bytes != null)
          InlineDataPart(
            item.mimeType?.isNotEmpty == true ? item.mimeType! : 'image/jpeg',
            item.bytes!,
          ),
    ];

    if (parts.isEmpty) {
      return null;
    }

    final ai = _remoteAi ?? FirebaseAI.agentPlatform();

    final genModel = ai.generativeModel(
      model: model,
      systemInstruction: Content.system(systemInstruction),
      generationConfig: GenerationConfig(
        responseMimeType: responseMimeType,
        temperature: 0.1,
      ),
      safetySettings: [
        SafetySetting(
          HarmCategory.dangerousContent,
          HarmBlockThreshold.none,
          null,
        ),
      ],
    );

    final response = await genModel
        .generateContent([Content.multi(parts)])
        .timeout(AppVariables.aiTimeoutDuration);

    return response.text;
  }
}
