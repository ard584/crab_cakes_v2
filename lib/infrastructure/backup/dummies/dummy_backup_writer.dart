import 'package:ui_prototype/application/backup/interfaces/backup_writer.dart';


class DummyBackupWriter implements BackupWriter {

   @override
  Future<void> backup({
    required String sourceDbPath,
    required String targetRoot,
  }) async {
        throw UnsupportedError('Backup is only supported on Windows right now.');
  }

}