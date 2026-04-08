import 'package:flutter/material.dart';
import '../../app_preferences.dart';
import '../../services/ai_service.dart';
import '../../services/saf_service.dart';
import 'ai_log_screen.dart';

class AiSettingsScreen extends StatefulWidget {
  const AiSettingsScreen({super.key});

  @override
  State<AiSettingsScreen> createState() => _AiSettingsScreenState();
}

class _AiSettingsScreenState extends State<AiSettingsScreen> {
  late bool _aiEnabled;
  final _apiKeyController = TextEditingController();
  final _creditIdController = TextEditingController();
  final _modelController = TextEditingController();
  final _recPromptController = TextEditingController();
  final _chatPromptController = TextEditingController();
  late int _historyWeeks;
  bool _apiKeyLoading = true;
  bool _obscureApiKey = true;

  // Balance
  double? _balance;
  bool _balanceLoading = false;
  String? _balanceError;

  // Logging
  late bool _loggingEnabled;
  String? _logDirPath;

  late bool _initAiEnabled;
  String _initApiKey = '';
  late String _initCreditId;
  late String _initModel;
  late String _initRecPrompt;
  late String _initChatPrompt;
  late int _initHistoryWeeks;
  late bool _initLoggingEnabled;
  String? _initLogDirPath;

  bool get _hasUnsavedChanges =>
      _aiEnabled != _initAiEnabled ||
      _apiKeyController.text.trim() != _initApiKey ||
      _creditIdController.text.trim() != _initCreditId ||
      _modelController.text.trim() != _initModel ||
      _recPromptController.text.trim() != _initRecPrompt ||
      _chatPromptController.text.trim() != _initChatPrompt ||
      _historyWeeks != _initHistoryWeeks ||
      _loggingEnabled != _initLoggingEnabled ||
      _logDirPath != _initLogDirPath;

  @override
  void initState() {
    super.initState();
    _aiEnabled = AppPreferences.getAiEnabled();
    _modelController.text = AppPreferences.getAiModel();
    _creditIdController.text = AppPreferences.getAiCreditId() ?? '';
    _recPromptController.text = AppPreferences.getAiRecommendationPrompt();
    _chatPromptController.text = AppPreferences.getAiChatPrompt();
    _historyWeeks = AppPreferences.getAiHistoryWeeks();
    _loggingEnabled = AppPreferences.getAiLoggingEnabled();
    _logDirPath = AppPreferences.getAiLogDirectoryPath();

    _initAiEnabled = _aiEnabled;
    _initCreditId = _creditIdController.text;
    _initModel = _modelController.text;
    _initRecPrompt = _recPromptController.text;
    _initChatPrompt = _chatPromptController.text;
    _initHistoryWeeks = _historyWeeks;
    _initLoggingEnabled = _loggingEnabled;
    _initLogDirPath = _logDirPath;

    _loadApiKey();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _creditIdController.dispose();
    _modelController.dispose();
    _recPromptController.dispose();
    _chatPromptController.dispose();
    super.dispose();
  }

  Future<void> _loadApiKey() async {
    final key = await AppPreferences.getApiKey();
    if (mounted) {
      setState(() {
        _apiKeyController.text = key ?? '';
        _initApiKey = key ?? '';
        _apiKeyLoading = false;
      });
    }
  }

  Future<void> _checkBalance() async {
    final creditId = _creditIdController.text.trim();
    if (creditId.isEmpty) {
      setState(() => _balanceError = 'Enter a Credit ID first');
      return;
    }
    setState(() {
      _balanceLoading = true;
      _balanceError = null;
      _balance = null;
    });
    try {
      final bal = await AiService.getBalance(creditId);
      if (mounted) setState(() => _balance = bal);
    } catch (e) {
      if (mounted) setState(() => _balanceError = e.toString());
    } finally {
      if (mounted) setState(() => _balanceLoading = false);
    }
  }

  Future<void> _save() async {
    await AppPreferences.setAiEnabled(_aiEnabled);
    final apiKey = _apiKeyController.text.trim();
    await AppPreferences.setApiKey(apiKey.isEmpty ? null : apiKey);
    final creditId = _creditIdController.text.trim();
    await AppPreferences.setAiCreditId(creditId.isEmpty ? null : creditId);
    await AppPreferences.setAiModel(_modelController.text.trim().isEmpty
        ? AppPreferences.defaultAiModel
        : _modelController.text.trim());
    await AppPreferences.setAiRecommendationPrompt(
        _recPromptController.text.trim().isEmpty
            ? AppPreferences.defaultRecommendationPrompt
            : _recPromptController.text.trim());
    await AppPreferences.setAiChatPrompt(
        _chatPromptController.text.trim().isEmpty
            ? AppPreferences.defaultChatPrompt
            : _chatPromptController.text.trim());
    await AppPreferences.setAiHistoryWeeks(_historyWeeks);
    await AppPreferences.setAiLoggingEnabled(_loggingEnabled);
    await AppPreferences.setAiLogDirectoryPath(_logDirPath);

    _initAiEnabled = _aiEnabled;
    _initApiKey = _apiKeyController.text.trim();
    _initCreditId = _creditIdController.text.trim();
    _initModel = _modelController.text.trim();
    _initRecPrompt = _recPromptController.text.trim();
    _initChatPrompt = _chatPromptController.text.trim();
    _initHistoryWeeks = _historyWeeks;
    _initLoggingEnabled = _loggingEnabled;
    _initLogDirPath = _logDirPath;
  }

  Future<bool> _onPop() async {
    if (!_hasUnsavedChanges) return true;
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unsaved changes'),
        content: const Text('You have unsaved settings.'),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, 'cancel'),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, 'dismiss'),
                  child: const Text('Dismiss'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx, 'save'),
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (result == 'save') {
      await _save();
      return true;
    }
    return result == 'dismiss';
  }

  void _showPromptEditor({
    required String title,
    required TextEditingController controller,
    required String defaultValue,
  }) {
    showDialog(
      context: context,
      builder: (ctx) {
        final editCtrl = TextEditingController(text: controller.text);
        return AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TextField(
                  controller: editCtrl,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'System prompt...',
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => editCtrl.text = defaultValue,
                  child: const Text('Reset to default'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                setState(() => controller.text = editCtrl.text);
                Navigator.pop(ctx);
              },
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  Widget _sectionLabel(String label) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(label, style: Theme.of(context).textTheme.labelLarge),
      );

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final ok = await _onPop();
        if (ok && context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('AI')),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: FilledButton(
              onPressed: _apiKeyLoading
                  ? null
                  : () async {
                      await _save();
                      if (context.mounted) Navigator.pop(context);
                    },
              child: const Text('Save'),
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            // ── Enable toggle ───────────────────────────────────────────
            Card.outlined(
              child: SwitchListTile(
                title: const Text('AI Recommendations'),
                subtitle: const Text(
                    'Pre-fill set targets based on your history and profile.'),
                value: _aiEnabled,
                onChanged: (v) => setState(() => _aiEnabled = v),
              ),
            ),
            const SizedBox(height: 24),

            // ── Connection ──────────────────────────────────────────────
            _sectionLabel('Connection'),
            Card.outlined(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ppq.ai API Key',
                        style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 8),
                    if (_apiKeyLoading)
                      const LinearProgressIndicator()
                    else
                      TextField(
                        controller: _apiKeyController,
                        obscureText: _obscureApiKey,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          hintText: 'ppq_...',
                          isDense: true,
                          suffixIcon: IconButton(
                            icon: Icon(_obscureApiKey
                                ? Icons.visibility
                                : Icons.visibility_off),
                            onPressed: () => setState(
                                () => _obscureApiKey = !_obscureApiKey),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Text('Credit ID (for balance check)',
                        style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _creditIdController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: _balanceLoading ? null : _checkBalance,
                          child: _balanceLoading
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                )
                              : const Text('Check Balance'),
                        ),
                        const SizedBox(width: 12),
                        if (_balance != null)
                          Text('\$${_balance!.toStringAsFixed(4)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                      fontWeight: FontWeight.bold)),
                        if (_balanceError != null)
                          Flexible(
                            child: Text(_balanceError!,
                                style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.error)),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Model ───────────────────────────────────────────────────
            _sectionLabel('Model'),
            Card.outlined(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: TextField(
                  controller: _modelController,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: 'Model ID',
                    isDense: true,
                    helperText:
                        'Default: ${AppPreferences.defaultAiModel}',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── History depth ───────────────────────────────────────────
            _sectionLabel('History Context'),
            Card.outlined(
              child: ListTile(
                title: const Text('Weeks of history'),
                subtitle: Text('$_historyWeeks weeks sent to the AI'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: _historyWeeks > 1
                          ? () =>
                              setState(() => _historyWeeks--)
                          : null,
                    ),
                    Text('$_historyWeeks',
                        style: Theme.of(context).textTheme.titleMedium),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: _historyWeeks < 12
                          ? () =>
                              setState(() => _historyWeeks++)
                          : null,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Prompts ─────────────────────────────────────────────────
            _sectionLabel('System Prompts'),
            Card.outlined(
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Recommendation prompt'),
                    subtitle: Text(
                      _recPromptController.text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.edit),
                    onTap: () => _showPromptEditor(
                      title: 'Recommendation Prompt',
                      controller: _recPromptController,
                      defaultValue:
                          AppPreferences.defaultRecommendationPrompt,
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Chat prompt'),
                    subtitle: Text(
                      _chatPromptController.text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.edit),
                    onTap: () => _showPromptEditor(
                      title: 'Chat Prompt',
                      controller: _chatPromptController,
                      defaultValue: AppPreferences.defaultChatPrompt,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Logging ────────────────────────────────────────────────
            _sectionLabel('Logging'),
            Card.outlined(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Export AI logs to file'),
                    subtitle: const Text(
                        'Save each AI request/response as a markdown file.'),
                    value: _loggingEnabled,
                    onChanged: (v) => setState(() => _loggingEnabled = v),
                  ),
                  if (_loggingEnabled) ...[
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('Log folder'),
                      subtitle: Text(
                        _logDirPath != null
                            ? Uri.decodeFull(
                                Uri.parse(_logDirPath!).pathSegments.last)
                            : 'No folder selected',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.folder_open),
                      onTap: () async {
                        final uri = await SafService.pickFolder();
                        if (uri != null && mounted) {
                          setState(() => _logDirPath = uri);
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Tools ──────────────────────────────────────────────────
            _sectionLabel('Tools'),
            Card.outlined(
              child: ListTile(
                leading: const Icon(Icons.article_outlined),
                title: const Text('View AI log'),
                subtitle: const Text('Session requests and responses'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AiLogScreen()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
