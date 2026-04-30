import 'dart:convert';
import 'dart:io';

import 'package:ui_prototype/application/backup/dtos/backup_plan.dart';
import 'package:ui_prototype/application/backup/dtos/backup_request.dart';
import 'package:ui_prototype/application/backup/interfaces/backup_manifest_writer.dart';

class JsonManifestWriter implements BackupManifestWriter {

  @override 
  Future<void> writeManifest({
    required BackupRequest request,
    required BackupPlan plan,
  }) async {
    final dbFile = File(plan.backupDbPath);
    final exportFile = File(plan.textExportPath);

    final manifest = {
      'version': 1,
      'projectId': request.projectId,
      'projectName': request.projectName,
      'backupCreatedAt': request.createdAt.toUtc().toIso8601String(),
      'database': {
        'path': 'data/data.sqlite',
        'exists': await dbFile.exists(),
        'sizeBytes': await dbFile.exists() ? await dbFile.length() : 0,
      },
      'textExport': {
        'included': request.includeTextExport,
        'path': request.includeTextExport ? 'export/data.txt' : null,
        'exists': request.includeTextExport && await exportFile.exists(),
        'sizeBytes': request.includeTextExport && await exportFile.exists()
            ? await exportFile.length()
            : 0,
      },
    };

    await File(plan.manifestPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(manifest),
    );
  }
}