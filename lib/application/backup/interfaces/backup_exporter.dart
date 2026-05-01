abstract class BackupExporter {
  Future<void> export({
    required String dbPath, 
    required String destPath, 
    required String baseTable, 
    required String delim
    });
}