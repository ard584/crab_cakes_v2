import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:crab_cakes/infrastructure/providers/schema_discovery_provider.dart';
import 'package:crab_cakes/infrastructure/providers/settings_provider.dart';
//import 'package:crab_cakes/domain/entities/settings/project_settings.dart';
import 'package:crab_cakes/presentation/screens/settings_screen.dart';
import 'package:crab_cakes/presentation/utils/logger.dart';

class ScannerTargetSection extends ConsumerStatefulWidget {
  const ScannerTargetSection({super.key});

  @override
  ConsumerState<ScannerTargetSection> createState() =>
      _ScannerTargetSectionState();
}

class _ScannerTargetSectionState extends ConsumerState<ScannerTargetSection> {
  String? _tableOverride;
  String? _columnOverride;
  bool _isSaving = false;

  bool _isInternalColumn(String columnName) {
    return columnName.startsWith('__');
  }

  List<String> _filterVisibleColumns(List<String> columns) {
    return columns.where((column) => !_isInternalColumn(column)).toList();
  }

  Future<void> _saveScannerTarget({
    required String? table,
    required String? column,
  }) async {
    final updateScannerTarget = ref.read(updateScannerTargetUsecaseProvider);

    if (updateScannerTarget == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await updateScannerTarget.execute(
        targetTable: table,
        targetColumn: column,
      );

      ref.invalidate(projectSettingsProvider);

      log.d('Saved scanner target: table=$table, column=$column');
    } catch (e, st) {
      log.e('Failed to save scanner target', error: e, stackTrace: st);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save scanner target: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(projectSettingsProvider);
    final tablesAsync = ref.watch(schemaTablesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ReusableLeftAlignedText(text: 'Scanner Target Field'),
        Container(
          decoration: reusableBoxDecoration,
          padding: reusablePadding,
          child: settingsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
            error: (error, stack) {
              return Text('Error loading settings: $error');
            },
            data: (settings) {
              final savedTable = settings.scanner.targetTable;
              final savedColumn = settings.scanner.targetColumn;

              final effectiveTable = _tableOverride ?? savedTable;

              final columnsAsync = effectiveTable == null
                  ? const AsyncValue.data(<String>[])
                  : ref.watch(tableColumnsProvider(effectiveTable));

              return tablesAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                ),
                error: (error, stack) {
                  return Text('Error loading tables: $error');
                },
                data: (tables) {
                  final visibleTable =
                      tables.contains(effectiveTable) ? effectiveTable : null;

                  return columnsAsync.when(
                    loading: () => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: visibleTable,
                          decoration: const InputDecoration(
                            labelText: 'Target Table',
                            border: OutlineInputBorder(),
                          ),
                          items: tables
                              .map(
                                (table) => DropdownMenuItem<String>(
                                  value: table,
                                  child: Text(table),
                                ),
                              )
                              .toList(),
                          onChanged: _isSaving
                              ? null
                              : (value) async {
                                  setState(() {
                                    _tableOverride = value;
                                    _columnOverride = null;
                                  });

                                  await _saveScannerTarget(
                                    table: value,
                                    column: null,
                                  );
                                },
                        ),
                        const SizedBox(height: 16),
                        const CircularProgressIndicator(),
                      ],
                    ),
                    error: (error, stack) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DropdownButtonFormField<String>(
                            initialValue: visibleTable,
                            decoration: const InputDecoration(
                              labelText: 'Target Table',
                              border: OutlineInputBorder(),
                            ),
                            items: tables
                                .map(
                                  (table) => DropdownMenuItem<String>(
                                    value: table,
                                    child: Text(table),
                                  ),
                                )
                                .toList(),
                            onChanged: _isSaving
                                ? null
                                : (value) async {
                                    setState(() {
                                      _tableOverride = value;
                                      _columnOverride = null;
                                    });

                                    await _saveScannerTarget(
                                      table: value,
                                      column: null,
                                    );
                                  },
                          ),
                          const SizedBox(height: 16),
                          Text('Error loading columns: $error'),
                        ],
                      );
                    },
                    data: (columns) {
                      final visibleColumns = _filterVisibleColumns(columns);

                      final effectiveColumn = _columnOverride ?? savedColumn;

                      final visibleColumn =
                          visibleColumns.contains(effectiveColumn)
                              ? effectiveColumn
                              : null;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DropdownButtonFormField<String>(
                            initialValue: visibleTable,
                            decoration: const InputDecoration(
                              labelText: 'Target Table',
                              border: OutlineInputBorder(),
                            ),
                            items: tables
                                .map(
                                  (table) => DropdownMenuItem<String>(
                                    value: table,
                                    child: Text(table),
                                  ),
                                )
                                .toList(),
                            onChanged: _isSaving
                                ? null
                                : (value) async {
                                    setState(() {
                                      _tableOverride = value;
                                      _columnOverride = null;
                                    });

                                    await _saveScannerTarget(
                                      table: value,
                                      column: null,
                                    );
                                  },
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            initialValue: visibleColumn,
                            decoration: const InputDecoration(
                              labelText: 'Target Column',
                              border: OutlineInputBorder(),
                            ),
                            items: visibleColumns
                                .map(
                                  (column) => DropdownMenuItem<String>(
                                    value: column,
                                    child: Text(column),
                                  ),
                                )
                                .toList(),
                            onChanged: (visibleTable == null || _isSaving)
                                ? null
                                : (value) async {
                                    setState(() {
                                      _columnOverride = value;
                                    });

                                    await _saveScannerTarget(
                                      table: visibleTable,
                                      column: value,
                                    );
                                  },
                          ),
                          if (_isSaving) ...[
                            const SizedBox(height: 12),
                            const Row(
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text('Saving scanner target...'),
                              ],
                            ),
                          ],
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}