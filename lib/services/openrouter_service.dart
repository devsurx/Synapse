import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Centralized OpenRouter integration for the app.
///
/// Stores the key under `openrouter_api_key` and talks to the
/// OpenRouter Chat Completions API (OpenAI-compatible) via the existing
/// `http` package so no additional SDK dependency is required.
///
/// NOTE: OpenRouter still requires an API key (`sk-or-v1-...`, free to
/// create at https://openrouter.ai/keys) for every request, free models
/// included. The default model below is a free one, so usage costs nothing.
class OpenRouterService {
  static const String apiKeyPrefsKey = 'openrouter_api_key';

  /// Default model. A free-tier model so studying costs nothing.
  /// Change this to any OpenRouter model id (e.g. 'openai/gpt-4o-mini')
  /// if you prefer a paid/faster model.
  static const String defaultModel =
      'meta-llama/llama-3.3-70b-instruct:free';

  static const String _baseUrl =
      'https://openrouter.ai/api/v1/chat/completions';

  // App-wide shared key, used when the user hasn't set a personal override
  // in Settings. Split into parts as a speed bump against trivial string
  // extraction — this is OBFUSCATION, NOT security. Anyone decompiling the
  // APK can still recover it. Keep the spend limit on this key at $0 in the
  // OpenRouter dashboard and never attach credits to it.
  static const String _k1 = 'sk-or-v1-c8ceda6a77c5';
  static const String _k2 = 'f192d6e9204ae64b9a038f506bd29';
  static const String _k3 = '619173fcdb55260e8ec1172';
  static String get _bundledKey => _k1 + _k2 + _k3;

  /// OpenRouter asks clients to identify themselves.
  static const Map<String, String> _appHeaders = {
    'HTTP-Referer': 'https://github.com/devsurx/Synapse',
    'X-Title': 'Synapse',
  };

  /// Returns the user's personal override if set, otherwise the bundled
  /// shared app key. Never returns empty as long as the bundled key exists.
  static Future<String> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final override = (prefs.getString(apiKeyPrefsKey) ?? '').trim();
    if (override.isNotEmpty) return override;
    return _bundledKey;
  }

  static Future<void> saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(apiKeyPrefsKey, key.trim());
  }

  /// Low-level chat completion call.
  ///
  /// [messages] must be a list of {"role": ..., "content": ...} maps.
  /// Throws a categorized [Exception] with one of:
  /// INVALID_KEY, LIMIT_REACHED, SERVER_OVERLOAD, MODEL_ERROR,
  /// or the raw message.
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
              ..._appHeaders,
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
    if (status == 401 || bodyStr.contains('invalid api key')) {
      throw Exception('INVALID_KEY');
    } else if (status == 402 ||
        status == 429 ||
        bodyStr.contains('rate limit') ||
        bodyStr.contains('quota') ||
        bodyStr.contains('insufficient') ||
        bodyStr.contains('credits')) {
      throw Exception('LIMIT_REACHED');
    } else if (status >= 500 || status == 503) {
      throw Exception('SERVER_OVERLOAD');
    } else if (status == 400) {
      throw Exception('MODEL_ERROR');
    }
    throw Exception('OPENROUTER_ERROR_$status');
  }

  /// Single-turn text generation helper.
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

  /// JSON helper. Tries structured output first; free models don't always
  /// support `response_format`, so on a 400 it retries with a plain
  /// "return JSON only" instruction and parses the fenced/plain response.
  static Future<dynamic> generateJson(
    String prompt, {
    required String apiKey,
    String? systemInstruction,
    String model = defaultModel,
    double temperature = 0.3,
    int maxTokens = 2000,
    int retries = 1,
  }) async {
    final systemWithJson = [
      if (systemInstruction != null && systemInstruction.trim().isNotEmpty)
        systemInstruction.trim(),
      'Always return valid JSON only. No markdown, no extra text.',
    ].join(' ');

    Future<dynamic> attempt({required bool structured}) async {
      final raw = await _withRetry(
        () => chatCompletion(
          apiKey: apiKey,
          messages: [
            {'role': 'system', 'content': systemWithJson},
            {'role': 'user', 'content': prompt},
          ],
          model: model,
          jsonMode: structured,
          temperature: temperature,
          maxTokens: maxTokens,
        ),
        retries: retries,
      );
      return jsonDecode(_stripCodeFences(raw));
    }

    try {
      return await attempt(structured: true);
    } catch (e) {
      if (e.toString().contains('MODEL_ERROR') ||
          e.toString().contains('OPENROUTER_ERROR_400')) {
        // Model rejected response_format — fall back to prompt-based JSON.
        return await attempt(structured: false);
      }
      rethrow;
    }
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
