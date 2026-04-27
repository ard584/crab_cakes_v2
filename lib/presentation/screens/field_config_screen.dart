import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ui_prototype/infrastructure/providers/flex_form_provider.dart';
import 'package:ui_prototype/infrastructure/providers/settings_provider.dart';
import 'package:ui_prototype/infrastructure/providers/field_config_providers.dart';

import 'package:ui_prototype/domain/entities/settings/field_config.dart';

class FieldConfigScreen extends ConsumerWidget {
  const FieldConfigScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectAsync = ref.watch(projectViewModelProvider);
    final settingsAsync = ref.watch(projectSettingsProvider);
    final activeTableName = ref.watch(activeTableProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Field Config')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: projectAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(child: Text("Error: $e")),
          data: (project) {
            if (project.tables.isEmpty) {
              return const Center(child: Text("No project tables available."));
            }

            final resolvedTableName = activeTableName ?? project.tables.keys.first;
            final table = project.tables[resolvedTableName];

            if (table == null) {
              return const Center(child: Text("Selected table could not be found."));
            }

            final attributes = table.attributes.values.toList();

            return settingsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text("Error: $e")),
              data: (settings) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TableChoiceChips(
                      activeTableName: resolvedTableName,
                      onTableSelected: (tableName) {
                        ref.read(activeTableProvider.notifier).setActiveTable(tableName);
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
                              itemCount: attributes.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final attribute = attributes[index];

                                final fieldName = attribute.fields.name;
                                final dataType = attribute.fields.dataType;
                                final schemaRequired = attribute.fields.isNotNullable;
                                final isForeignKey = attribute.fields.isForeignKey;
                                final isPrimaryKey = attribute.fields.isPrimaryKey;
                                final isAutoIncrement = attribute.fields.isAutoIncrement;

                                final savedConfig = settings.fieldConfig.getConfig(
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
                                  isForeignKey: isForeignKey,
                                  isPrimaryKey: isPrimaryKey,
                                  isAutoIncrement: isAutoIncrement,
                                  onEditPressed: () async {
                                    final updated = await showDialog<FieldConfig>(
                                      context: context,
                                      builder: (_) => FieldConfigDialog(
                                        initialValue: effectiveConfig,
                                        fieldName: fieldName,
                                        dataType: dataType,
                                        schemaRequired: schemaRequired,
                                        isForeignKey: isForeignKey,
                                        isPrimaryKey: isPrimaryKey,
                                        isAutoIncrement: isAutoIncrement,
                                      ),
                                    );

                                    if (updated == null || !context.mounted) return;

                                    final updateUsecase =
                                        ref.read(updateFieldConfigUsecaseProvider);

                                    if (updateUsecase == null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
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

                                      ref.invalidate(projectSettingsProvider);

                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Field config saved.'),
                                        ),
                                      );
                                    } catch (e) {
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
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

bool canHideField({
  required bool isForeignKey,
  required bool isPrimaryKey,
  required bool isAutoIncrement,
  required bool schemaRequired,
}) {
  return !isForeignKey &&
      (isAutoIncrement || (!schemaRequired && !isPrimaryKey));
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
              if (selected) onTableSelected(table.key);
            },
          );
        }).toList();

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Wrap(spacing: 8, runSpacing: 8, children: chips),
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
            child: Text("Column", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            flex: 4,
            child: Text(
              "Dropdown / Constraints",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(width: 110),
        ],
      ),
    );
  }
}

class _FieldConfigRow extends StatelessWidget {
  final String fieldName;
  final String dataType;
  final FieldConfig config;
  final bool schemaRequired;
  final bool isForeignKey;
  final bool isPrimaryKey;
  final bool isAutoIncrement;
  final VoidCallback onEditPressed;

  const _FieldConfigRow({
    required this.fieldName,
    required this.dataType,
    required this.config,
    required this.schemaRequired,
    required this.isForeignKey,
    required this.isPrimaryKey,
    required this.isAutoIncrement,
    required this.onEditPressed,
  });

  @override
  Widget build(BuildContext context) {
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
                  Text(fieldName, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(dataType, style: Theme.of(context).textTheme.bodySmall),
                  if (isPrimaryKey) ...[
                    const SizedBox(height: 6),
                    Text(
                      "Primary key field",
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  if (isAutoIncrement) ...[
                    const SizedBox(height: 6),
                    Text(
                      "Auto-increment field",
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  if (isForeignKey) ...[
                    const SizedBox(height: 6),
                    Text(
                      "Foreign key field",
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: _ConfigSummary(
              config: config,
              schemaRequired: schemaRequired,
              isForeignKey: isForeignKey,
              isPrimaryKey: isPrimaryKey,
              isAutoIncrement: isAutoIncrement,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 98,
            child: OutlinedButton(
              onPressed: onEditPressed,
              child: const Text("Edit"),
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
  final bool isForeignKey;
  final bool isPrimaryKey;
  final bool isAutoIncrement;

  const _ConfigSummary({
    required this.config,
    required this.schemaRequired,
    required this.isForeignKey,
    required this.isPrimaryKey,
    required this.isAutoIncrement,
  });

  @override
  Widget build(BuildContext context) {
    final summaryLines = <String>[];

    final showHiddenSummary = canHideField(
      isForeignKey: isForeignKey,
      isPrimaryKey: isPrimaryKey,
      isAutoIncrement: isAutoIncrement,
      schemaRequired: schemaRequired,
    );

    if (isForeignKey) {
      summaryLines.add(
        "Locked: options are populated automatically from referenced table data",
      );
    } else if (config.useDropdown) {
      summaryLines.add(
        config.options.isEmpty
            ? "Dropdown enabled, no options yet"
            : "Options: ${config.options.join(', ')}",
      );

      summaryLines.add(
        config.allowCustomValues
            ? "Custom values allowed"
            : "Restricted to listed options",
      );
    } else {
      summaryLines.add("Free text entry");
    }

    if (!isForeignKey &&
        (config.minValue != null || config.maxValue != null)) {
      summaryLines.add(
        "Range: ${config.minValue?.toString() ?? '-∞'} to ${config.maxValue?.toString() ?? '∞'}",
      );
    }

    if (schemaRequired || config.isRequired) {
      summaryLines.add("Required");
    }

    if (!isForeignKey && config.isSticky) {
      summaryLines.add("Sticky field");
    }

    if (showHiddenSummary && config.isHidden) {
      summaryLines.add("Hidden field");
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
  final bool schemaRequired;
  final bool isForeignKey;
  final bool isPrimaryKey;
  final bool isAutoIncrement;

  const FieldConfigDialog({
    super.key,
    required this.initialValue,
    required this.fieldName,
    required this.dataType,
    required this.schemaRequired,
    required this.isForeignKey,
    required this.isPrimaryKey,
    required this.isAutoIncrement,
  });

  @override
  State<FieldConfigDialog> createState() => _FieldConfigDialogState();
}

class _FieldConfigDialogState extends State<FieldConfigDialog> {
  late bool _useDropdown;
  late bool _allowCustomValues;
  late bool _isRequired;
  late bool _isSticky;
  late bool _isHidden;

  late TextEditingController _optionsController;
  late TextEditingController _minController;
  late TextEditingController _maxController;
  late TextEditingController _helpTextController;

  bool get _canHideField => canHideField(
        isForeignKey: widget.isForeignKey,
        isPrimaryKey: widget.isPrimaryKey,
        isAutoIncrement: widget.isAutoIncrement,
        schemaRequired: widget.schemaRequired,
      );

  @override
  void initState() {
    super.initState();

    _useDropdown = widget.initialValue.useDropdown;
    _allowCustomValues = widget.initialValue.allowCustomValues;
    _isRequired = widget.initialValue.isRequired;
    _isSticky = widget.initialValue.isSticky;
    _isHidden = widget.initialValue.isHidden;

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

    return AlertDialog(
      title: Text("Configure ${widget.fieldName}"),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.isForeignKey)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  child: const Text(
                    "This field is a foreign key. Its dropdown options, sticky behavior, numeric constraints, and hide behavior are locked.",
                  ),
                ),

              if (!widget.isForeignKey) ...[
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
              ],

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text("Required field"),
                subtitle: widget.schemaRequired
                    ? const Text("This column is already required by the schema.")
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

              if (!widget.isForeignKey)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text("Sticky field"),
                  subtitle: const Text("Keeps its value after a record is saved."),
                  value: _isSticky,
                  onChanged: (value) {
                    setState(() {
                      _isSticky = value;
                    });
                  },
                ),

              if (_canHideField)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text("Hidden field"),
                  subtitle: const Text("Hides this field from the data entry form."),
                  value: _isHidden,
                  onChanged: (value) {
                    setState(() {
                      _isHidden = value;
                    });
                  },
                ),

              const SizedBox(height: 8),

              if (!widget.isForeignKey)
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

              if (!widget.isForeignKey) const SizedBox(height: 14),

              if (!widget.isForeignKey && isNumeric)
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
              else if (!widget.isForeignKey)
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
              useDropdown: widget.isForeignKey ? true : _useDropdown,
              allowCustomValues:
                  widget.isForeignKey ? false : _allowCustomValues,
              isRequired: widget.schemaRequired ? true : _isRequired,
              isSticky: widget.isForeignKey ? false : _isSticky,
              isHidden: _canHideField ? _isHidden : false,
              options: widget.isForeignKey
                  ? widget.initialValue.options
                  : _parseOptions(_optionsController.text),
              minValue: widget.isForeignKey
                  ? null
                  : _parseNullableNum(_minController.text),
              maxValue: widget.isForeignKey
                  ? null
                  : _parseNullableNum(_maxController.text),
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