import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:ui_prototype/domain/entities/row_identifier.dart';
import 'package:ui_prototype/infrastructure/project/active_project/pluto_grid_constructor.dart';
import 'package:ui_prototype/infrastructure/providers/flex_form_provider.dart';
import 'package:ui_prototype/infrastructure/providers/pluto/pluto_delete_rows_provider.dart';
import 'package:ui_prototype/infrastructure/providers/pluto/pluto_edited_rows_provider.dart';
import 'package:ui_prototype/infrastructure/providers/pluto/pluto_update_rows_provider.dart';
import 'package:ui_prototype/infrastructure/providers/project_database_provider.dart';
import 'package:ui_prototype/presentation/dialogs/confirm_delete.dart';
import 'package:ui_prototype/presentation/adapters/pluto_grid_adapter.dart';
import 'package:ui_prototype/presentation/dialogs/confirm_update.dart';

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

  bool _showDeleteButton = false;
  // final Set<Key> _updatedRowKeys = {};

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tableName = ref.watch(activeTableProvider);
    final editedRowsMap = ref.watch(plutoEditedRowsProvider)[tableName] ?? {};
    final rowCount = editedRowsMap.length;

    void _updateShowDeleteButton() {
      final sm = stateManager;
      if (sm == null) return;
      if (sm.checkedRows.isNotEmpty) {
        print("ENABLING SHOW DELETE BUTTON");

        setState(() {
          _showDeleteButton = true;
        });
      } else {
        setState(() {
          _showDeleteButton = false;
        });
      }
    }

    if (tableName == null) {
      return Center(child: Text("TableName is null."));
    }

    final repo = ref.watch(projectDatabaseProvider);
    final table = repo.getTableSchema(tableName);

    final constructor = PlutoGridConstructor();
    List<PlutoColumn> columns = constructor.constructColumns(table);
    final dbRows = repo.getAllRows(tableName);

    final List<PlutoRow> rows = dbRows.map((row) {
      PlutoRow currentRow = constructor.constructRow(table, row);

      print(currentRow.key.runtimeType);

      final id = (currentRow.key as ValueKey<RowIdentifier>).value;
      final PlutoRow? editedRow = editedRowsMap[id];

      final workingRow = editedRow ?? currentRow;
      workingRow.cells['check_box'] = PlutoCell(value: '');

      return workingRow;
    }).toList();

    final check_col = PlutoColumn(
      title: '',
      field: 'check_box',
      type: PlutoColumnType.text(),
      enableEditingMode: false,
      readOnly: false,
      enableRowChecked: true,
      width: 80,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('View Entries')),
      floatingActionButton: AnimatedSize(
        duration: Duration(milliseconds: 400),
        curve: Curves.easeInOutCubicEmphasized,
        clipBehavior: Clip.none,
        child: TweenAnimationBuilder<Color?>(
          duration: Duration(milliseconds: 300),
          tween: ColorTween(
            end: rowCount > 0
                ? scheme.primaryContainer
                : scheme.surfaceContainerHighest,
          ),
          builder: (context, color, child) {
            return FloatingActionButton.extended(
              onPressed: rowCount > 0
                  ? () async {
                      final currentStateManager = stateManager;
                      if (currentStateManager == null) return;

                      String promptRows = "rows";
                      final selectedRowKeys = editedRowsMap.keys.toList();

                      if (selectedRowKeys.length == 1) {
                        promptRows = "row";
                      }

                      final update = await confirmUpdate(
                        context,
                        "Are you sure you want to update ${selectedRowKeys.length} $promptRows?",
                      );

                      if (update) {
                        // Get state manager
                        final stateManager = currentStateManager;

                        // Get all updated row identifiers
                        // final List<Key> editedRowIdentifiers = _updatedRowKeys
                        //     .toList();
                        final List<RowIdentifier> editedRowIdentifiers =
                            editedRowsMap.keys.toList();

                        // Get edited rows
                        final editedRows = extractPlutoRowsByKeys(
                          editedRowIdentifiers,
                          stateManager,
                        );

                        print("EDITED ROWS: $editedRows");

                        final updater = ref.read(plutoUpdateRowsProvider);
                        updater.updateFromPluto(rows: editedRows, table: table);
                      }
                    }
                  : null,
              label: Text("Update $rowCount rows"),
              backgroundColor: color,
            );
          },
        ),
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
                    onPressed: _showDeleteButton
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
                              // Call
                              final deleter = ref.read(plutoDeleteRowsProvider);
                              deleter.deleteFromPluto(
                                rows: selectedRows,
                                table: table,
                              );

                              // Remove rows from stateManager
                              currentStateManager.removeRows(selectedRows);

                              // Reset delete button
                              setState(() {
                                _showDeleteButton = false;
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
                  columns: [check_col, ...columns],
                  rows: rows,
                  mode: PlutoGridMode.normal,
                  onLoaded: (PlutoGridOnLoadedEvent event) {
                    stateManager = event.stateManager;
                  },
                  onChanged: (event) {
                    final tableName = ref.read(activeTableProvider);
                    if (tableName == null) return;

                    print(event.row.key.runtimeType);

                    final id = (event.row.key as ValueKey<RowIdentifier>).value;
                    print("ID: $id");

                    final edited = ref.read(plutoEditedRowsProvider.notifier);

                    Future.microtask(() {
                      edited.state = {
                        ...edited.state,
                        tableName: {
                          ...(edited.state[tableName] ?? {}),
                          id: event.row,
                        },
                      };

                      print("EDITED: ${edited.state}");
                    });
                  },
                  onRowChecked: (event) {
                    _updateShowDeleteButton();
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
