import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_prototype/application/table_repository.dart';
import 'package:ui_prototype/infrastructure/project/sqlite/sqlite_table_repository.dart';
import 'package:ui_prototype/infrastructure/providers/active_database_connection_provider.dart';

final projectDatabaseProvider = Provider<TableRepository>((ref) {
  
  // Get current project
  final database = ref.watch(activeDatabaseConnectionProvider);

  if (database == null) {
    throw Exception("[projectDatabaseProvider] Database not open in activeDatabaseConnectionProvider");
  }

  return SqliteTableRepository(db: database);

});