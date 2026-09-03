import 'package:flutter/material.dart';

/// A concise recovery view for screen-level data loading failures.
class LoadFailureView extends StatelessWidget {
  const LoadFailureView({
    super.key,
    required this.message,
    required this.onRetry,
    this.onClose,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 40,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
            if (onClose != null) ...[
              const SizedBox(height: 8),
              TextButton(onPressed: onClose, child: const Text('Close')),
            ],
          ],
        ),
      ),
    );
  }
}
