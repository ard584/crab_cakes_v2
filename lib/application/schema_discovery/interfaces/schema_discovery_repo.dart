abstract class SchemaDiscoveryRepo {
  Future<List<String>> getTables();
  Future<List<String>> getColumns(String table);
}