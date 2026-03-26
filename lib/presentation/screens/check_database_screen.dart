import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:ui_prototype/application/project/use_cases/update_rows.dart';
import 'package:ui_prototype/domain/entities/row_identifier.dart';
import 'package:ui_prototype/domain/models/db_row.dart';
import 'package:ui_prototype/infrastructure/project/active_project/pluto_grid_constructor.dart';
import 'package:ui_prototype/infrastructure/providers/delete_rows_provider.dart';
import 'package:ui_prototype/infrastructure/providers/flex_form_provider.dart';
import 'package:ui_prototype/infrastructure/providers/pluto_update_rows_provider.dart';
import 'package:ui_prototype/infrastructure/providers/project_database_provider.dart';
import 'package:ui_prototype/infrastructure/providers/update_rows_provider.dart';
import 'package:ui_prototype/presentation/dialogs/confirm_delete.dart';
import 'package:ui_prototype/presentation/adapters/pluto_grid_adapter.dart';
import 'package:ui_prototype/presentation/dialogs/confirm_update.dart';
import 'package:ui_prototype/infrastructure/pluto/pluto_update_rows_controller.dart';

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
  final Set<Key> _updatedRowKeys = {};

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tableName = ref.watch(activeTableProvider);
    int _rowCount = _updatedRowKeys.length;

    void _updateShowDeleteButton() {
      if (stateManager != null && stateManager!.checkedRows.isNotEmpty) {
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
    print("TABLE SCHEMA: $table");

    final constructor = PlutoGridConstructor();
    List<PlutoColumn> columns = constructor.constructColumns(table);
    final dbRows = repo.getAllRows(tableName);
    final rows = dbRows.map((row) {
      PlutoRow current_row = constructor.constructRow(table, row);
      final check_row = PlutoCell(value: "");
      current_row.cells['check_box'] = check_row;
      return current_row;
    }).toList();

    print("ROW: ${rows.first.cells}");

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
            end: _rowCount > 0
                ? scheme.primaryContainer
                : scheme.surfaceContainerHighest,
          ),
          builder: (context, color, child) {
            return FloatingActionButton.extended(
              onPressed: _rowCount > 0
                  ? () async {
                      print("TEST");

                      final currentStateManager = stateManager;
                      if (currentStateManager == null) return;

                      String promptRows = "rows";
                      final selectedRowKeys = _updatedRowKeys.toList();

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
                        final List<Key> editedRowIdentifiers = _updatedRowKeys
                            .toList();

                        // Get edited rows
                        final editedRows = extractPlutoRowsByKeys(
                          editedRowIdentifiers,
                          stateManager,
                        );

                        final updater = ref.read(plutoUpdateRowsProvider);
                        updater.updateFromPluto(rows: editedRows, table: table);
                        
                      }
                    }
                  : null,
              label: Text("Update $_rowCount rows"),
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
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;

                      setState(() {
                        _updatedRowKeys.add(event.row.key);
                      });
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