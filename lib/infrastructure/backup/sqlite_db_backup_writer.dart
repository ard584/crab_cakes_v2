import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:sqlite3/sqlite3.dart';
import 'package:crab_cakes/application/backup/interfaces/db_backup_writer.dart';

/// Class to implement the DbBackupWriter interface
///
/// This class is in charge of writing specifically the Database backup to the
/// given destination path. 
class SqliteDbBackupWriter implements DbBackupWriter {
  
  /// Function takes in 2 strings: 
  /// 1) The path to the source DB to be backed up
  /// 2) The path to the destination where the backup should be written to
  /// 
  /// It ensures that the source db exists, creates a snapshot of the source db, 
  /// and verifies that the backup was successful
  /// * THIS FUNCTION CAN THROW IF SRC DB DOESN'T EXIST OR IF BACKUP FAILS
  @override
  Future<void> writeDatabaseBackup({
    required String sourceDbPath,
    required String destinationDbPath,
  }) async {
    final sourceFile = File(sourceDbPath);

    if (!await sourceFile.exists()) {
      throw Exception('Source database does not exist: $sourceDbPath');
    }

    await Directory(path.dirname(destinationDbPath)).create(recursive: true);

    final tempPath = '$destinationDbPath.tmp';
    final tempFile = File(tempPath);

    if (await tempFile.exists()) {
      await tempFile.delete();
    }

    final db = sqlite3.open(sourceDbPath);

    try {
      final escapedTempPath = tempPath.replaceAll("'", "''");
      db.execute("VACUUM INTO '$escapedTempPath'");
    } finally {
      db.dispose();
    }

    await _verifySqliteBackup(tempPath);

    final destinationFile = File(destinationDbPath);

    if (await destinationFile.exists()) {
      await destinationFile.delete();
    }

    await tempFile.rename(destinationDbPath);

    await _verifySqliteBackup(destinationDbPath);
  }

  /// Function that takes in a String path to a SQLite database file and ensures
  /// 1) That the DB exists
  /// 2) That it not empty
  /// 3) That it passes an integrity check.
  /// This allows a successful database backup to be identified.
  Future<void> _verifySqliteBackup(String dbPath) async {
    final file = File(dbPath);

    if (!await file.exists()) {
      throw Exception('Backup database was not created: $dbPath');
    }

    final length = await file.length();
    if (length == 0) {
      throw Exception('Backup database is empty: $dbPath');
    }

    final db = sqlite3.open(dbPath);

    try {
      final result = db.select('PRAGMA integrity_check;');

      if (result.isEmpty) {
        throw Exception('SQLite integrity check returned no result.');
      }

      final value = result.first.values.first.toString();

      if (value.toLowerCase() != 'ok') {
        throw Exception('Backup database failed integrity check: $value');
      }
    } finally {
      db.dispose();
    }
  }
}