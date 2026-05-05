import 'package:crab_cakes/application/schema_discovery/interfaces/schema_discovery_repo.dart';

class GetSchemaTables {
  final SchemaDiscoveryRepo repo;

  GetSchemaTables(this.repo);

  Future<List<String>> execute() {
    return repo.getTables();
  }
}