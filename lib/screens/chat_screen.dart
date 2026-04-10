import 'package:flutter/material.dart';

import '../services/chat_session_manager.dart';
import '../widgets/app_nav_menu.dart';

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
  final _session = ChatSessionManager.instance;

  @override
  void initState() {
    super.initState();
    _session.addListener(_onSessionChanged);
    // When opened with initialContext (e.g. from workout), start a fresh
    // session so the context is relevant to what the user is doing.
    if (widget.initialContext != null) {
      _session.clear();
    }
    _session.ensureContext(initialContext: widget.initialContext);
  }

  @override
  void dispose() {
    _session.removeListener(_onSessionChanged);
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSessionChanged() {
    if (mounted) setState(() {});
    _scrollToBottom();
  }

  void _send() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    _inputController.clear();
    _session.send(text);
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

  void _confirmClear() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New conversation?'),
        content: const Text(
          'This will clear the current conversation. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _session.clear();
              _session.ensureContext();
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final messages = _session.messages;
    final loading = _session.loading;
    final contextLoading = _session.contextLoading;
    final error = _session.error;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Chat'),
        automaticallyImplyLeading: false,
        actions: [
          if (_session.hasMessages || loading)
            IconButton(
              icon: const Icon(Icons.add_comment_outlined),
              tooltip: 'New conversation',
              onPressed: loading ? null : _confirmClear,
            ),
          const AppNavMenu(current: AppScreen.chat),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: contextLoading
                ? const Center(child: CircularProgressIndicator())
                : messages.isEmpty
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
                        itemCount: messages.length + (loading ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == messages.length) {
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
                          final msg = messages[index];
                          return _MessageBubble(message: msg);
                        },
                      ),
          ),

          // Error banner
          if (error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: theme.colorScheme.errorContainer,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      error,
                      style: TextStyle(
                          color: theme.colorScheme.onErrorContainer),
                    ),
                  ),
                  TextButton(
                    onPressed: _session.retry,
                    child: const Text('Retry'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: _session.dismissError,
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
                      enabled: !loading && !contextLoading,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    icon: const Icon(Icons.send),
                    onPressed: loading || contextLoading ? null : _send,
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

  final ChatMessage message;

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
