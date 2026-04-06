import 'dart:convert';

import 'package:http/http.dart' as http;

import '../app_preferences.dart';

/// Lightweight wrapper around the ppq.ai OpenAI-compatible API.
class AiService {
  AiService._();

  static const _baseUrl = 'https://api.ppq.ai';

  // ── Chat completions ────────────────────────────────────────────────────────

  /// Sends a chat completion request and returns the assistant's message content.
  ///
  /// [messages] is a list of `{role, content}` maps (OpenAI format).
  /// Throws on network errors, missing API key, or non-2xx responses.
  static Future<String> chatCompletion(
    List<Map<String, String>> messages, {
    String? model,
  }) async {
    final apiKey = await AppPreferences.getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw AiServiceException('No API key configured. Set it in Settings > AI.');
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': model ?? AppPreferences.getAiModel(),
        'messages': messages,
      }),
    );

    if (response.statusCode != 200) {
      final body = _tryDecodeBody(response.body);
      throw AiServiceException(
        'API error ${response.statusCode}: ${body ?? response.reasonPhrase}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = json['choices'] as List<dynamic>;
    if (choices.isEmpty) {
      throw AiServiceException('No choices returned from the API.');
    }
    final message = choices[0]['message'] as Map<String, dynamic>;
    return message['content'] as String;
  }

  // ── Balance ─────────────────────────────────────────────────────────────────

  /// Returns the account balance in USD for the given [creditId].
  static Future<double> getBalance(String creditId) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/credits/balance'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'credit_id': creditId}),
    );

    if (response.statusCode != 200) {
      final body = _tryDecodeBody(response.body);
      throw AiServiceException(
        'Balance check failed (${response.statusCode}): ${body ?? response.reasonPhrase}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    // ppq.ai returns balance as a number (could be int or double).
    final balance = json['balance'];
    if (balance is num) return balance.toDouble();
    throw AiServiceException('Unexpected balance format: $balance');
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  static String? _tryDecodeBody(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      return json['error']?['message'] as String? ?? json['error']?.toString();
    } catch (_) {
      return null;
    }
  }
}

class AiServiceException implements Exception {
  final String message;
  const AiServiceException(this.message);
  @override
  String toString() => message;
}
