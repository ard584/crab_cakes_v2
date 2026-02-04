import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_prototype/application/interfaces/project_database.dart';
import 'package:ui_prototype/infrastructure/project/sqlite/sqlite_project_database.dart';

final projectDatabaseProvider = Provider<ProjectDatabase>((ref) {
  return SqliteProjectDatabase();
});