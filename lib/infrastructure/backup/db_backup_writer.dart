// import 'package:ui_prototype/application/backup/interfaces/backup_writer.dart';
// import 'package:ui_prototype/infrastructure/backup/drift_db_snapshotter.dart';
// import 'package:path/path.dart' as path;
// import 'dart:io';

// class DbBackupWriter implements BackupWriter {

//   final DriftDbSnapshotter snapshotter;    //<-- For the snapshotter helper
//   final String tempDirPath;                //<-- For the snapshot file location

//   DbBackupWriter(this.snapshotter, this.tempDirPath);

//   @override
//   Future<void> backup({
//     required String sourceDbPath,
//     required String targetRoot,
//   }) async {
//     final rootDir = Directory(targetRoot);
    
//     //verify the target exists
//     if(!await rootDir.exists()) {
//       //TODO: Maybe return an exception?

//       //drive no longer detected, exit
//       return;
//     }

//     //look for Data/ Directory, if not there create it
//     final dataDir = await ensureDataDirExists( targetRoot );

//     //Create a snapshot of the current database state
//     final snapshotPath = await snapshotter.createSnapshotFile(tempDirPath);

//     //Copy the main application database to the target drive
//     final destPath = path.join(dataDir.path, 'Data.db');
//     await File(snapshotPath).copy(destPath);
//   }


//   //============================ HELPER METHODS ================================
//   Future<Directory> ensureDataDirExists(String targetRoot) async {
//     final dataDir = Directory(path.join(targetRoot, 'Data'));

//     if (!await dataDir.exists()) {
//       await dataDir.create(recursive: true);
//     }
//     return dataDir;
//   }
// }

import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:ui_prototype/application/backup/interfaces/backup_writer.dart';

class DbBackupWriter implements BackupWriter {
  @override
  Future<void> backup({
    required String sourceDbPath,
    required String targetRoot,
  }) async {
    final rootDir = Directory(targetRoot);
    if (!await rootDir.exists()) {
      throw Exception('Drive not available: $targetRoot');
    }

    // Ensure Data/ exists on the drive
    final dataDir = Directory(path.join(targetRoot, 'Data'));
    if (!await dataDir.exists()) {
      await dataDir.create(recursive: true);
    }

    // Copy the main db file to Data/Data.db
    final src = File(sourceDbPath);
    if (!await src.exists()) {
      throw Exception('Source DB not found: $sourceDbPath');
    }

    final destPath = path.join(dataDir.path, 'Data.db');
    await src.copy(destPath);
  }
}
