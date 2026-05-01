import 'package:sqlite3/sqlite3.dart';
import 'package:ui_prototype/application/backup/interfaces/backup_exporter.dart';
import 'package:ui_prototype/infrastructure/export/sqlite_data_exporter.dart';

class SqliteBackupExporter implements BackupExporter {
  
  @override
  Future<void> export({
    required String dbPath, 
    required String destPath, 
    required String baseTable, 
    required String delim
  }) async {

    //open connection to the source db
    final db = sqlite3.open(dbPath);

    try {
    //use the original exporter
    final exporter = SqliteDataExporter(db);

    //export the data to the destination
    await exporter.export(baseTable, destPath, delim);
    
    } finally {
      db.dispose();
    }
  }
}