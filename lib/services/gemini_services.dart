import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  // Replace with your actual key or use a .env file
  static const String _apiKey = 'AIzaSyCAnahv3xdlsl5Gc4lrxYYoCyR74tke2NI';

  final GenerativeModel _model;

  GeminiService()
    : _model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: _apiKey);

  Future<String> getStudyHelp(String prompt) async {
    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      return response.text ?? "The garden is quiet right now. Try again?";
    } catch (e) {
      // This is where your apology logic lives!
      return "APOLOGY: I'm currently overwhelmed by all the new growth. Please give me a moment to rest and try again later!";
    }
  }
}
