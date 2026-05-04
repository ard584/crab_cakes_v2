import 'package:crab_cakes/application/schema_discovery/interfaces/schema_discovery_repo.dart';

class GetTableColumns {
  final SchemaDiscoveryRepo repo;

  GetTableColumns(this.repo);

  Future<List<String>> execute(String table) {
    return repo.getColumns(table);
  }
}