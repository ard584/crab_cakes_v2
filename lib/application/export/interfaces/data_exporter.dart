abstract class DataExporter {
  Future<void> export(String tableName, String filePath, String delimiter);
  Future<List<String>> getBaseTables();
}