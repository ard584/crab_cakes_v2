import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:ui_prototype/infrastructure/project/active_project/pluto_grid_constructor.dart';
import 'package:ui_prototype/infrastructure/providers/delete_rows_provider.dart';
import 'package:ui_prototype/infrastructure/providers/flex_form_provider.dart';
import 'package:ui_prototype/infrastructure/providers/project_database_provider.dart';
import 'package:ui_prototype/presentation/dialogs/confirm_delete.dart';
import 'package:ui_prototype/presentation/adapters/pluto_grid_adapter.dart';

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
  PlutoGridStateManager? _stateManager;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('View Entries')),
      floatingActionButton: _stateManager == null
          ? null
          : ListenableBuilder(
              listenable: _stateManager!,
              builder: (context, child) {
                final manager = _stateManager;
                if (manager == null) return SizedBox.shrink();

                final isSelected = manager.currentSelectingRows.isNotEmpty;
                final rowCount = manager.currentSelectingRows.length;

                return AnimatedSize(
                  duration: Duration(milliseconds: 400),
                  curve: Curves.easeInOutCubicEmphasized,
                  clipBehavior: Clip.none,
                  child: TweenAnimationBuilder<Color?>(
                    duration: Duration(milliseconds: 300),
                    tween: ColorTween(
                      end: isSelected
                          ? scheme.primaryContainer
                          : scheme.surfaceContainerHighest,
                    ),
                    builder: (context, color, child) {
                      return FloatingActionButton.extended(
                        onPressed: isSelected ? () {} : () {},
                        label: Text("Update $rowCount rows"),
                        backgroundColor: color,
                      );
                    },
                  ),
                );
              },
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
              Expanded(
                child: TableGrid(
                  onGridLoaded: (manager) {
                    setState(() {
                      _stateManager = manager;
                    });
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

class TableGrid extends ConsumerStatefulWidget {
  final Function(PlutoGridStateManager)? onGridLoaded;

  const TableGrid({super.key, this.onGridLoaded});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _TableGridState();
  }
}

class _TableGridState extends ConsumerState<TableGrid> {
  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(projectDatabaseProvider);
    final tableName = ref.watch(activeTableProvider);

    if (tableName == null) {
      return Center(child: Text("Select a table"));
    }

    final table = repo.getTableSchema(tableName);

    final constructor = PlutoGridConstructor();
    final columns = constructor.constructColumns(table);

    final dbRows = repo.getAllRows(tableName);

    final rows = dbRows.map((row) {
      return constructor.constructRow(table, row);
    }).toList();

    return PlutoGrid(
      key: ValueKey(tableName),
      columns: columns,
      rows: rows,
      mode: PlutoGridMode.multiSelect,
      onLoaded: (PlutoGridOnLoadedEvent event) {
        final function = widget.onGridLoaded;
        if (function != null) {
          function(event.stateManager);
        }
      },
      createHeader: (stateManager) {
        return ListenableBuilder(
          listenable: stateManager,
          builder: (context, child) {
            final bool hasSelection =
                stateManager.currentSelectingRows.isNotEmpty;

            return TextButton.icon(
              onPressed: hasSelection
                  ? () async {
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
                    }
                  : null,
              icon: const Icon(Icons.delete),
              label: Text('Delete'),
            );
          },
        );
      },
    );
  }
}
