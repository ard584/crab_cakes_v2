import 'dart:io';

import 'package:sqlite3/sqlite3.dart';
import 'package:ui_prototype/application/backup/interfaces/backup_exporter.dart';
import 'package:ui_prototype/infrastructure/export/sqlite_data_exporter.dart';

class SqliteBackupExporter implements BackupExporter {
  @override
  Future<void> export({
    required String dbPath,
    required String destPath,
    required String baseTable,
    required String delim,
  }) async {
    if (!File(dbPath).existsSync()) {
      throw FileSystemException('Source database does not exist.', dbPath);
    }

    final db = sqlite3.open(dbPath);

    try {
      final exporter = SqliteDataExporter(db);

      await exporter.export(baseTable, destPath, delim);
    } finally {
      db.dispose();
    }
  }
}