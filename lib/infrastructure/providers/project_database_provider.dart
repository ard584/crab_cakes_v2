import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crab_cakes/application/active_project_repository.dart';
import 'package:crab_cakes/infrastructure/project/sqlite/sql_insert_generator.dart';
import 'package:crab_cakes/infrastructure/project/sqlite/sqlite_active_project_repository.dart';
import 'package:crab_cakes/infrastructure/project/sqlite/sqlite_update_generator.dart';
import 'package:crab_cakes/infrastructure/providers/active_database_connection_provider.dart';

final projectDatabaseProvider = Provider<ActiveProjectRepository>((ref) {
  // Get current project
  final database = ref.watch(activeDatabaseConnectionProvider);

  if (database == null) {
    throw Exception(
      "[projectDatabaseProvider] Database not open in activeDatabaseConnectionProvider",
    );
  }

  // Define and inject generator
  final insert = SQLInsertGenerator();
  final update = SqliteUpdateGenerator();

  return SqliteActiveProjectRepository(
    db: database,
    insert: insert,
    update: update,
  );
});
