import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';

class FlashcardService {
  static Future<List<Map<String, String>>> generateFlashcards(
    String pdfText,
    String apiKey,
  ) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-3-flash-preview',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
        ),
      );

      final safeText = pdfText.length > 7000
          ? pdfText.substring(0, 7000)
          : pdfText;

      final prompt =
          '''
        Return a JSON array of 5-8 flashcards from this text. 
        Format: [{"front": "...", "back": "..."}]
        TEXT: $safeText
      ''';

      // --- RETRY LOGIC FOR 503 ---
      GenerateContentResponse response;
      try {
        response = await model.generateContent([Content.text(prompt)]);
      } catch (e) {
        if (e.toString().contains('503')) {
          // Wait 2 seconds and try one more time
          await Future.delayed(const Duration(seconds: 2));
          response = await model.generateContent([Content.text(prompt)]);
        } else {
          rethrow;
        }
      }
      // ---------------------------

      final rawText = response.text;
      if (rawText == null || rawText.isEmpty) throw Exception("AI_SILENCE");

      final List<dynamic> decoded = jsonDecode(rawText);
      return decoded
          .map(
            (item) => {
              "front": item["front"]?.toString() ?? "N/A",
              "back": item["back"]?.toString() ?? "N/A",
            },
          )
          .toList();
    } catch (e) {
      final errorStr = e.toString();

      // Categorize the errors for the UI
      if (errorStr.contains('429')) {
        throw Exception("LIMIT_REACHED");
      } else if (errorStr.contains('503')) {
        throw Exception("SERVER_OVERLOAD");
      } else if (errorStr.contains('403') || errorStr.contains('400')) {
        throw Exception("INVALID_KEY");
      }

      rethrow;
    }
  }
}
