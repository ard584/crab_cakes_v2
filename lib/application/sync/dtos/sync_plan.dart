class SyncPlan {
  final List<TableSyncPlan> tablePlans;

  SyncPlan({
    required this.tablePlans,
  });

  int get totalInsertsToActive =>
      tablePlans.fold(0, (sum, plan) => sum + plan.insertsToActive.length);

  int get totalInsertsToCandidate =>
      tablePlans.fold(0, (sum, plan) => sum + plan.insertsToCandidate.length);

  int get totalUpdatesToActive =>
      tablePlans.fold(0, (sum, plan) => sum + plan.updatesToActive.length);

  int get totalUpdatesToCandidate =>
      tablePlans.fold(0, (sum, plan) => sum + plan.updatesToCandidate.length);

  int get totalConflicts =>
      tablePlans.fold(0, (sum, plan) => sum + plan.conflicts.length);
}

class TableSyncPlan {
  final String tableName;

  final List<Map<String, dynamic>> insertsToActive;
  final List<Map<String, dynamic>> insertsToCandidate;

  final List<Map<String, dynamic>> updatesToActive;
  final List<Map<String, dynamic>> updatesToCandidate;

  final List<SyncConflict> conflicts;

  TableSyncPlan({
    required this.tableName,
    required this.insertsToActive,
    required this.insertsToCandidate,
    required this.updatesToActive,
    required this.updatesToCandidate,
    required this.conflicts,
  });
}

class SyncConflict {
  final String tableName;
  final String rowGuid;
  final Map<String, dynamic> activeRow;
  final Map<String, dynamic> candidateRow;
  final String reason;

  SyncConflict({
    required this.tableName,
    required this.rowGuid,
    required this.activeRow,
    required this.candidateRow,
    required this.reason,
  });
}