import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_prototype/application/interfaces/project_database.dart';
import 'package:ui_prototype/infrastructure/project/sqlite/sqlite_project_database.dart';
import 'package:ui_prototype/presentation/providers/flex_form_provider.dart';

final projectDatabaseProvider = Provider<ProjectDatabase>((ref) {
  
  // Get current project
  final projectAsync = ref.watch(currentFlexProjectProvider);

  return projectAsync.when(error: (e, st) {
    throw StateError('Failed to load project: $e');
  }, loading: () {
    throw StateError('Project is still loading');
  }, data: (project) {
    
    if (project == null) {
      throw StateError('No active project loaded');
    }

    return SqliteProjectDatabase(dbPath: project.dbPath);

  });
});