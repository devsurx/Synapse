import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Centralized OpenAI integration for the app.
///
/// Stores the key under `openai_api_key` (with automatic one-time migration
/// from the legacy `gemini_api_key` preference) and talks to the
/// OpenAI Chat Completions API via the existing `http` package so no
/// additional SDK dependency is required.
class OpenAIService {
  static const String apiKeyPrefsKey = 'openai_api_key';

  /// Legacy key kept for migration only.
  static const String _legacyPrefsKey = 'gemini_api_key';

  /// Default model. gpt-4o-mini is cheap, fast, and good for tutoring,
  /// planning, flashcards, quizzes and OCR cleanup.
  static const String defaultModel = 'gpt-4o-mini';

  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';

  /// Reads the stored OpenAI key, migrating the old Gemini preference if
  /// present so existing users don't lose their setup (they will still need
  /// to replace a Gemini key with an OpenAI key).
  static Future<String> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    String key = prefs.getString(apiKeyPrefsKey) ?? '';
    if (key.isEmpty) {
      final legacy = prefs.getString(_legacyPrefsKey) ?? '';
      if (legacy.isNotEmpty) {
        // Don't auto-copy a Gemini key (it won't work with OpenAI),
        // just surface it so the UI can hint the user to replace it.
        // We intentionally do NOT persist it as the OpenAI key.
        key = '';
      }
    }
    return key.trim();
  }

  static Future<void> saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(apiKeyPrefsKey, key.trim());
  }

  /// Low-level chat completion call.
  ///
  /// [messages] must be a list of {"role": ..., "content": ...} maps.
  /// Throws a categorized [Exception] with one of:
  /// INVALID_KEY, LIMIT_REACHED, SERVER_OVERLOAD, or the raw message.
  static Future<String> chatCompletion({
    required String apiKey,
    required List<Map<String, String>> messages,
    String model = defaultModel,
    bool jsonMode = false,
    double temperature = 0.7,
    int maxTokens = 2000,
  }) async {
    final trimmedKey = apiKey.trim();
    if (trimmedKey.isEmpty) {
      throw Exception('INVALID_KEY');
    }

    final body = <String, dynamic>{
      'model': model,
      'messages': messages,
      'temperature': temperature,
      'max_tokens': maxTokens,
    };
    if (jsonMode) {
      body['response_format'] = {'type': 'json_object'};
    }

    http.Response response;
    try {
      response = await http
          .post(
            Uri.parse(_baseUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $trimmedKey',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 60));
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('timeout')) throw Exception('SERVER_OVERLOAD');
      rethrow;
    }

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final content =
          decoded['choices']?[0]?['message']?['content']?.toString() ?? '';
      if (content.trim().isEmpty) throw Exception('AI_SILENCE');
      return content.trim();
    }

    final status = response.statusCode;
    final bodyStr = response.body.toLowerCase();
    if (status == 401 || bodyStr.contains('incorrect api key')) {
      throw Exception('INVALID_KEY');
    } else if (status == 429 ||
        bodyStr.contains('rate limit') ||
        bodyStr.contains('quota') ||
        bodyStr.contains('insufficient_quota')) {
      throw Exception('LIMIT_REACHED');
    } else if (status >= 500 || status == 503) {
      throw Exception('SERVER_OVERLOAD');
    } else if (status == 400 && bodyStr.contains('model')) {
      throw Exception('MODEL_ERROR');
    }
    throw Exception('OPENAI_ERROR_$status');
  }

  /// Single-turn text generation helper (drop-in replacement for
  /// `GenerativeModel.generateContent([Content.text(prompt)])`).
  static Future<String> generateText(
    String prompt, {
    required String apiKey,
    String? systemInstruction,
    String model = defaultModel,
    double temperature = 0.7,
    int maxTokens = 2000,
    int retries = 1,
  }) async {
    final messages = <Map<String, String>>[
      if (systemInstruction != null && systemInstruction.trim().isNotEmpty)
        {'role': 'system', 'content': systemInstruction.trim()},
      {'role': 'user', 'content': prompt},
    ];
    return _withRetry(
      () => chatCompletion(
        apiKey: apiKey,
        messages: messages,
        model: model,
        temperature: temperature,
        maxTokens: maxTokens,
      ),
      retries: retries,
    );
  }

  /// JSON-mode helper. Instructs the model to return valid JSON and strips
  /// any markdown fences before decoding.
  static Future<dynamic> generateJson(
    String prompt, {
    required String apiKey,
    String? systemInstruction,
    String model = defaultModel,
    double temperature = 0.3,
    int maxTokens = 2000,
    int retries = 1,
  }) async {
    final raw = await _withRetry(
      () => chatCompletion(
        apiKey: apiKey,
        messages: [
          if (systemInstruction != null && systemInstruction.trim().isNotEmpty)
            {'role': 'system', 'content': systemInstruction.trim()},
          {'role': 'user', 'content': prompt},
        ],
        model: model,
        jsonMode: true,
        temperature: temperature,
        maxTokens: maxTokens,
      ),
      retries: retries,
    );
    return jsonDecode(_stripCodeFences(raw));
  }

  static String _stripCodeFences(String text) {
    var t = text.trim();
    t = t.replaceAll('```json', '').replaceAll('```', '').trim();
    return t;
  }

  static Future<T> _withRetry<T>(
    Future<T> Function() fn, {
    int retries = 1,
  }) async {
    try {
      return await fn();
    } catch (e) {
      final msg = e.toString();
      final isTransient = msg.contains('SERVER_OVERLOAD') ||
          msg.contains('503') ||
          msg.contains('500') ||
          msg.contains('Timeout');
      if (retries > 0 && isTransient) {
        await Future.delayed(const Duration(seconds: 2));
        return _withRetry(fn, retries: retries - 1);
      }
      rethrow;
    }
  }
}
