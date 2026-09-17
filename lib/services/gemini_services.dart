import 'openai_service.dart';

/// Legacy name kept so old imports don't break.
/// Now backed by OpenAI instead of Google Gemini.
class GeminiService {
  Future<String> getStudyHelp(String prompt) async {
    try {
      final apiKey = await OpenAIService.getApiKey();
      if (apiKey.isEmpty) {
        return "APOLOGY: No OpenAI API key found. Please add one in Settings.";
      }
      return await OpenAIService.generateText(prompt, apiKey: apiKey);
    } catch (e) {
      // This is where your apology logic lives!
      return "APOLOGY: I'm currently overwhelmed by all the new growth. Please give me a moment to rest and try again later!";
    }
  }
}
