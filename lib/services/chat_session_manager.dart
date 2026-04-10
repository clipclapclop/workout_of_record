import 'package:flutter/foundation.dart';

import '../app_preferences.dart';
import 'ai_context_builder.dart';
import 'ai_service.dart';

/// A single chat message.
class ChatMessage {
  final String role; // 'user' or 'assistant'
  final String content;

  const ChatMessage({required this.role, required this.content});
}

/// Singleton that owns chat conversation state so it survives navigation.
///
/// The AI API call runs through this manager — even if the ChatScreen is
/// disposed while a response is in-flight, the response lands here and is
/// visible when the user navigates back.
class ChatSessionManager extends ChangeNotifier {
  ChatSessionManager._();
  static final ChatSessionManager instance = ChatSessionManager._();

  final List<ChatMessage> messages = [];
  bool loading = false;
  bool contextLoading = false;
  String? error;

  String _systemContext = '';
  bool _contextLoaded = false;

  /// Extra context supplied when opening chat from a specific screen
  /// (e.g. the current workout or template being edited).
  String? _initialContext;

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Ensures the system context is loaded. Safe to call multiple times; the
  /// context is only fetched once per session (until [clear] is called).
  ///
  /// [initialContext] is optional extra context to prepend (e.g. current
  /// workout info). It is applied once on the first call per session.
  Future<void> ensureContext({String? initialContext}) async {
    if (initialContext != null && _initialContext == null) {
      _initialContext = initialContext;
      // If context was already loaded without initial context, re-fetch so
      // the new initial context gets included.
      if (_contextLoaded) {
        _contextLoaded = false;
      }
    }

    if (_contextLoaded) return;

    contextLoading = true;
    notifyListeners();

    try {
      final base = await AiContextBuilder.forChat();
      _systemContext = _initialContext != null
          ? '$_initialContext\n\n$base'
          : base;
      _contextLoaded = true;
    } catch (e) {
      error = 'Failed to load context: $e';
    }

    contextLoading = false;
    notifyListeners();
  }

  /// Send a user message and get the assistant response.
  Future<void> send(String text) async {
    if (text.trim().isEmpty) return;

    final apiKey = await AppPreferences.getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      error = 'No API key configured. Set it in Settings > AI.';
      notifyListeners();
      return;
    }

    messages.add(ChatMessage(role: 'user', content: text.trim()));
    loading = true;
    error = null;
    notifyListeners();

    try {
      final apiMessages = <Map<String, String>>[
        {
          'role': 'system',
          'content': '${AppPreferences.getAiChatPrompt()}\n\n$_systemContext',
        },
        for (final m in messages) {'role': m.role, 'content': m.content},
      ];

      final response = await AiService.chatCompletion(apiMessages);
      messages.add(ChatMessage(role: 'assistant', content: response));
    } on AiServiceException catch (e) {
      error = e.message;
    } catch (e) {
      error = 'Something went wrong: $e';
    }

    loading = false;
    notifyListeners();
  }

  /// Retry the last exchange (re-send the current message history).
  Future<void> retry() async {
    if (messages.isEmpty) return;

    loading = true;
    error = null;
    notifyListeners();

    try {
      final apiMessages = <Map<String, String>>[
        {
          'role': 'system',
          'content': '${AppPreferences.getAiChatPrompt()}\n\n$_systemContext',
        },
        for (final m in messages) {'role': m.role, 'content': m.content},
      ];

      final response = await AiService.chatCompletion(apiMessages);
      messages.add(ChatMessage(role: 'assistant', content: response));
    } on AiServiceException catch (e) {
      error = e.message;
    } catch (e) {
      error = 'Something went wrong: $e';
    }

    loading = false;
    notifyListeners();
  }

  /// Clear the conversation and reset to a fresh state.
  void clear() {
    messages.clear();
    error = null;
    loading = false;
    _systemContext = '';
    _initialContext = null;
    _contextLoaded = false;
    contextLoading = false;
    notifyListeners();
  }

  /// Dismiss the current error.
  void dismissError() {
    error = null;
    notifyListeners();
  }

  /// Whether the session has any messages (used to decide whether to show
  /// the "New conversation" button).
  bool get hasMessages => messages.isNotEmpty;
}
