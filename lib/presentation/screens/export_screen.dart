import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crab_cakes/application/sync/dtos/sync_plan.dart';

import 'package:crab_cakes/infrastructure/providers/export_provider.dart';
import 'package:crab_cakes/infrastructure/providers/external_backup_provider.dart';
import 'package:crab_cakes/infrastructure/providers/project_sync_providers.dart';
import 'package:crab_cakes/infrastructure/providers/settings_provider.dart';

import 'package:crab_cakes/application/backup/dtos/backup_target.dart';

class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  final ScrollController _scrollController = ScrollController();

  late final Future<List<BackupTarget>> _drivesFuture;

  String? selectedTable;
  static const String defaultDelimiter = '\t';

  // Store selected drive paths instead of selected BackupTarget objects.
  // This avoids DropdownButton object-identity issues after rebuilds.
  String? selectedSyncDriveAPath;
  String? selectedSyncDriveBPath;

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

  @override
  void initState() {
    super.initState();

    _drivesFuture = ref.read(discoverDevicesProvider).execute();

    // Clear old sync preview/error/success state when this screen is opened.
    // This prevents stale preview results from showing after navigating away
    // and coming back with no drives selected.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.invalidate(projectSyncNotifierProvider);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _clearSyncPreview() {
    ref.invalidate(projectSyncNotifierProvider);
  }

  String _labelForDelimiter(String delimiter) {
    return delimiterOptions.entries
        .firstWhere(
          (entry) => entry.value == delimiter,
          orElse: () => const MapEntry("Tab Separated", "\t"),
        )
        .key;
  }

  Future<void> _persistExportSettings({
    String? baseTable,
    String? delimiter,
  }) async {
    final updateExportSettings = ref.read(updateExportSettingsUsecaseProvider);

    if (updateExportSettings == null) return;

    // Read current persisted settings first so updating only the delimiter
    // does not accidentally overwrite the saved base table with null.
    final currentSettings = await ref.read(projectSettingsProvider.future);

    final resolvedBaseTable = baseTable ?? currentSettings.export.baseTable;
    final resolvedDelimiter =
        delimiter ?? currentSettings.export.delimiter ?? defaultDelimiter;

    await updateExportSettings.execute(
      baseTable: resolvedBaseTable,
      delimiter: resolvedDelimiter,
    );

    //refresh cached settings so backup/export consumers see the latest values
    ref.invalidate(projectSettingsProvider);

    // Optional debugging while verifying persistence:
    // final refreshed = await ref.read(projectSettingsProvider.future);
    // debugPrint('Persisted export base table: ${refreshed.export.baseTable}');
    // debugPrint('Persisted export delimiter: ${refreshed.export.delimiter}');
  }

  Future<void> _previewDriveSync(BuildContext context) async {
    if (selectedSyncDriveAPath == null || selectedSyncDriveBPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select two drives before previewing sync.'),
        ),
      );
      return;
    }

    if (selectedSyncDriveAPath == selectedSyncDriveBPath) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select two different drives before previewing sync.'),
        ),
      );
      return;
    }

    try {
      final dbPathA = await _findProjectDatabaseOnDrive(
        selectedSyncDriveAPath!,
      );

      final dbPathB = await _findProjectDatabaseOnDrive(
        selectedSyncDriveBPath!,
      );

      await ref.read(projectSyncNotifierProvider.notifier).previewSync(
            activeDbPath: dbPathA,
            candidateDbPath: dbPathB,
          );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sync preview failed: $e')),
      );
    }
  }

  Future<void> _applyDriveSync(BuildContext context) async {
    if (selectedSyncDriveAPath == null || selectedSyncDriveBPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select two drives before syncing.'),
        ),
      );
      return;
    }

    if (selectedSyncDriveAPath == selectedSyncDriveBPath) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select two different drives before syncing.'),
        ),
      );
      return;
    }

    try {
      final dbPathA = await _findProjectDatabaseOnDrive(
        selectedSyncDriveAPath!,
      );

      final dbPathB = await _findProjectDatabaseOnDrive(
        selectedSyncDriveBPath!,
      );

      final exportPathA = _exportPathForProjectDatabase(dbPathA);
      final exportPathB = _exportPathForProjectDatabase(dbPathB);

      // Read the saved export settings so synced drive exports are refreshed
      // using the same base table and delimiter as normal backups/exports.
      final settings = await ref.read(projectSettingsProvider.future);

      await ref.read(projectSyncNotifierProvider.notifier).applySync(
            activeDbPath: dbPathA,
            candidateDbPath: dbPathB,
            activeExportPath: exportPathA,
            candidateExportPath: exportPathB,
            baseTable: settings.export.baseTable,
            delim: settings.export.delimiter ?? defaultDelimiter,
          );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sync completed successfully.')),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sync failed: $e')),
      );
    }
  }

  Future<String> _findProjectDatabaseOnDrive(String driveRootPath) async {
    final projectsDir = Directory(
      '$driveRootPath'
      '${Platform.pathSeparator}CRABCAKES'
      '${Platform.pathSeparator}projects',
    );

    if (!await projectsDir.exists()) {
      throw Exception(
        'Could not find CRABCAKES/projects on drive: $driveRootPath',
      );
    }

    final sqliteFiles = await projectsDir
        .list(recursive: true)
        .where((entity) {
          if (entity is! File) return false;

          final path = entity.path.toLowerCase();

          return path.endsWith('.sqlite') ||
              path.endsWith('.sqlite3') ||
              path.endsWith('.db');
        })
        .cast<File>()
        .toList();

    if (sqliteFiles.isEmpty) {
      throw Exception(
        'No project database was found under ${projectsDir.path}.',
      );
    }

    // For now, use the most recently modified DB if multiple are found.
    // Later, this should be stricter and select by matching projectGuid.
    sqliteFiles.sort((a, b) {
      final aModified = a.lastModifiedSync();
      final bModified = b.lastModifiedSync();

      return bModified.compareTo(aModified);
    });

    return sqliteFiles.first.path;
  }

  String _exportPathForProjectDatabase(String dbPath) {
    final dbFile = File(dbPath);
    final dataDir = dbFile.parent;
    final projectDir = dataDir.parent;

    return '${projectDir.path}${Platform.pathSeparator}export${Platform.pathSeparator}data.txt';
  }

  @override
  Widget build(BuildContext context) {
    final exportUseCase = ref.watch(exportDataUsecaseProvider);
    final baseTablesAsync = ref.watch(exportBaseTablesProvider);
    final settingsAsync = ref.watch(projectSettingsProvider);
    final syncState = ref.watch(projectSyncNotifierProvider);

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
            settings.export.delimiter ?? defaultDelimiter,
          );
          _loadedSettingsIntoUi = true;
        });
      });
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Export')),
      body: SingleChildScrollView(
        key: const PageStorageKey<String>('export-screen-scroll-view'),
        controller: _scrollController,
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
                  final safeSelectedTable =
                      tables.contains(selectedTable) ? selectedTable : null;

                  return DropdownButtonFormField<String>(
                    key: ValueKey('base-table-$safeSelectedTable'),
                    decoration: const InputDecoration(
                      labelText: "Base Table",
                      border: OutlineInputBorder(),
                    ),
                    initialValue: safeSelectedTable,
                    items: tables.map((table) {
                      return DropdownMenuItem<String>(
                        value: table,
                        child: Text(table),
                      );
                    }).toList(),
                    onChanged: (value) async {
                      if (value == null) return;

                      setState(() {
                        selectedTable = value;
                      });

                      await _persistExportSettings(baseTable: value);
                    },
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (error, stack) => Text("Error loading tables: $error"),
              ),

              const SizedBox(height: 20),

              // ---------- DELIMITER DROPDOWN ----------
              DropdownButtonFormField<String>(
                key: ValueKey('delimiter-$selectedDelimiterLabel'),
                decoration: const InputDecoration(
                  labelText: "Delimiter",
                  border: OutlineInputBorder(),
                ),
                initialValue: selectedDelimiterLabel,
                items: delimiterOptions.keys.map((label) {
                  return DropdownMenuItem<String>(
                    value: label,
                    child: Text(label),
                  );
                }).toList(),
                onChanged: (value) async {
                  if (value == null) return;

                  final newDelimiter = delimiterOptions[value]!;

                  setState(() {
                    selectedDelimiterLabel = value;
                  });

                  await _persistExportSettings(delimiter: newDelimiter);
                },
              ),

              const SizedBox(height: 32),

              const Divider(),

              const SizedBox(height: 24),

              _DataSyncPanel(
                drivesFuture: _drivesFuture,
                selectedDriveAPath: selectedSyncDriveAPath,
                selectedDriveBPath: selectedSyncDriveBPath,
                syncState: syncState,
                onDriveAChanged: (path) {
                  setState(() {
                    selectedSyncDriveAPath = path;

                    if (selectedSyncDriveBPath == path) {
                      selectedSyncDriveBPath = null;
                    }
                  });

                  _clearSyncPreview();
                },
                onDriveBChanged: (path) {
                  setState(() {
                    selectedSyncDriveBPath = path;

                    if (selectedSyncDriveAPath == path) {
                      selectedSyncDriveAPath = null;
                    }
                  });

                  _clearSyncPreview();
                },
                onPreviewSync: () => _previewDriveSync(context),
                onApplySync: () => _applyDriveSync(context),
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

class _DataSyncPanel extends StatelessWidget {
  final Future<List<BackupTarget>> drivesFuture;
  final String? selectedDriveAPath;
  final String? selectedDriveBPath;
  final ProjectSyncState syncState;
  final ValueChanged<String?> onDriveAChanged;
  final ValueChanged<String?> onDriveBChanged;
  final VoidCallback onPreviewSync;
  final VoidCallback onApplySync;

  const _DataSyncPanel({
    required this.drivesFuture,
    required this.selectedDriveAPath,
    required this.selectedDriveBPath,
    required this.syncState,
    required this.onDriveAChanged,
    required this.onDriveBChanged,
    required this.onPreviewSync,
    required this.onApplySync,
  });

  @override
  Widget build(BuildContext context) {
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
      child: FutureBuilder<List<BackupTarget>>(
        future: drivesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Text('Error discovering drives: ${snapshot.error}');
          }

          final drives = snapshot.data ?? [];

          final drivePaths = drives.map((drive) => drive.drivePath).toSet();

          final safeSelectedDriveAPath =
              drivePaths.contains(selectedDriveAPath)
                  ? selectedDriveAPath
                  : null;

          final safeSelectedDriveBPath =
              drivePaths.contains(selectedDriveBPath)
                  ? selectedDriveBPath
                  : null;

          final firstDriveOptions = drives
              .where((drive) => drive.drivePath != safeSelectedDriveBPath)
              .toList();

          final secondDriveOptions = drives
              .where((drive) => drive.drivePath != safeSelectedDriveAPath)
              .toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Data Sync',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'Select two backup drives to compare their CRABCAKES project databases. '
                'The app will only sync them if they belong to the same project and schema.',
              ),
              const SizedBox(height: 18),

              DropdownButtonFormField<String>(
                key: ValueKey(
                  'first-drive-$safeSelectedDriveAPath-$safeSelectedDriveBPath',
                ),
                decoration: const InputDecoration(
                  labelText: 'First Drive',
                  border: OutlineInputBorder(),
                ),
                initialValue: safeSelectedDriveAPath,
                items: firstDriveOptions.map((drive) {
                  return DropdownMenuItem<String>(
                    value: drive.drivePath,
                    child: Text(drive.drivePath),
                  );
                }).toList(),
                onChanged: onDriveAChanged,
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                key: ValueKey(
                  'second-drive-$safeSelectedDriveAPath-$safeSelectedDriveBPath',
                ),
                decoration: const InputDecoration(
                  labelText: 'Second Drive',
                  border: OutlineInputBorder(),
                ),
                initialValue: safeSelectedDriveBPath,
                items: secondDriveOptions.map((drive) {
                  return DropdownMenuItem<String>(
                    value: drive.drivePath,
                    child: Text(drive.drivePath),
                  );
                }).toList(),
                onChanged: onDriveBChanged,
              ),

              const SizedBox(height: 18),

              if (syncState.isLoading) ...[
                const LinearProgressIndicator(),
                const SizedBox(height: 14),
              ],

              if (syncState.errorMessage != null) ...[
                Text(
                  syncState.errorMessage!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                const SizedBox(height: 14),
              ],

              if (syncState.successMessage != null) ...[
                Text(syncState.successMessage!),
                const SizedBox(height: 14),
              ],

              if (syncState.plan != null) ...[
                _SyncPlanSummary(plan: syncState.plan!),
                const SizedBox(height: 18),
              ],

              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: syncState.isLoading ? null : onPreviewSync,
                    icon: const Icon(Icons.search),
                    label: const Text('Preview Sync'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: syncState.isLoading || syncState.plan == null
                        ? null
                        : onApplySync,
                    icon: const Icon(Icons.sync),
                    label: const Text('Run Sync'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SyncPlanSummary extends StatelessWidget {
  final SyncPlan plan;

  const _SyncPlanSummary({
    required this.plan,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sync Preview',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Text('Rows to copy into first drive: ${plan.totalInsertsToActive}'),
          Text(
            'Rows to copy into second drive: ${plan.totalInsertsToCandidate}',
          ),
          Text('Rows to update in first drive: ${plan.totalUpdatesToActive}'),
          Text(
            'Rows to update in second drive: ${plan.totalUpdatesToCandidate}',
          ),
          Text('Conflicts: ${plan.totalConflicts}'),
        ],
      ),
    );
  }
}