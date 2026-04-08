import 'package:flutter/material.dart';
import '../../app_preferences.dart';
import '../../db/tables/enums.dart';
import '../../services/workout_cue_service.dart';

class TimerSettingsScreen extends StatefulWidget {
  const TimerSettingsScreen({super.key});

  @override
  State<TimerSettingsScreen> createState() => _TimerSettingsScreenState();
}

class _TimerSettingsScreenState extends State<TimerSettingsScreen> {
  late bool _timerEnabled;
  late TimerSound _timerSound;
  late bool _timerHaptic;
  late bool _timerKeepAwake;
  late int _timerDefaultSeconds;
  late final TextEditingController _timerSecondsCtrl;

  late bool _initTimerEnabled;
  late TimerSound _initTimerSound;
  late bool _initTimerHaptic;
  late bool _initTimerKeepAwake;
  late int _initTimerDefaultSeconds;

  /// null = still checking, true = engine present, false = no engine.
  bool? _ttsAvailable;

  bool get _hasUnsavedChanges =>
      _timerEnabled != _initTimerEnabled ||
      _timerDefaultSeconds != _initTimerDefaultSeconds ||
      _timerSound != _initTimerSound ||
      _timerHaptic != _initTimerHaptic ||
      _timerKeepAwake != _initTimerKeepAwake;

  @override
  void initState() {
    super.initState();
    _timerEnabled = AppPreferences.getTimerEnabled();
    _timerSound = AppPreferences.getTimerSound();
    _timerHaptic = AppPreferences.getTimerHaptic();
    _timerKeepAwake = AppPreferences.getTimerKeepAwake();
    _timerDefaultSeconds = AppPreferences.getTimerDefaultSeconds();
    _timerSecondsCtrl =
        TextEditingController(text: _timerDefaultSeconds.toString());

    _initTimerEnabled = _timerEnabled;
    _initTimerSound = _timerSound;
    _initTimerHaptic = _timerHaptic;
    _initTimerKeepAwake = _timerKeepAwake;
    _initTimerDefaultSeconds = _timerDefaultSeconds;

    WorkoutCueService.isAvailable().then((ok) {
      if (mounted) setState(() => _ttsAvailable = ok);
    });
  }

  Future<void> _showTtsInfo() async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Text-to-speech engine'),
        content: const Text(
          'The rest-timer alert (both "read value aloud" and "chime") is '
          'spoken by your phone\'s text-to-speech engine — this app does not '
          'play its own audio file.\n\n'
          'On GrapheneOS and other de-Googled Android builds there is no '
          'TTS engine installed by default, so the timer will be silent '
          '(haptic still works).\n\n'
          'Fix: install a TTS engine and select it under '
          'Android Settings → System → Languages → Text-to-speech output. '
          'Free options on F-Droid:\n'
          '  • RHVoice — offline, natural-sounding\n'
          '  • eSpeak NG — tiny, robotic',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timerSecondsCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await AppPreferences.setTimerEnabled(_timerEnabled);
    await AppPreferences.setTimerDefaultSeconds(_timerDefaultSeconds);
    await AppPreferences.setTimerSound(_timerSound);
    await AppPreferences.setTimerHaptic(_timerHaptic);
    await AppPreferences.setTimerKeepAwake(_timerKeepAwake);

    _initTimerEnabled = _timerEnabled;
    _initTimerSound = _timerSound;
    _initTimerHaptic = _timerHaptic;
    _initTimerKeepAwake = _timerKeepAwake;
    _initTimerDefaultSeconds = _timerDefaultSeconds;
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
        appBar: AppBar(title: const Text('Rest Timer')),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: FilledButton(
              onPressed: () async {
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
            Card.outlined(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Rest Timer'),
                    subtitle: const Text('Countdown timer between sets.'),
                    value: _timerEnabled,
                    onChanged: (v) => setState(() => _timerEnabled = v),
                  ),
                  if (_timerEnabled) ...[
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: TextField(
                        controller: _timerSecondsCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Default rest (seconds)',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (v) {
                          final seconds = int.tryParse(v.trim());
                          if (seconds != null && seconds > 0) {
                            setState(() => _timerDefaultSeconds = seconds);
                          }
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
                      child: Row(
                        children: [
                          Text('Alert sound',
                              style: Theme.of(context).textTheme.bodySmall),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.info_outline, size: 18),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                                minWidth: 24, minHeight: 24),
                            tooltip: 'About text-to-speech',
                            onPressed: _showTtsInfo,
                          ),
                        ],
                      ),
                    ),
                    if (_ttsAvailable == false &&
                        _timerSound != TimerSound.silent)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                        child: Material(
                          color: Theme.of(context)
                              .colorScheme
                              .errorContainer
                              .withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: _showTtsInfo,
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Row(
                                children: [
                                  const Icon(Icons.warning_amber_rounded,
                                      size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'No text-to-speech engine found. The '
                                      'timer alert will be silent. Tap for '
                                      'details.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    RadioGroup<TimerSound>(
                      groupValue: _timerSound,
                      onChanged: (v) => setState(() => _timerSound = v!),
                      child: const Column(
                        children: [
                          RadioListTile<TimerSound>(
                            title: Text('Read target value aloud'),
                            value: TimerSound.tts,
                          ),
                          RadioListTile<TimerSound>(
                            title: Text('Chime ("ready")'),
                            value: TimerSound.chime,
                          ),
                          RadioListTile<TimerSound>(
                            title: Text('Silent'),
                            value: TimerSound.silent,
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Haptic feedback'),
                      subtitle:
                          const Text('Vibrate when the timer reaches zero.'),
                      value: _timerHaptic,
                      onChanged: (v) => setState(() => _timerHaptic = v),
                    ),
                    SwitchListTile(
                      title: const Text('Keep screen awake'),
                      subtitle:
                          const Text('Prevent sleep during a workout.'),
                      value: _timerKeepAwake,
                      onChanged: (v) => setState(() => _timerKeepAwake = v),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
