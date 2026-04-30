import 'package:ui_prototype/application/backup/dtos/backup_request.dart';
import 'package:ui_prototype/application/backup/interfaces/backup_manifest_writer.dart';
import 'package:ui_prototype/application/backup/interfaces/backup_planner.dart';
import 'package:ui_prototype/application/backup/interfaces/db_backup_writer.dart';
import 'package:ui_prototype/application/backup/interfaces/drive_selection_repo.dart';
import 'package:ui_prototype/application/backup/interfaces/drive_discovery.dart';
import 'package:ui_prototype/application/export/interfaces/data_exporter.dart';

class WriteBackup {
  final BackupPlanner planner;
  final DbBackupWriter dbBackupWriter;
  final DataExporter? dataExporter;
  final BackupManifestWriter manifestWriter;
  final DriveSelectionRepository repo;
  final DriveDiscovery discovery;

  WriteBackup({
    required this.planner,
    required this.dbBackupWriter,
    this.dataExporter,
    required this.manifestWriter,
    required this.repo,
    required this.discovery,
  });

  Future<void> execute({required BackupRequest request}) async {
    final detectedDrives = await discovery.discover();
    final selectedIds = await repo.loadSelectedIds();

    final selectedTargets = detectedDrives
        .where((d) => selectedIds.contains(d.id))
        .toList();

    for (final target in selectedTargets) {
      final plan = await planner.prepareBackup(request, target);
      
      await dbBackupWriter.writeDatabaseBackup(
        sourceDbPath: request.sourceDbPath, 
        destinationDbPath: plan.backupDbPath,
      );

      //making a local variable that will be promoted from null
      final exporter = dataExporter;

      //writing a CSV version of the data if selected
      if(request.includeTextExport && request.baseTable != null) {

        if(exporter == null) {
          throw Exception(
            'Text export was requested, but no active database exporter is available'
          );
        }

        final delim = request.exportDelimiter ?? '\t';
        exporter.export(request.baseTable!, plan.textExportPath, delim);
      }

      //write the manifest that would be used to for data sync
      await manifestWriter.writeManifest(request: request, plan: plan);
    }
  }
}