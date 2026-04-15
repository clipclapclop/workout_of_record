import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../app_preferences.dart';

/// Lightweight wrapper around the ppq.ai OpenAI-compatible API.
class AiService {
  AiService._();

  static const _baseUrl = 'https://api.ppq.ai';
  static const _requestTimeout = Duration(seconds: 30);

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

    final http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('$_baseUrl/chat/completions'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
            },
            body: jsonEncode({
              'model': model ?? AppPreferences.getAiModel(),
              'messages': messages,
            }),
          )
          .timeout(_requestTimeout);
    } catch (e) {
      _throwFriendlyError(e);
    }

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
    final http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('$_baseUrl/credits/balance'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'credit_id': creditId}),
          )
          .timeout(_requestTimeout);
    } catch (e) {
      _throwFriendlyError(e);
    }

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

  static Never _throwFriendlyError(Object e) {
    if (e is AiServiceException) throw e;
    final msg = e.toString();
    if (msg.contains('SocketException') || msg.contains('host lookup')) {
      throw const AiServiceException(
        'Unable to reach the AI service. Check your internet connection.',
      );
    }
    if (e is TimeoutException || msg.contains('TimeoutException')) {
      throw const AiServiceException(
        'The request timed out. Please try again.',
      );
    }
    if (msg.contains('HandshakeException') ||
        msg.contains('CERTIFICATE_VERIFY')) {
      throw const AiServiceException(
        'Secure connection failed. Check your network settings.',
      );
    }
    throw const AiServiceException('Something went wrong. Please try again.');
  }
}

class AiServiceException implements Exception {
  final String message;
  const AiServiceException(this.message);
  @override
  String toString() => message;
}
