import 'package:flutter/material.dart';

import '../db/template_data.dart';

enum MesoTemplateSort { name, created, lastUsed }

extension MesoTemplateHistory on MesoTemplateWithHistory {
  DateTime? get lastUsedAt =>
      pastMesos.isEmpty ? null : pastMesos.first.createdAt;
}

List<MesoTemplateWithHistory> sortMesoTemplates(
  Iterable<MesoTemplateWithHistory> templates,
  MesoTemplateSort sort,
) {
  final result = templates.toList();
  result.sort((a, b) {
    final comparison = switch (sort) {
      MesoTemplateSort.name => a.template.name.toLowerCase().compareTo(
        b.template.name.toLowerCase(),
      ),
      MesoTemplateSort.created => b.template.createdAt.compareTo(
        a.template.createdAt,
      ),
      MesoTemplateSort.lastUsed => _compareNewestNullableDates(
        a.lastUsedAt,
        b.lastUsedAt,
      ),
    };
    return comparison != 0
        ? comparison
        : a.template.name.toLowerCase().compareTo(
            b.template.name.toLowerCase(),
          );
  });
  return result;
}

int _compareNewestNullableDates(DateTime? a, DateTime? b) {
  if (a == null && b == null) return 0;
  if (a == null) return 1;
  if (b == null) return -1;
  return b.compareTo(a);
}

class MesoTemplateSortButton extends StatelessWidget {
  const MesoTemplateSortButton({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final MesoTemplateSort value;
  final ValueChanged<MesoTemplateSort> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<MesoTemplateSort>(
      initialValue: value,
      tooltip: 'Sort templates',
      icon: const Icon(Icons.sort),
      onSelected: onChanged,
      itemBuilder: (context) => const [
        PopupMenuItem(value: MesoTemplateSort.name, child: Text('Name')),
        PopupMenuItem(
          value: MesoTemplateSort.created,
          child: Text('Creation date (newest)'),
        ),
        PopupMenuItem(
          value: MesoTemplateSort.lastUsed,
          child: Text('Last used (newest)'),
        ),
      ],
    );
  }
}

class MesoTemplateCard extends StatelessWidget {
  const MesoTemplateCard({
    super.key,
    required this.history,
    required this.onTap,
    this.isSelected = false,
    this.showSelection = false,
    this.onEdit,
    this.onCopy,
    this.onDelete,
  });

  final MesoTemplateWithHistory history;
  final VoidCallback onTap;
  final bool isSelected;
  final bool showSelection;
  final VoidCallback? onEdit;
  final VoidCallback? onCopy;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final template = history.template;
    final actions = <_TemplateCardAction, VoidCallback>{
      _TemplateCardAction.edit: ?onEdit,
      _TemplateCardAction.copy: ?onCopy,
      _TemplateCardAction.delete: ?onDelete,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: showSelection && isSelected
            ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.name,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Created ${formatMesoTemplateDate(template.createdAt)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      history.lastUsedAt == null
                          ? 'Never used'
                          : 'Last used ${formatMesoTemplateDate(history.lastUsedAt!)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (showSelection && isSelected)
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                ),
              if (actions.isNotEmpty)
                PopupMenuButton<_TemplateCardAction>(
                  tooltip: 'Template actions',
                  onSelected: (action) => actions[action]!(),
                  itemBuilder: (context) => [
                    if (onEdit != null)
                      const PopupMenuItem(
                        value: _TemplateCardAction.edit,
                        child: Text('Edit'),
                      ),
                    if (onCopy != null)
                      const PopupMenuItem(
                        value: _TemplateCardAction.copy,
                        child: Text('Copy'),
                      ),
                    if (onDelete != null)
                      const PopupMenuItem(
                        value: _TemplateCardAction.delete,
                        child: Text('Delete'),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _TemplateCardAction { edit, copy, delete }

String formatMesoTemplateDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}
