import 'package:flutter/material.dart';

enum UnsavedSettingsAction { keepEditing, discard, save }

Future<UnsavedSettingsAction> showUnsavedSettingsDialog(
  BuildContext context,
) async {
  final action = await showDialog<UnsavedSettingsAction>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Unsaved changes'),
      content: const Text('You have unsaved settings.'),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      actions: [
        SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onPressed: () => Navigator.pop(
                  dialogContext,
                  UnsavedSettingsAction.keepEditing,
                ),
                child: const Text('Keep editing'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onPressed: () =>
                    Navigator.pop(dialogContext, UnsavedSettingsAction.discard),
                child: const Text('Discard'),
              ),
              const SizedBox(height: 8),
              FilledButton(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onPressed: () =>
                    Navigator.pop(dialogContext, UnsavedSettingsAction.save),
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ],
    ),
  );
  return action ?? UnsavedSettingsAction.keepEditing;
}
