import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class FlashcardService {
  // --- SECURE API KEY LOGIC ---
  // No more hardcoded keys! This pulls from the --define flag during build/run.
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');

  /// Generates flashcards from PDF text.
  /// Throws specific "APOLOGY" strings if something goes wrong.
  static Future<List<Map<String, String>>> generateFlashcards(
    String pdfText,
  ) async {
    // Safety check for the developer
    if (_apiKey.isEmpty) {
      debugPrint(
        "SECURE ERROR: No API Key found for FlashcardService. Run with --define=GEMINI_API_KEY=your_key",
      );
      throw "CONFIG_ERROR";
    }

    final model = GenerativeModel(
      model: 'gemini-3-flash-preview',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 2048,
      ),
    );

    // SYSTEM PROMPT
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

      if (response.text == null || response.text!.isEmpty) {
        throw "EMPTY_RESPONSE";
      }

      // Clean the response (remove Markdown JSON blocks if present)
      String cleanJson = response.text!
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      // Parse JSON
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
      // LOGIC: Convert technical errors into friendly constants for the UI
      String errorStr = e.toString().toLowerCase();

      if (errorStr.contains('429') || errorStr.contains('quota')) {
        // UI will catch this and show: "I'm a bit overwhelmed... give me a minute to catch my breath."
        throw "LIMIT_REACHED";
      } else if (errorStr.contains('network') || errorStr.contains('socket')) {
        // UI will catch this and show: "Mind checking your internet?"
        throw "OFFLINE";
      } else {
        debugPrint("Flashcard Service Error: $e");
        throw "GENERAL_FAILURE";
      }
    }
  }
}
