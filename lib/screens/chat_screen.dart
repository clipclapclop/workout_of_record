import 'package:flutter/material.dart';

import '../app_preferences.dart';
import '../services/ai_context_builder.dart';
import '../services/ai_service.dart';
import '../widgets/app_nav_menu.dart';

/// A simple chat message.
class _ChatMessage {
  final String role; // 'user' or 'assistant'
  final String content;

  const _ChatMessage({required this.role, required this.content});
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, this.initialContext});

  /// Optional extra context to prepend (e.g. current workout or template data).
  final String? initialContext;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _messages = <_ChatMessage>[];
  bool _loading = false;
  bool _contextLoading = true;
  String _systemContext = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadContext();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadContext() async {
    try {
      final context = widget.initialContext != null
          ? '${widget.initialContext}\n\n${await AiContextBuilder.forChat()}'
          : await AiContextBuilder.forChat();
      if (mounted) {
        setState(() {
          _systemContext = context;
          _contextLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _contextLoading = false;
          _error = 'Failed to load context: $e';
        });
      }
    }
  }

  Future<void> _send() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    final apiKey = await AppPreferences.getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      setState(() => _error = 'No API key configured. Set it in Settings > AI.');
      return;
    }

    setState(() {
      _messages.add(_ChatMessage(role: 'user', content: text));
      _inputController.clear();
      _loading = true;
      _error = null;
    });
    _scrollToBottom();

    try {
      // Build the full message list for the API.
      final apiMessages = <Map<String, String>>[
        {
          'role': 'system',
          'content': '${AppPreferences.getAiChatPrompt()}\n\n$_systemContext',
        },
        for (final m in _messages) {'role': m.role, 'content': m.content},
      ];

      final response = await AiService.chatCompletion(apiMessages);

      if (mounted) {
        setState(() {
          _messages.add(_ChatMessage(role: 'assistant', content: response));
          _loading = false;
        });
        _scrollToBottom();
      }
    } on AiServiceException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;

          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Something went wrong: $e';

          _loading = false;
        });
      }
    }
  }

  Future<void> _retry() async {
    if (_messages.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final apiMessages = <Map<String, String>>[
        {
          'role': 'system',
          'content': '${AppPreferences.getAiChatPrompt()}\n\n$_systemContext',
        },
        for (final m in _messages) {'role': m.role, 'content': m.content},
      ];

      final response = await AiService.chatCompletion(apiMessages);

      if (mounted) {
        setState(() {
          _messages.add(_ChatMessage(role: 'assistant', content: response));
          _loading = false;
        });
        _scrollToBottom();
      }
    } on AiServiceException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Something went wrong: $e';
          _loading = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Chat'),
        automaticallyImplyLeading: false,
        actions: const [AppNavMenu(current: AppScreen.chat)],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: _contextLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            'Ask me anything about your training.\n\n'
                            'I have access to your recent workout history and profile.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        itemCount: _messages.length + (_loading ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _messages.length) {
                            // Loading indicator for pending response
                            return const Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: SizedBox(
                                  width: 48,
                                  child: LinearProgressIndicator(),
                                ),
                              ),
                            );
                          }
                          final msg = _messages[index];
                          return _MessageBubble(message: msg);
                        },
                      ),
          ),

          // Error banner
          if (_error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: theme.colorScheme.errorContainer,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(color: theme.colorScheme.onErrorContainer),
                    ),
                  ),
                  TextButton(
                    onPressed: _retry,
                    child: const Text('Retry'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(() => _error = null),
                  ),
                ],
              ),
            ),

          // Input area
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      decoration: const InputDecoration(
                        hintText: 'Ask about your training...',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      textInputAction: TextInputAction.send,
                      maxLines: 4,
                      minLines: 1,
                      onSubmitted: (_) => _send(),
                      enabled: !_loading && !_contextLoading,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    icon: const Icon(Icons.send),
                    onPressed: _loading || _contextLoading ? null : _send,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.role == 'user';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: isUser ? const Radius.circular(4) : null,
            bottomLeft: !isUser ? const Radius.circular(4) : null,
          ),
        ),
        child: SelectableText(
          message.content,
          style: TextStyle(
            color: isUser
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
