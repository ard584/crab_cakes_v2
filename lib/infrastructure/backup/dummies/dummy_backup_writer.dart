import 'package:crab_cakes/application/backup/interfaces/db_backup_writer.dart';


class DummyBackupWriter implements DbBackupWriter {

   @override
  Future<void> writeDatabaseBackup({
    required String sourceDbPath,
    required String destinationDbPath,
  }) async {
        throw UnsupportedError('Backup is only supported on Windows right now.');
  }

}