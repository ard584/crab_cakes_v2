abstract class DataExporter {
  Future<void> export(String tableName, String filePath);
}