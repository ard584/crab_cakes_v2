abstract class DbBackupWriter {
  Future<void> writeDatabaseBackup({
    required String sourceDbPath,
    required String destinationDbPath,
  });
}