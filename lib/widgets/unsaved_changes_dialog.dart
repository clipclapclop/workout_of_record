import 'package:flutter/material.dart';

enum UnsavedChangesAction { keepEditing, discard, save }

Future<UnsavedChangesAction> showUnsavedChangesDialog(
  BuildContext context,
) async {
  final action = await showDialog<UnsavedChangesAction>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Unsaved changes'),
      content: const Text('You have unsaved changes.'),
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
                  UnsavedChangesAction.keepEditing,
                ),
                child: const Text('Keep editing'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onPressed: () =>
                    Navigator.pop(dialogContext, UnsavedChangesAction.discard),
                child: const Text('Discard'),
              ),
              const SizedBox(height: 8),
              FilledButton(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onPressed: () =>
                    Navigator.pop(dialogContext, UnsavedChangesAction.save),
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ],
    ),
  );
  return action ?? UnsavedChangesAction.keepEditing;
}
