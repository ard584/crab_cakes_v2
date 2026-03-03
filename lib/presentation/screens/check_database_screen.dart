import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:ui_prototype/application/table_repository.dart';
import 'package:ui_prototype/infrastructure/project/active_project/pluto_grid_constructor.dart';
import 'package:ui_prototype/infrastructure/providers/flex_form_provider.dart';
import 'package:ui_prototype/infrastructure/providers/project_database_provider.dart';
import 'package:ui_prototype/domain/models/project_db.dart';

class CheckDatabaseScreen extends ConsumerWidget {
  const CheckDatabaseScreen({super.key});

  PlutoGrid displayGrid(ProjectDb project, ActiveProjectRepository repo) {
    final tableName = project.tables.entries.first.key;

    final table = repo.getTableSchema(tableName);

    final grid = PlutoGridConstructor();
    final columns = grid.constructColumns(table);

    final dbRows = repo.getAllRows(tableName);
    final List<PlutoRow> rows = [];

    for (final dbRow in dbRows) {
      final plutoRow = grid.constructRow(table, dbRow);
      rows.add(plutoRow);
    }

    // Create grid
    final plutoGrid = grid.constructGrid(
      columns: columns,
      rows: rows,
      onChanged: (event) {
        print("EVENT: $event");
      },
    );
    return plutoGrid;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get current project
    final table = ref.watch(projectDatabaseProvider);
    final projectAsync = ref.watch(projectViewModelProvider);

    return projectAsync.when(
      error: (e, st) {
        throw StateError('Failed to load project: $e');
      },
      loading: () {
        throw StateError('Project is still loading');
      },
      data: (project) {

        final grid = displayGrid(project.project, table);

        return Scaffold(
          appBar: AppBar(title: const Text('View Entries')),
          body: Center(
            child: Padding(padding: const EdgeInsets.all(20.0), child: grid),
          ),
          floatingActionButton: FloatingActionButton(onPressed: () async {}),
        );
      },
    );
  }
}
