import 'dart:convert';
import 'openrouter_service.dart';

/// Legacy filename/class kept so existing imports don't break.
/// Now backed by OpenRouter instead of Google Gemini.
class FlashcardService {
  static Future<List<Map<String, String>>> generateFlashcards(
    String pdfText,
    String apiKey,
  ) async {
    try {
      final effectiveKey = apiKey.trim().isNotEmpty
          ? apiKey.trim()
          : await OpenRouterService.getApiKey();
      if (effectiveKey.isEmpty) throw Exception("INVALID_KEY");

      final safeText = pdfText.length > 7000
          ? pdfText.substring(0, 7000)
          : pdfText;

      final prompt =
          '''
Return a JSON array of 5-8 flashcards from this text.
Each item must have exactly these keys: "front" and "back".
Return ONLY the JSON array, no markdown, no extra text.
TEXT: $safeText
''';

      dynamic decoded;
      try {
        decoded = await OpenRouterService.generateJson(
          prompt,
          apiKey: effectiveKey,
          systemInstruction:
              'You generate study flashcards. Always return valid JSON only.',
        );
      } catch (e) {
        if (e.toString().contains('SERVER_OVERLOAD')) {
          // One extra retry for overloaded servers.
          await Future.delayed(const Duration(seconds: 2));
          decoded = await OpenRouterService.generateJson(
            prompt,
            apiKey: effectiveKey,
            systemInstruction:
                'You generate study flashcards. Always return valid JSON only.',
          );
        } else {
          rethrow;
        }
      }

      // OpenRouter JSON mode may return {"flashcards": [...]} — normalize both.
      List<dynamic> list;
      if (decoded is List) {
        list = decoded;
      } else if (decoded is Map && decoded['flashcards'] is List) {
        list = decoded['flashcards'] as List;
      } else if (decoded is Map) {
        // Single object fallback: try to find any list value.
        final found = decoded.values.whereType<List>().firstOrNull;
        if (found == null) throw Exception("AI_SILENCE");
        list = found;
      } else if (decoded is String) {
        list = jsonDecode(decoded) as List;
      } else {
        throw Exception("AI_SILENCE");
      }

      if (list.isEmpty) throw Exception("AI_SILENCE");

      return list
          .map(
            (item) => {
              "front": item["front"]?.toString() ?? "N/A",
              "back": item["back"]?.toString() ?? "N/A",
            },
          )
          .toList();
    } catch (e) {
      final errorStr = e.toString();
      if (errorStr.contains('LIMIT_REACHED') || errorStr.contains('429')) {
        throw Exception("LIMIT_REACHED");
      } else if (errorStr.contains('SERVER_OVERLOAD') ||
          errorStr.contains('503')) {
        throw Exception("SERVER_OVERLOAD");
      } else if (errorStr.contains('INVALID_KEY') ||
          errorStr.contains('401') ||
          errorStr.contains('403') ||
          errorStr.contains('400')) {
        throw Exception("INVALID_KEY");
      }
      rethrow;
    }
  }
}
