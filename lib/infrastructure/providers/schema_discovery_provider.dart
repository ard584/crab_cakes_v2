import 'package:flutter_riverpod/flutter_riverpod.dart';

//importing the active database (project) provider
import 'package:crab_cakes/infrastructure/providers/active_database_connection_provider.dart';

//importing use cases
import 'package:crab_cakes/application/schema_discovery/usecases/get_schema_tables.dart';
import 'package:crab_cakes/application/schema_discovery/usecases/get_table_columns.dart';

//importing interfaces 
import 'package:crab_cakes/application/schema_discovery/interfaces/schema_discovery_repo.dart';

//importing concrete infrastructure implementations
import 'package:crab_cakes/infrastructure/schema_discovery/sqlite_schema_discovery_repo.dart';


//wiring infrastructure
final schemaDiscoveryRepoProvider = Provider<SchemaDiscoveryRepo?>((ref) {
  final db = ref.watch(activeDatabaseConnectionProvider);

  if(db == null) return null;

  return SqliteSchemaDiscoveryRepo(db);
});

//wiring use cases
final getSchemaTablesUsecaseProvider = Provider<GetSchemaTables?>((ref) {
  final repo = ref.watch(schemaDiscoveryRepoProvider);

  if(repo == null) return null;

  return GetSchemaTables(repo);
});

final getTableColumnsUsecaseProvider = Provider<GetTableColumns?>((ref) {
  final repo = ref.watch(schemaDiscoveryRepoProvider);

  if(repo == null) return null;

  return GetTableColumns(repo);
});

//wiring complete


final schemaTablesProvider = FutureProvider<List<String>>((ref) async {
  final useCase = ref.watch(getSchemaTablesUsecaseProvider);

  if(useCase == null) return [];

  return useCase.execute();
});

final tableColumnsProvider = 
            FutureProvider.family<List<String>, String>((ref, tableName) async {
  final useCase = ref.watch(getTableColumnsUsecaseProvider);

  if(useCase == null) return [];

  return useCase.execute(tableName);
});