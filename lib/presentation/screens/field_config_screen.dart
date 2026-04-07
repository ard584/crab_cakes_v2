import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ui_prototype/infrastructure/providers/flex_form_provider.dart';
import 'package:ui_prototype/infrastructure/providers/settings_provider.dart';

import 'package:ui_prototype/domain/entities/settings/field_config.dart';
import 'package:ui_prototype/domain/entities/settings/project_settings.dart';

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

            final attributes = table.attributes.values.toList();

            return settingsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text("Error: $e")),
              data: (settings) {
                final resolvedSettings = settings ?? ProjectSettings.empty();

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
                              itemCount: attributes.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final attribute = attributes[index];
                                final fieldName = attribute.fields.name;
                                final dataType = attribute.fields.dataType;
                                final schemaRequired =
                                    attribute.fields.isNotNullable;

                                final savedConfig =
                                    resolvedSettings.fieldConfig.getConfig(
                                  table: resolvedTableName,
                                  col: fieldName,
                                );

                                final draft = savedConfig != null
                                    ? _domainToDraft(savedConfig, dataType)
                                    : FieldConfigDraft(
                                        useDropdown: false,
                                        allowCustomValues: true,
                                        isRequired: schemaRequired,
                                        options: const [],
                                        minValue: null,
                                        maxValue: null,
                                        helpText: '',
                                        dataType: dataType,
                                      );

                                return _FieldConfigRow(
                                  fieldName: fieldName,
                                  dataType: dataType,
                                  draft: draft,
                                  onEditPressed: () async {
                                    final updated =
                                        await showDialog<FieldConfigDraft>(
                                      context: context,
                                      builder: (_) => FieldConfigDialog(
                                        initialValue: draft.copy(),
                                        fieldName: fieldName,
                                        dataType: dataType,
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
                                      final domainConfig =
                                          _draftToDomainConfig(updated);

                                      await updateUsecase.execute(
                                        table: resolvedTableName,
                                        column: fieldName,
                                        config: domainConfig,
                                      );

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

  static FieldConfig _draftToDomainConfig(FieldConfigDraft draft) {
    return FieldConfig(
      useDropdown: draft.useDropdown,
      allowCustomValues: draft.allowCustomValues,
      isRequired: draft.isRequired,
      options: List<String>.from(draft.options),
      minValue: draft.minValue,
      maxValue: draft.maxValue,
      helpText: draft.helpText.trim().isEmpty ? null : draft.helpText.trim(),
    );
  }

  static FieldConfigDraft _domainToDraft(FieldConfig config, String dataType) {
    return FieldConfigDraft(
      useDropdown: config.useDropdown,
      allowCustomValues: config.allowCustomValues,
      isRequired: config.isRequired,
      options: List<String>.from(config.options),
      minValue: config.minValue?.toDouble(),
      maxValue: config.maxValue?.toDouble(),
      helpText: config.helpText ?? '',
      dataType: dataType,
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
          SizedBox(width: 110),
        ],
      ),
    );
  }
}

class _FieldConfigRow extends StatelessWidget {
  final String fieldName;
  final String dataType;
  final FieldConfigDraft draft;
  final VoidCallback onEditPressed;

  const _FieldConfigRow({
    required this.fieldName,
    required this.dataType,
    required this.draft,
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
            child: _ConfigSummary(draft: draft),
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
  final FieldConfigDraft draft;

  const _ConfigSummary({required this.draft});

  @override
  Widget build(BuildContext context) {
    final summaryLines = <String>[];

    if (draft.useDropdown) {
      if (draft.options.isEmpty) {
        summaryLines.add("Dropdown enabled, no options yet");
      } else {
        summaryLines.add("Options: ${draft.options.join(', ')}");
      }
    } else {
      summaryLines.add("Free text entry");
    }

    summaryLines.add(
      draft.allowCustomValues
          ? "Custom values allowed"
          : "Restricted to listed options",
    );

    if (draft.minValue != null || draft.maxValue != null) {
      summaryLines.add(
        "Range: ${draft.minValue?.toString() ?? '-∞'} to ${draft.maxValue?.toString() ?? '∞'}",
      );
    }

    if (draft.isRequired) {
      summaryLines.add("Required");
    }

    if (draft.helpText.trim().isNotEmpty) {
      summaryLines.add("Help: ${draft.helpText.trim()}");
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
  final FieldConfigDraft initialValue;
  final String fieldName;
  final String dataType;

  const FieldConfigDialog({
    super.key,
    required this.initialValue,
    required this.fieldName,
    required this.dataType,
  });

  @override
  State<FieldConfigDialog> createState() => _FieldConfigDialogState();
}

class _FieldConfigDialogState extends State<FieldConfigDialog> {
  late bool _useDropdown;
  late bool _allowCustomValues;
  late bool _isRequired;

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
      text: widget.initialValue.helpText,
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
                value: _isRequired,
                onChanged: (value) {
                  setState(() {
                    _isRequired = value;
                  });
                },
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
            final updated = FieldConfigDraft(
              useDropdown: _useDropdown,
              allowCustomValues: _allowCustomValues,
              isRequired: _isRequired,
              options: _parseOptions(_optionsController.text),
              minValue: _parseNullableNum(_minController.text),
              maxValue: _parseNullableNum(_maxController.text),
              helpText: _helpTextController.text.trim(),
              dataType: widget.dataType,
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

class FieldConfigDraft {
  final bool useDropdown;
  final bool allowCustomValues;
  final bool isRequired;
  final List<String> options;
  final num? minValue;
  final num? maxValue;
  final String helpText;
  final String dataType;

  const FieldConfigDraft({
    required this.useDropdown,
    required this.allowCustomValues,
    required this.isRequired,
    required this.options,
    required this.minValue,
    required this.maxValue,
    required this.helpText,
    required this.dataType,
  });

  FieldConfigDraft copy() {
    return FieldConfigDraft(
      useDropdown: useDropdown,
      allowCustomValues: allowCustomValues,
      isRequired: isRequired,
      options: List<String>.from(options),
      minValue: minValue,
      maxValue: maxValue,
      helpText: helpText,
      dataType: dataType,
    );
  }
}