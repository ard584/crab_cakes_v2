import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ui_prototype/infrastructure/providers/flex_form_provider.dart';
import 'package:ui_prototype/infrastructure/providers/settings_provider.dart';
import 'package:ui_prototype/infrastructure/providers/field_config_providers.dart';

import 'package:ui_prototype/domain/entities/settings/field_config.dart';

import 'package:ui_prototype/infrastructure/providers/column_filter_provider.dart';

import 'package:ui_prototype/presentation/dialogs/column_order_dialog.dart';

class FieldConfigScreen extends ConsumerWidget {
  const FieldConfigScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectAsync = ref.watch(projectViewModelProvider);
    final settingsAsync = ref.watch(projectSettingsProvider);
    final activeTableName = ref.watch(activeTableProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Field Config'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: projectAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(child: Text("Error: $e")),
          data: (project) {
            if (project.tables.isEmpty) {
              return const Center(
                child: Text("No project tables available."),
              );
            }

            final resolvedTableName =
                activeTableName ?? project.tables.keys.first;
            final table = project.tables[resolvedTableName];

            if (table == null) {
              return const Center(
                child: Text("Selected table could not be found."),
              );
            }

            // Get filter setting from provider
            final hideDoubleUnderscore = ref.watch(hideDoubleUnderscoreColumnsProvider);

            // Apply filter based on provider setting
            final attributes = hideDoubleUnderscore
                ? table.attributes.values.where((a) => !a.fields.name.startsWith(kColumnPrefixToHide)).toList()
                : table.attributes.values.toList();

            return settingsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text("Error: $e")),
              data: (settings) {
                final resolvedSettings = settings;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TableChoiceChips(
                      activeTableName: resolvedTableName,
                      onTableSelected: (tableName) {
                        ref
                            .read(activeTableProvider.notifier)
                            .setActiveTable(tableName);
                      },
                    ),
                    const SizedBox(height: 18),
                    Text(
                      "Configure dropdown options and simple constraints for each field.",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 14),
                    const _FieldConfigHeader(),
                    const SizedBox(height: 8),
                    Expanded(
                      child: attributes.isEmpty
                          ? const _EmptyFieldConfigView()
                          : ListView.separated(
                              itemCount: attributes.length + 1,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                              if (index == 0) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surface,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: Padding(
                                          padding: const EdgeInsets.only(top: 6),
                                          child: Text(
                                            "Column Display Order",
                                            style: Theme.of(context).textTheme.titleSmall,
                                          ),
                                        ),
                                      ),
                                      const Expanded(
                                        flex: 4,
                                        child: Text("Reorder columns in catch history table"),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Row(
                                          children: [
                                            const Spacer(),
                                            SizedBox(
                                              width: 98,
                                              child: OutlinedButton(
                                                onPressed: () {
                                                  final visibleColumns = attributes.where((attr) {
                                                    final fieldName = attr.fields.name;
                                                    final config = resolvedSettings.fieldConfig.getConfig(
                                                      table: resolvedTableName,
                                                      col: fieldName,
                                                    );
                                                    return config?.showInCatchHistory ?? false;
                                                  }).map((a) => a.fields.name).toList();
                                                  
                                                  final columnsToOrder = visibleColumns.isEmpty
                                                      ? attributes.take(8).map((a) => a.fields.name).toList()
                                                      : visibleColumns;
                                                  
                                                  showDialog(
                                                    context: context,
                                                    builder: (context) => ColumnOrderDialog(
                                                      tableName: resolvedTableName,
                                                      allColumns: columnsToOrder,
                                                    ),
                                                  );
                                                },
                                                child: const Text("Order"),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                                
                                final fieldIndex = index - 1;
                                final attribute = attributes[fieldIndex];
                                final fieldName = attribute.fields.name;
                                final dataType = attribute.fields.dataType;
                                final schemaRequired =
                                    attribute.fields.isNotNullable;

                                final savedConfig =
                                    resolvedSettings.fieldConfig.getConfig(
                                  table: resolvedTableName,
                                  col: fieldName,
                                );

                                final effectiveConfig = savedConfig ??
                                    FieldConfig.defaultInstance().copyWith(
                                      isRequired: schemaRequired,
                                    );

                                return _FieldConfigRow(
                                  fieldName: fieldName,
                                  dataType: dataType,
                                  config: effectiveConfig,
                                  schemaRequired: schemaRequired,
                                  onEditPressed: () async {
                                    final shownCount = attributes.where((attr) {
                                      final fn = attr.fields.name;
                                      final cfg = resolvedSettings.fieldConfig.getConfig(
                                        table: resolvedTableName,
                                        col: fn,
                                      );
                                      return cfg?.showInCatchHistory ?? false;
                                    }).length;

                                    final updated =
                                        await showDialog<FieldConfig>(
                                      context: context,
                                      builder: (_) => FieldConfigDialog(
                                        initialValue: effectiveConfig,
                                        fieldName: fieldName,
                                        dataType: dataType,
                                        currentShownCount: shownCount,
                                        schemaRequired: schemaRequired,
                                      ),
                                    );

                                    if (updated == null) return;
                                    if (!context.mounted) return;

                                    final updateUsecase = ref.read(
                                      updateFieldConfigUsecaseProvider,
                                    );

                                    if (updateUsecase == null) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'No active project settings repository.',
                                          ),
                                        ),
                                      );
                                      return;
                                    }

                                    try {
                                      await updateUsecase.execute(
                                        table: resolvedTableName,
                                        column: fieldName,
                                        config: updated,
                                      );
                                      if (effectiveConfig.showInCatchHistory != updated.showInCatchHistory) {
                                        final currentOrder = resolvedSettings.columnOrder[resolvedTableName] ?? [];
                                        List<String> newOrder;
                                        if (updated.showInCatchHistory) {
                                          if (!currentOrder.contains(fieldName)) {
                                            newOrder = [...currentOrder, fieldName];
                                          } else {
                                            newOrder = currentOrder;
                                          }
                                        } else {
                                          newOrder = currentOrder.where((col) => col != fieldName).toList();
                                        }
                                        final updateColumnOrderUsecase = ref.read(updateColumnOrderUsecaseProvider);
                                        if (updateColumnOrderUsecase != null) {
                                          await updateColumnOrderUsecase.execute(
                                            tableName: resolvedTableName,
                                            columnOrder: newOrder,
                                          );
                                        }
                                      }

                                      ref.invalidate(projectSettingsProvider);

                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text('Field config saved.'),
                                        ),
                                      );
                                    } catch (e) {
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Failed to save field config: $e',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _TableChoiceChips extends ConsumerWidget {
  final String activeTableName;
  final void Function(String tableName) onTableSelected;

  const _TableChoiceChips({
    required this.activeTableName,
    required this.onTableSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectAsync = ref.watch(projectViewModelProvider);

    return projectAsync.when(
      loading: () => const CircularProgressIndicator(),
      error: (e, st) => Text("Error: $e"),
      data: (project) {
        final chips = project.tables.entries.map((table) {
          return ChoiceChip(
            label: Text(table.key),
            selected: table.key == activeTableName,
            onSelected: (selected) {
              if (selected) {
                onTableSelected(table.key);
              }
            },
          );
        }).toList();

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: chips,
          ),
        );
      },
    );
  }
}

class _FieldConfigHeader extends StatelessWidget {
  const _FieldConfigHeader();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: const Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              "Column",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              "Dropdown / Constraints",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex:3,
            child: Text(
              "Catch Table",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldConfigRow extends ConsumerWidget {
  final String fieldName;
  final String dataType;
  final FieldConfig config;
  final bool schemaRequired;
  final VoidCallback onEditPressed;

  const _FieldConfigRow({
    required this.fieldName,
    required this.dataType,
    required this.config,
    required this.schemaRequired,
    required this.onEditPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fieldName,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dataType,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: _ConfigSummary(
              config: config,
              schemaRequired: schemaRequired,
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                if (config.showInCatchHistory)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Shown',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                const Spacer(),
                SizedBox(
                  width: 98,
                  child: OutlinedButton(
                    onPressed: onEditPressed,
                    child: const Text("Edit"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfigSummary extends StatelessWidget {
  final FieldConfig config;
  final bool schemaRequired;

  const _ConfigSummary({
    required this.config,
    required this.schemaRequired,
  });

  @override
  Widget build(BuildContext context) {
    final summaryLines = <String>[];

    if (config.useDropdown) {
      if (config.options.isEmpty) {
        summaryLines.add("Dropdown enabled, no options yet");
      } else {
        summaryLines.add("Options: ${config.options.join(', ')}");
      }
    } else {
      summaryLines.add("Free text entry");
    }

    summaryLines.add(
      config.allowCustomValues
          ? "Custom values allowed"
          : "Restricted to listed options",
    );

    if (config.minValue != null || config.maxValue != null) {
      summaryLines.add(
        "Range: ${config.minValue?.toString() ?? '-∞'} to ${config.maxValue?.toString() ?? '∞'}",
      );
    }

    if (schemaRequired || config.isRequired) {
      summaryLines.add("Required");
    }

    if (config.isSticky) {
      summaryLines.add("Sticky field");
    }

    if ((config.helpText ?? '').trim().isNotEmpty) {
      summaryLines.add("Help: ${(config.helpText ?? '').trim()}");
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: summaryLines
          .map(
            (line) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(line),
            ),
          )
          .toList(),
    );
  }
}

class _EmptyFieldConfigView extends StatelessWidget {
  const _EmptyFieldConfigView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        "This table has no columns to configure.",
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}

class FieldConfigDialog extends StatefulWidget {
  final FieldConfig initialValue;
  final String fieldName;
  final String dataType;
  final int currentShownCount;
  final bool schemaRequired;

  const FieldConfigDialog({
    super.key,
    required this.initialValue,
    required this.fieldName,
    required this.dataType,
    required this.currentShownCount,
    required this.schemaRequired,
  });

  @override
  State<FieldConfigDialog> createState() => _FieldConfigDialogState();
}

class _FieldConfigDialogState extends State<FieldConfigDialog> {
  late bool _useDropdown;
  late bool _allowCustomValues;
  late bool _isRequired;
  late bool _showInCatchHistory;
  late bool _isSticky;

  late TextEditingController _optionsController;
  late TextEditingController _minController;
  late TextEditingController _maxController;
  late TextEditingController _helpTextController;

  @override
  void initState() {
    super.initState();

    _useDropdown = widget.initialValue.useDropdown;
    _allowCustomValues = widget.initialValue.allowCustomValues;
    _isRequired = widget.initialValue.isRequired;
    _showInCatchHistory = widget.initialValue.showInCatchHistory;
    _isSticky = widget.initialValue.isSticky;

    _optionsController = TextEditingController(
      text: widget.initialValue.options.join(', '),
    );
    _minController = TextEditingController(
      text: widget.initialValue.minValue?.toString() ?? '',
    );
    _maxController = TextEditingController(
      text: widget.initialValue.maxValue?.toString() ?? '',
    );
    _helpTextController = TextEditingController(
      text: widget.initialValue.helpText ?? '',
    );
  }

  @override
  void dispose() {
    _optionsController.dispose();
    _minController.dispose();
    _maxController.dispose();
    _helpTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNumeric = _looksNumeric(widget.dataType);
    final canEnableShown = widget.initialValue.showInCatchHistory || widget.currentShownCount < 8;

    return AlertDialog(
      title: Text("Configure ${widget.fieldName}"),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text("Enable dropdown / autocomplete"),
                value: _useDropdown,
                onChanged: (value) {
                  setState(() {
                    _useDropdown = value;
                  });
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text("Allow custom values"),
                subtitle: const Text(
                  "If off, users must choose from listed options.",
                ),
                value: _allowCustomValues,
                onChanged: (value) {
                  setState(() {
                    _allowCustomValues = value;
                  });
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text("Required field"),
                subtitle: widget.schemaRequired
                    ? const Text(
                        "This column is already required by the schema.",
                      )
                    : null,
                value: _isRequired || widget.schemaRequired,
                onChanged: widget.schemaRequired
                    ? null
                    : (value) {
                        setState(() {
                          _isRequired = value;
                        });
                      },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text("Sticky field"),
                subtitle: const Text(
                  "Keeps its value after a record is saved.",
                ),
                value: _isSticky,
                onChanged: (value) {
                  setState(() {
                    _isSticky = value;
                  });
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text("Show in Catch History Table."),
                subtitle: Text(
                  canEnableShown
                      ? "Display this field in the catch history table."
                      : "Maximum of 8 fields can be shown (${widget.currentShownCount}/8 selected)",
                  style: TextStyle(
                    color: canEnableShown 
                        ? null 
                        : Theme.of(context).colorScheme.error,
                  ),
                ),
                value: _showInCatchHistory,
                onChanged: canEnableShown
                    ? (value) {
                        setState(() {
                          _showInCatchHistory = value;
                        });
                      }
                    : null,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _optionsController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: "Dropdown options",
                  hintText: "Male, Female, Unknown",
                  border: OutlineInputBorder(),
                  helperText: "Comma-separated input",
                ),
              ),
              const SizedBox(height: 14),
              if (isNumeric)
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _minController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: "Min value",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _maxController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: "Max value",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                )
              else
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Numeric range constraints hidden for non-numeric field.",
                  ),
                ),
              const SizedBox(height: 14),
              TextField(
                controller: _helpTextController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Help text",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        FilledButton(
          onPressed: () {
            final updated = FieldConfig(
              useDropdown: _useDropdown,
              allowCustomValues: _allowCustomValues,
              isRequired: widget.schemaRequired ? true : _isRequired,
              showInCatchHistory: _showInCatchHistory,
              isSticky: _isSticky,
              options: _parseOptions(_optionsController.text),
              minValue: _parseNullableNum(_minController.text),
              maxValue: _parseNullableNum(_maxController.text),
              helpText: _helpTextController.text.trim().isEmpty
                  ? null
                  : _helpTextController.text.trim(),
            );

            Navigator.pop(context, updated);
          },
          child: const Text("Save"),
        ),
      ],
    );
  }

  static List<String> _parseOptions(String raw) {
    return raw
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
  }

  static num? _parseNullableNum(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    return num.tryParse(trimmed);
  }

  static bool _looksNumeric(String dataType) {
    final normalized = dataType.toLowerCase();

    return normalized.contains('int') ||
        normalized.contains('real') ||
        normalized.contains('double') ||
        normalized.contains('float') ||
        normalized.contains('decimal') ||
        normalized.contains('num');
  }
}