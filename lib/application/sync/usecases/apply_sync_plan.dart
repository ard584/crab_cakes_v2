import 'package:crab_cakes/application/sync/dtos/sync_plan.dart';
import 'package:crab_cakes/application/sync/interfaces/project_sync_repo.dart';
import 'package:crab_cakes/application/backup/interfaces/backup_exporter.dart';

class ApplySyncPlan {
  final ProjectSyncRepo repo;
  final BackupExporter backupExporter;

  ApplySyncPlan({
    required this.repo,
    required this.backupExporter,
  });

  Future<void> call({
    required String activeDbPath,
    required String candidateDbPath,
    required SyncPlan plan,

    // Optional export refresh info
    String? activeExportPath,
    String? candidateExportPath,
    String? baseTable,
    String delim = '\t',
  }) async {
    if (plan.totalConflicts > 0) {
      throw Exception(
        'Cannot apply sync plan because it has ${plan.totalConflicts} conflict(s).',
      );
    }

    for (final tablePlan in plan.tablePlans) {
      for (final row in tablePlan.insertsToActive) {
        await repo.insertRowForSync(
          dbPath: activeDbPath,
          tableName: tablePlan.tableName,
          row: row,
        );
      }

      for (final row in tablePlan.insertsToCandidate) {
        await repo.insertRowForSync(
          dbPath: candidateDbPath,
          tableName: tablePlan.tableName,
          row: row,
        );
      }

      for (final row in tablePlan.updatesToActive) {
        await repo.updateRowForSync(
          dbPath: activeDbPath,
          tableName: tablePlan.tableName,
          row: row,
        );
      }

      for (final row in tablePlan.updatesToCandidate) {
        await repo.updateRowForSync(
          dbPath: candidateDbPath,
          tableName: tablePlan.tableName,
          row: row,
        );
      }
    }

    // Refresh text exports after both databases have been updated.
    if (baseTable != null && activeExportPath != null) {
      await backupExporter.export(
        dbPath: activeDbPath,
        destPath: activeExportPath,
        baseTable: baseTable,
        delim: delim,
      );
    }

    if (baseTable != null && candidateExportPath != null) {
      await backupExporter.export(
        dbPath: candidateDbPath,
        destPath: candidateExportPath,
        baseTable: baseTable,
        delim: delim,
      );
    }
  }
}