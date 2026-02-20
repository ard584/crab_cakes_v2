import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_prototype/application/table_repository.dart';
import 'package:ui_prototype/infrastructure/providers/flex_form_provider.dart';
import 'package:ui_prototype/infrastructure/providers/project_database_provider.dart';
import 'package:ui_prototype/domain/models/project_db.dart';

class CheckDatabaseScreen extends ConsumerWidget {
  const CheckDatabaseScreen({super.key});

  Future<void> displayRows(ProjectDb project, TableRepository table) async {

     for (final tableName in project.tables.entries) {
      final res = table.getAllRows(tableName.key);
      
      for (final row in res) {
        print("ROW: ${row.values}");
      }
     }
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

        String test = '';

        for (final tableName in project.project.tables.entries) {

          final rows = table.getAllRows(tableName.key);
          
          for (final row in rows) {
            test += '${row.values}\n';
          }
        }

        return Scaffold(
          appBar: AppBar(title: const Text('View Entries')),
          body: Center(child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(test),
          )), floatingActionButton: FloatingActionButton(onPressed: () async {

          }),);
      },
    );
  }
}