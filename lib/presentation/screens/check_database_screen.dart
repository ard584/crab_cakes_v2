import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:ui_prototype/presentation/providers/flex_form_provider.dart';

class CheckDatabaseScreen extends ConsumerWidget {
  const CheckDatabaseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get current project
    final projectAsync = ref.watch(currentFlexProjectProvider);

    return projectAsync.when(
      error: (e, st) {
        throw StateError('Failed to load project: $e');
      },
      loading: () {
        throw StateError('Project is still loading');
      },
      data: (project) {
        if (project == null) {
          throw StateError('No active project loaded');
        }

        final dbPath = project.dbPath;
        final Database db = sqlite3.open(dbPath);

        String test = '';

        for (final table in project.tables.values) {
          final res = db.select('SELECT * FROM ${table.name}');

          for (final row in res.rows) {
            test += row.toString();
            test += '\n';
          }
        }

        return Scaffold(
          appBar: AppBar(title: const Text('View Entries')),
          body: Center(child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(test),
          )));
      },
    );
  }
}