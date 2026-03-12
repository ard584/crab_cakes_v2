import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:ui_prototype/application/table_repository.dart';
import 'package:ui_prototype/infrastructure/project/active_project/pluto_grid_constructor.dart';
import 'package:ui_prototype/infrastructure/providers/delete_rows_provider.dart';
import 'package:ui_prototype/infrastructure/providers/flex_form_provider.dart';
import 'package:ui_prototype/infrastructure/providers/project_database_provider.dart';
import 'package:ui_prototype/domain/models/project_db.dart';
import 'package:ui_prototype/presentation/dialogs/confirm_delete.dart';
import 'package:ui_prototype/presentation/adapters/pluto_grid_adapter.dart';

class CheckDatabaseScreen extends ConsumerStatefulWidget {
  const CheckDatabaseScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _CheckDatabaseState();
  }
}

class _CheckDatabaseState extends ConsumerState<CheckDatabaseScreen> {
  PlutoGrid displayGrid(
    ProjectDb project,
    ActiveProjectRepository repo,
    String tableName,
  ) {
    final table = repo.getTableSchema(tableName);

    final grid = PlutoGridConstructor();
    final columns = grid.constructColumns(table);
    final dbRows = repo.getAllRows(tableName);
    final List<PlutoRow> rows = [];

    for (final dbRow in dbRows) {
      final plutoRow = grid.constructRow(table, dbRow);
      rows.add(plutoRow);
    }

    final plutoGrid = PlutoGrid(
      columns: columns,
      rows: rows,
      configuration: PlutoGridConfiguration(),
      onChanged: (event) {
        event.row;
      },
      mode: PlutoGridMode.multiSelect,
      createHeader: (stateManager) {
        return TextButton.icon(
          onPressed: () async {
            final selectedRows = stateManager.currentSelectingRows;

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
              final dbRows = extractDbRows(selectedRows);

              // Call use case
              final deleteRowsUseCase = ref.read(deleteRowsProvider);
              deleteRowsUseCase(tableName: tableName, rows: dbRows);

              // Remove rows from stateManager
              stateManager.removeRows(selectedRows);
            }
          },
          icon: const Icon(Icons.delete),
          label: Text('Delete'),
        );
      },
    );

    return plutoGrid;
  }

  @override
  Widget build(BuildContext context) {
    // Get current project
    final repo = ref.watch(projectDatabaseProvider);
    final projectAsync = ref.watch(projectViewModelProvider);
    final activeTableName = ref.watch(activeTableProvider);

    final Map<String, PlutoGrid?> grids = {};
    PlutoGrid? activeGrid;

    return projectAsync.when(
      error: (e, st) {
        throw StateError('Failed to load project: $e');
      },
      loading: () {
        throw StateError('Project is still loading');
      },
      data: (project) {
        if (activeTableName == null) {
          return Center(child: CircularProgressIndicator());
        }

        if (grids.containsKey(activeTableName)) {
          PlutoGrid? grid = grids[activeTableName];
          if (grid != null) {
            activeGrid = grid;
          }
        } else {
          activeGrid = displayGrid(project.project, repo, activeTableName);
          grids[activeTableName] = activeGrid;
        }

        if (activeGrid == null) {
          return PlutoLoading();
        }

        final chip = project.tables.entries.map((table) {
          return ChoiceChip(
            label: Text(table.key),
            selected: table.key == activeTableName,
            onSelected: (bool selected) {
              if (selected) {
                // Update active table
                ref
                    .read(activeTableProvider.notifier)
                    .setActiveTable(table.key);
              }
            },
          );
        }).toList();

        final grid = activeGrid;

        return Scaffold(
          appBar: AppBar(title: const Text('View Entries')),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsetsGeometry.directional(bottom: 12),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(spacing: 8.0, children: chip),
                    ),
                  ),
                  if (grid != null) Expanded(child: grid),
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(onPressed: () async {}),
        );
      },
    );
  }
}
