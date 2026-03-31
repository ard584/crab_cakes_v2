abstract class BackupWriter {
  Future<void> backup({
    required String sourceDbPath,
    required String targetRoot,
  });
}