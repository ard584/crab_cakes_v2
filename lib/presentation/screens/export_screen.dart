import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ui_prototype/infrastructure/providers/export_provider.dart';
import 'package:ui_prototype/infrastructure/providers/settings_provider.dart';



class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  String? selectedTable;
  static const String defaultDelimiter = '\t';

  //display name -> actual delimiter value
  final Map<String, String> delimiterOptions = const {
    "Comma Separated": ",",
    "Tab Separated": "\t",
    "Semicolon Separated": ";",
    "Pipe Separated": "|",
  };

  String selectedDelimiterLabel = "Tab Separated";

  //used to avoid overwriting the user's local dropdown selections on every rebuild
  bool _loadedSettingsIntoUi = false;

  String _labelForDelimiter(String delimiter) {
    return delimiterOptions.entries
        .firstWhere(
          (entry) => entry.value == delimiter,
          orElse: () => const MapEntry("Tab Separated", "\t"),
        )
        .key;
  }

  Future<void> _persistExportSettings() async {
    final updateExportSettings = ref.read(updateExportSettingsUsecaseProvider);

    if (updateExportSettings == null) return;

    final delimiter = delimiterOptions[selectedDelimiterLabel]!;

    await updateExportSettings.execute(
      baseTable: selectedTable,
      delimiter: delimiter,
    );

    //refresh cached settings so backup/export consumers see the latest values
    ref.invalidate(projectSettingsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final exportUseCase = ref.watch(exportDataUsecaseProvider);
    final baseTablesAsync = ref.watch(exportBaseTablesProvider);
    final settingsAsync = ref.watch(projectSettingsProvider);

    final delimiter = delimiterOptions[selectedDelimiterLabel]!;

    final canExport = exportUseCase != null && selectedTable != null;

    //load persisted export settings into the local dropdown state once
    settingsAsync.whenData((settings) {
      if (_loadedSettingsIntoUi) return;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        setState(() {
          selectedTable = settings.export.baseTable;
          selectedDelimiterLabel = _labelForDelimiter(
            settings.export.delimiter ?? defaultDelimiter);
          _loadedSettingsIntoUi = true;
        });
      });
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Export')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: <Widget>[
              _ExportSettingsInfoPanel(
                selectedTable: selectedTable,
                selectedDelimiterLabel: selectedDelimiterLabel,
                delimiter: delimiter,
              ),

              const SizedBox(height: 20),

              FloatingActionButton.extended(
                onPressed: !canExport
                    ? null
                    : () async {
                        try {
                          await exportUseCase.execute(
                            selectedTable!,
                            delimiter,
                          );

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Export complete: $selectedTable',
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Export failed: $e'),
                              ),
                            );
                          }
                        }
                      },
                label: const Text('Export to File'),
                icon: const Icon(Icons.file_download),
              ),

              const SizedBox(height: 20),

              // ---------- BASE TABLE DROPDOWN ----------
              baseTablesAsync.when(
                data: (tables) {
                  //auto select the first table if none selected
                  if (tables.isNotEmpty &&
                      selectedTable == null &&
                      _loadedSettingsIntoUi) {
                    WidgetsBinding.instance.addPostFrameCallback((_) async {
                      if (mounted) {
                        setState(() {
                          selectedTable = tables.first;
                        });

                        await _persistExportSettings();
                      }
                    });
                  }

                  return DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: "Base Table",
                      border: OutlineInputBorder(),
                    ),
                    value: tables.contains(selectedTable) ? selectedTable : null,
                    items: tables.map((table) {
                      return DropdownMenuItem<String>(
                        value: table,
                        child: Text(table),
                      );
                    }).toList(),
                    onChanged: (value) async {
                      setState(() {
                        selectedTable = value;
                      });

                      await _persistExportSettings();
                    },
                  );
                },

                loading: () => const CircularProgressIndicator(),

                error: (error, stack) => Text("Error loading tables: $error"),
              ),

              const SizedBox(height: 20),

              // ---------- DELIMITER DROPDOWN ----------
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: "Delimiter",
                  border: OutlineInputBorder(),
                ),
                value: selectedDelimiterLabel,
                items: delimiterOptions.keys.map((label) {
                  return DropdownMenuItem<String>(
                    value: label,
                    child: Text(label),
                  );
                }).toList(),
                onChanged: (value) async {
                  if (value == null) return;

                  setState(() {
                    selectedDelimiterLabel = value;
                  });

                  await _persistExportSettings();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExportSettingsInfoPanel extends StatelessWidget {
  final String? selectedTable;
  final String selectedDelimiterLabel;
  final String delimiter;

  const _ExportSettingsInfoPanel({
    required this.selectedTable,
    required this.selectedDelimiterLabel,
    required this.delimiter,
  });

  @override
  Widget build(BuildContext context) {
    final tableText = selectedTable ?? 'No base table selected';

    final delimiterDisplay = delimiter == '\t' ? r'\t' : delimiter;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Export Settings',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'The base table controls which records appear as the main rows in the exported text file. '
            'Related parent/child data may be included around that table depending on the project schema.\n\n'
            'This setting is saved with the project. Automatic backups use it when creating export/data.txt. '
            'If no base table is selected, the SQLite backup will still be created, but the text export may be skipped.',
          ),
          const SizedBox(height: 14),
          Text('Base table: $tableText'),
          Text('Delimiter: $selectedDelimiterLabel ($delimiterDisplay)'),
        ],
      ),
    );
  }
}