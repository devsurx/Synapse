import 'openrouter_service.dart';

/// Legacy name kept so old imports don't break.
/// Now backed by OpenRouter instead of Google Gemini.
class GeminiService {
  Future<String> getStudyHelp(String prompt) async {
    try {
      final apiKey = await OpenRouterService.getApiKey();
      if (apiKey.isEmpty) {
        return "APOLOGY: No OpenRouter API key found. Please add one in Settings.";
      }
      return await OpenRouterService.generateText(prompt, apiKey: apiKey);
    } catch (e) {
      // This is where your apology logic lives!
      return "APOLOGY: I'm currently overwhelmed by all the new growth. Please give me a moment to rest and try again later!";
    }
  }
}
