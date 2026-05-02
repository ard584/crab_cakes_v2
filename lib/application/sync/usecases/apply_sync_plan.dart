import 'package:ui_prototype/application/sync/dtos/sync_plan.dart';
import 'package:ui_prototype/application/sync/interfaces/project_sync_repo.dart';

class ApplySyncPlan {
  final ProjectSyncRepo repo;

  ApplySyncPlan(this.repo);

  Future<void> call({
    required String activeDbPath,
    required String candidateDbPath,
    required SyncPlan plan,
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
  }
}