import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crab_cakes/infrastructure/providers/settings_provider.dart';

class ColumnOrderDialog extends ConsumerStatefulWidget {
  final String tableName;
  final List<String> allColumns;

  const ColumnOrderDialog({
    super.key,
    required this.tableName,
    required this.allColumns,
  });

  @override
  ConsumerState<ColumnOrderDialog> createState() => _ColumnOrderDialogState();
}

class _ColumnOrderDialogState extends ConsumerState<ColumnOrderDialog> {
  List<String> _orderedColumns = [];
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Initialize with the provided columns as fallback
    _orderedColumns = List.from(widget.allColumns);
  }

  void _loadCurrentOrder() {
    if (_isInitialized) return;

    final settingsAsync = ref.watch(projectSettingsProvider);

    settingsAsync.whenData((settings) {
      if (!_isInitialized && mounted) {
        // Get columns that should be shown
        final selectedForDisplay = <String>[];

        // Check which columns have showInCatchHistory = true
        for (final columnName in widget.allColumns) {
          final config = settings.fieldConfig.getConfig(
            table: widget.tableName,
            col: columnName,
          );
          if (config?.showInCatchHistory == true) {
            selectedForDisplay.add(columnName);
          }
        }

        final columnsToOrder = selectedForDisplay.isNotEmpty
            ? selectedForDisplay
            : widget.allColumns;

        final savedOrder = settings.columnOrder[widget.tableName];

        setState(() {
          if (savedOrder != null && savedOrder.isNotEmpty) {
            final orderedColumns = <String>[];

            for (final columnName in savedOrder) {
              if (columnsToOrder.contains(columnName)) {
                orderedColumns.add(columnName);
              }
            }

            for (final columnName in columnsToOrder) {
              if (!orderedColumns.contains(columnName)) {
                orderedColumns.add(columnName);
              }
            }

            _orderedColumns = orderedColumns;
          } else {
            _orderedColumns = List.from(columnsToOrder);
          }

          _isInitialized = true;
        });
      }
    });
  }

  Future<void> _saveOrder() async {
    final updateUsecase = ref.read(updateColumnOrderUsecaseProvider);

    if (updateUsecase != null) {
      await updateUsecase.execute(
        tableName: widget.tableName,
        columnOrder: _orderedColumns,
      );
      ref.invalidate(projectSettingsProvider);
    }

    if (!mounted) return;
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Column order saved')),
    );
  }

  @override
  Widget build(BuildContext context) {
    _loadCurrentOrder();
    
    return Dialog(
      child: Container(
        width: 500,
        height: 600,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.reorder),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Column Display Order',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Drag columns to reorder how they appear in the catch history table.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: _orderedColumns.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ReorderableListView.builder(
                      itemCount: _orderedColumns.length,
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (newIndex > oldIndex) {
                            newIndex -= 1;
                          }
                          final item = _orderedColumns.removeAt(oldIndex);
                          _orderedColumns.insert(newIndex, item);
                        });
                      },
                      itemBuilder: (context, index) {
                        final column = _orderedColumns[index];
                        return Card(
                          key: ValueKey(column),
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: ReorderableDragStartListener(
                              index: index,
                              child: const Icon(Icons.drag_handle),
                            ),
                            title: Text(column),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${index + 1}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),

            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FilledButton.icon(
                  onPressed: _saveOrder,
                  icon: const Icon(Icons.save),
                  label: const Text('Save Order'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}