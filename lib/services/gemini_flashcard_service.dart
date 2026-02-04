import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';

class FlashcardService {
  static const String _apiKey = "AIzaSyCAnahv3xdlsl5Gc4lrxYYoCyR74tke2NI";

  static Future<List<Map<String, String>>> generateFlashcards(
    String pdfText,
  ) async {
    final model = GenerativeModel(
      model: 'gemini-2.5-flash-lite',
      apiKey: _apiKey,
      // Adding generationConfig helps stabilize the response for flashcards
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 2048,
      ),
    );

    // STRICT SYSTEM PROMPT
    final prompt =
        """
    You are an expert academic tutor. Based ONLY on the following text provided from a PDF, 
    generate 8 high-quality flashcards for active recall.
    
    RULES:
    1. DO NOT use outside knowledge. 
    2. ONLY use information found in the text below.
    3. Format the response as a valid JSON list of objects with "front" and "back" keys.
    4. Keep questions (front) challenging and answers (back) concise.

    TEXT FROM PDF:
    $pdfText
    """;

    try {
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      // Extracting the JSON part from the response
      String cleanJson = response.text!
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      List<dynamic> decoded = jsonDecode(cleanJson);

      return decoded
          .map(
            (item) => {
              "front": item["front"].toString(),
              "back": item["back"].toString(),
            },
          )
          .toList();
    } catch (e) {
      print("Error generating cards: $e");
      return [
        {
          "front": "Error",
          "back": "Failed to generate cards. Please try again.",
        },
      ];
    }
  }
}
