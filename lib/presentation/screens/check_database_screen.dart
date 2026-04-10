import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:ui_prototype/domain/db_table.dart';
import 'package:ui_prototype/infrastructure/project/active_project/pluto_grid_constructor.dart';
import 'package:ui_prototype/infrastructure/providers/delete_rows_provider.dart';
import 'package:ui_prototype/infrastructure/providers/flex_form_provider.dart';
import 'package:ui_prototype/infrastructure/providers/pluto_update_rows_provider.dart';
import 'package:ui_prototype/infrastructure/providers/project_database_provider.dart';
import 'package:ui_prototype/presentation/dialogs/confirm_delete.dart';
import 'package:ui_prototype/presentation/adapters/pluto_grid_adapter.dart';
import 'package:ui_prototype/presentation/dialogs/confirm_update_edit_grid.dart';

Widget getTablesChoiceChips(WidgetRef ref) {
  final projectAsync = ref.watch(projectViewModelProvider);
  final tableName = ref.watch(activeTableProvider);

  return projectAsync.when(
    data: (project) {
      final chips = project.tables.entries.map((table) {
        return ChoiceChip(
          label: Text(table.key),
          selected: table.key == tableName,
          onSelected: (bool selected) {
            if (selected) {
              // Update active table
              ref.read(activeTableProvider.notifier).setActiveTable(table.key);
            }
          },
        );
      }).toList();

      return Wrap(spacing: 8, children: chips);
    },
    error: (e, st) {
      return Center(child: Text(e.toString()));
    },
    loading: () {
      return Center(child: CircularProgressIndicator());
    },
  );
}

class CheckDatabaseScreen extends ConsumerStatefulWidget {
  const CheckDatabaseScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _CheckDatabaseScreenState();
  }
}

class _CheckDatabaseScreenState extends ConsumerState<CheckDatabaseScreen> {
  PlutoGridStateManager? stateManager;
  String? _lastTableName;

  bool showDeleteButton = false;

  // Create caches
  final Map<String, List<PlutoRow>> _tableRowsCache = {};
  final Map<String, Set<Key>> _tableUpdatedKeysCache = {};

  // Pluto grid constructor
  PlutoGridConstructor constructor = PlutoGridConstructor();

  void resetTable(DbTable table) {
    final repo = ref.read(projectDatabaseProvider);
    final databaseRows = repo.getAllRows(table.name);

    final rows = databaseRows.map((row) {
      PlutoRow currentRow = constructor.constructRow(table, row);
      final checkRow = PlutoCell(value: "");
      currentRow.cells['check_box'] = checkRow;
      return currentRow;
    }).toList();

    setState(() {
      _tableUpdatedKeysCache[table.name]?.clear();
      _tableRowsCache[table.name] = rows;
    });

    final PlutoGridStateManager? currentStateManager = stateManager;
    if (currentStateManager != null) {
      currentStateManager.removeAllRows();
      currentStateManager.appendRows(rows);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tableName = ref.watch(activeTableProvider);

    void updateShowDeleteButton() {
      if (stateManager != null && stateManager!.checkedRows.isNotEmpty) {
        setState(() {
          showDeleteButton = true;
        });
      } else {
        setState(() {
          showDeleteButton = false;
        });
      }
    }

    if (tableName == null) {
      return Center(child: Text("TableName is null."));
    }

    // Update lastTableName if it changed
    if (tableName != _lastTableName) {
      stateManager = null;
      _lastTableName = tableName;
    }

    // Initialize and get keys specific to active table
    _tableUpdatedKeysCache.putIfAbsent(tableName, () => {});
    final currentUpdatedKeys = _tableUpdatedKeysCache[tableName];

    // If current updated keys is empty (should never be)
    if (currentUpdatedKeys == null) {
      // Return error message
      return Center(child: Text("Current updated keys is null."));
    }

    int rowCount = currentUpdatedKeys.length;

    final repo = ref.watch(projectDatabaseProvider);
    final table = repo.getTableSchema(tableName);

    // Create rows and columns
    List<PlutoRow> rows;
    List<PlutoColumn> columns;

    // Extract cached rows map result
    final List<PlutoRow>? cachedRows = _tableRowsCache[tableName];

    // Check if cached table exists
    if (cachedRows != null) {
      // Set rows to cached rows
      rows = cachedRows;
    } else {
      // Get rows from database
      final dbRows = repo.getAllRows(tableName);

      // Convert db rows to pluto rows
      rows = dbRows.map((row) {
        PlutoRow currentRow = constructor.constructRow(table, row);
        final checkRow = PlutoCell(value: "");
        currentRow.cells['check_box'] = checkRow;
        return currentRow;
      }).toList();

      // Update rows cache
      _tableRowsCache[tableName] = rows;
    }

    // Create column for checkbox (used with delete button)
    final checkCol = PlutoColumn(
      title: '',
      field: 'check_box',
      type: PlutoColumnType.text(),
      enableEditingMode: false,
      readOnly: false,
      enableRowChecked: true,
      width: 80,
    );

    // Create columns
    columns = constructor.constructColumns(table);

    return Scaffold(
      appBar: AppBar(title: const Text('View Entries')),
<<<<<<< HEAD
      floatingActionButton: AnimatedSize(
        duration: Duration(milliseconds: 400),
        curve: Curves.easeInOutCubicEmphasized,
        clipBehavior: Clip.none,
        child: TweenAnimationBuilder<Color?>(
        duration: Duration(milliseconds: 500),
=======
      floatingActionButton: TweenAnimationBuilder<Color?>(
        duration: Duration(milliseconds: 1000),
        curve: Curves.easeOut,
>>>>>>> main
        tween: ColorTween(
          end: rowCount > 0
              ? scheme.primaryContainer
              : scheme.surfaceContainerHighest,
        ),
        builder: (context, color, child) {
<<<<<<< HEAD

            final rowString = (rowCount == 1) ? "row" : "rows";
            final prompt = "Update $rowCount $rowString";
          return FloatingActionButton.extended(
            onPressed: rowCount > 0
                ? () async {
                    final currentStateManager = stateManager;
                    if (currentStateManager == null) return;

                    String promptRows = "rows";
                    final selectedRowKeys = currentUpdatedKeys.toList();

                    if (selectedRowKeys.length == 1) {
                      promptRows = "row";
                    }

                    final result = await confirmUpdateEditGrid(
                      context,
                      "Are you sure you want to update ${selectedRowKeys.length} $promptRows?",
                    );

=======
          final rowString = (rowCount == 1) ? "row" : "rows";
          final prompt = "Update $rowCount $rowString";
          return FloatingActionButton.extended(
            onPressed: rowCount > 0
                ? () async {
                    final currentStateManager = stateManager;
                    if (currentStateManager == null) return;

                    String promptRows = "rows";
                    final selectedRowKeys = currentUpdatedKeys.toList();

                    if (selectedRowKeys.length == 1) {
                      promptRows = "row";
                    }

                    final result = await confirmUpdateEditGrid(
                      context,
                      "Are you sure you want to update ${selectedRowKeys.length} $promptRows?",
                    );

>>>>>>> main
                    if (result == EditGridAction.update) {
                      // Get state manager
                      final stateManager = currentStateManager;

                      // Get all updated row identifiers
                      final List<Key> editedRowIdentifiers = currentUpdatedKeys
                          .toList();

                      // Get edited rows
                      final editedRows = extractPlutoRowsByKeys(
                        editedRowIdentifiers,
                        stateManager,
                      );

                      final updater = ref.read(plutoUpdateRowsProvider);
                      updater.updateFromPluto(rows: editedRows, table: table);

                      // Clear cached keys
                      setState(() {
                        currentUpdatedKeys.clear();
                      });
                    } else if (result == EditGridAction.abandon) {
                      resetTable(table);
                    }
                  }
                : null,
<<<<<<< HEAD
              label: Text(prompt),
            backgroundColor: color,
          );
        },
      ),
=======

            label: AnimatedSize(
              duration: Duration(milliseconds: 500),
              curve: Curves.fastEaseInToSlowEaseOut,
              clipBehavior: Clip.none,
              child: Text(prompt),
            ),

            backgroundColor: color,
          );
        },
>>>>>>> main
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsetsGeometry.directional(bottom: 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,

                    child: getTablesChoiceChips(ref),
                  ),
                ),
              ),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: showDeleteButton
                        ? () async {
                            final currentStateManager = stateManager;
                            if (currentStateManager == null) return;

                            final selectedRows =
                                currentStateManager.checkedRows;

                            String promptRows = "rows";

                            if (selectedRows.length == 1) {
                              promptRows = "row";
                            }

                            final delete = await confirmDelete(
                              context,
                              "Are you sure you want to delete ${selectedRows.length} $promptRows?",
                            );

                            if (delete) {
                              // Get dbRows from PlutoRows
                              final identifiers = extractIdentifiers(
                                selectedRows,
                              );

                              // Call use case
                              final deleteRowsUseCase = ref.read(
                                deleteRowsProvider,
                              );

                              deleteRowsUseCase(
                                tableName: tableName,
                                identifiers: identifiers,
                              );

                              // Remove rows from stateManager
                              currentStateManager.removeRows(selectedRows);

                              // Remove rows from cache
                              _tableRowsCache[tableName]?.removeWhere(
                                (row) => selectedRows.contains(row),
                              );

                              // Remove keys from updated cache
                              currentUpdatedKeys.removeWhere(
                                (key) =>
                                    selectedRows.any((row) => row.key == key),
                              );

                              // Reset delete button
                              setState(() {
                                showDeleteButton = false;
                              });
                            }
                          }
                        : null,
                    icon: const Icon(Icons.delete),
                    label: Text('Delete'),
                  ),
                ],
              ),
              Expanded(
                child: PlutoGrid(
                  key: ValueKey(tableName),
                  columns: [checkCol, ...columns],
                  rows: rows,
                  mode: PlutoGridMode.normal,
                  onLoaded: (PlutoGridOnLoadedEvent event) {
                    stateManager = event.stateManager;
                  },
                  onChanged: (event) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;

                      setState(() {
                        currentUpdatedKeys.add(event.row.key);
                      });
                    });
                  },
                  onRowChecked: (event) {
                    updateShowDeleteButton();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
