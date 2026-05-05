import 'package:crab_cakes/application/backup/dtos/backup_request.dart';
import 'package:crab_cakes/application/backup/interfaces/backup_exporter.dart';
import 'package:crab_cakes/application/backup/interfaces/backup_manifest_writer.dart';
import 'package:crab_cakes/application/backup/interfaces/backup_planner.dart';
import 'package:crab_cakes/application/backup/interfaces/db_backup_writer.dart';
import 'package:crab_cakes/application/backup/interfaces/drive_selection_repo.dart';
import 'package:crab_cakes/application/backup/interfaces/drive_discovery.dart';

class WriteBackup {
  final BackupPlanner planner;
  final DbBackupWriter dbBackupWriter;
  final BackupExporter backupExporter;
  final BackupManifestWriter manifestWriter;
  final DriveSelectionRepository repo;
  final DriveDiscovery discovery;

  WriteBackup({
    required this.planner,
    required this.dbBackupWriter,
    required this.backupExporter,
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

      //writing a CSV version of the data if selected
      if(request.includeTextExport && request.baseTable != null) {
        final delim = request.exportDelimiter ?? '\t';

        await backupExporter.export(
          dbPath: plan.backupDbPath,
          destPath: plan.textExportPath,
          baseTable: request.baseTable!,
          delim: delim,
        );

      }

      //write the manifest that would be used to for data sync
      await manifestWriter.writeManifest(request: request, plan: plan);
    }
  }
}