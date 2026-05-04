import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crab_cakes/infrastructure/providers/flex_form_provider.dart';

class TableSwitcher extends ConsumerWidget {
  final Map<String, dynamic> tables;
  final String? activeTableName;
  final bool showFKeyBadges;
  final void Function(String)? onTableSelected;

  const TableSwitcher({
    super.key,
    required this.tables,
    required this.activeTableName,
    this.showFKeyBadges = false,
    this.onTableSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tables.isEmpty) return const SizedBox.shrink();

    final chips = tables.keys.toList().asMap().entries.map((entry) {
      final index = entry.key;
      final tableName = entry.value;
      final isActive = tableName == activeTableName;
      final fKey = showFKeyBadges && index < 4 ? 'F${index + 1}' : null;

      return Padding(
        padding: const EdgeInsets.only(right: 6.0),
        child: ChoiceChip(
          label: showFKeyBadges
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(tableName),
                    if (fKey != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                        child: Text(
                          fKey,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ],
                )
              : Text(tableName),
          selected: isActive,
          onSelected: (selected) {
            if (selected) {
              // Use callback if provided, otherwise use provider
              if (onTableSelected != null) {
                onTableSelected!(tableName);
              } else {
                ref
                    .read(activeTableProvider.notifier)
                    .setActiveTable(tableName);
              }
            }
          },
        ),
      );
    }).toList();

    return SizedBox(
      height: 40,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: chips),
      ),
    );
  }
}
