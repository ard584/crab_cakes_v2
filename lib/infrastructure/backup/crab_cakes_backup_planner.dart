import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:ui_prototype/application/backup/dtos/backup_plan.dart';
import 'package:ui_prototype/application/backup/dtos/backup_request.dart';
import 'package:ui_prototype/application/backup/dtos/backup_target.dart';
import 'package:ui_prototype/application/backup/interfaces/backup_planner.dart';

class CrabCakesBackupPlanner implements BackupPlanner {

  @override
  Future<BackupPlan> prepareBackup(BackupRequest req, BackupTarget target) async {
    final safeProjectFolderName =
    '${_safeFolderName(req.projectName)}_${_safeFolderName(req.projectId)}';

    final backupRoot = path.join(target.drivePath, 'CRABCAKES');

    final projectRoot = path.join(backupRoot, 'projects', safeProjectFolderName);
    final dataDir = path.join(projectRoot, 'data');
    final exportDir = path.join(projectRoot, 'export');

    final databaseBackupPath = path.join(dataDir, 'data.sqlite');
    final textExportPath = path.join(exportDir, 'data.txt');
    final manifestPath = path.join(projectRoot, 'backup_manifest.json');

    await Directory(projectRoot).create(recursive: true);
    await Directory(dataDir).create(recursive: true);
    await Directory(exportDir).create(recursive: true);

    return BackupPlan(
      backupRootPath: backupRoot,
      projectRootPath: projectRoot,
      dataDir: dataDir,
      exportDir: exportDir,
      backupDbPath: databaseBackupPath,
      textExportPath: textExportPath,
      manifestPath: manifestPath,
    );
  }

  String _safeFolderName(String name) {
    final cleaned = name
        .trim()
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_');

    if (cleaned.isEmpty) {
      return 'unnamed_project';
    }

    return cleaned;
  }

}