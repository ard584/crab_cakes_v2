import 'package:ui_prototype/application/sync/dtos/sync_plan.dart';
import 'package:ui_prototype/application/sync/interfaces/project_sync_repo.dart';
import 'package:ui_prototype/application/sync/usecases/check_sync_compat.dart';

class BuildSyncPlan {
  final ProjectSyncRepo repo;
  final CheckSyncCompat checkCompat;

  BuildSyncPlan({
    required this.repo,
    required this.checkCompat,
  });

  Future<SyncPlan> call({
    required String activeDbPath,
    required String candidateDbPath,
  }) async {
    final compatibility = await checkCompat(
      activeDbPath: activeDbPath,
      candidateDbPath: candidateDbPath,
    );

    if (!compatibility.isCompatible) {
      throw Exception(
        compatibility.reason ?? 'Projects are not compatible for sync.',
      );
    }

    final tables = await repo.getUserTables(activeDbPath);

    final tablePlans = <TableSyncPlan>[];

    for (final tableName in tables) {
      final activeRows = await repo.getRowsForSync(
        dbPath: activeDbPath,
        tableName: tableName,
      );

      final candidateRows = await repo.getRowsForSync(
        dbPath: candidateDbPath,
        tableName: tableName,
      );

      final tablePlan = _buildTablePlan(
        tableName: tableName,
        activeRows: activeRows,
        candidateRows: candidateRows,
      );

      tablePlans.add(tablePlan);
    }

    return SyncPlan(tablePlans: tablePlans);
  }

  TableSyncPlan _buildTablePlan({
    required String tableName,
    required List<Map<String, dynamic>> activeRows,
    required List<Map<String, dynamic>> candidateRows,
  }) {
    final activeByGuid = _indexByGuid(activeRows);
    final candidateByGuid = _indexByGuid(candidateRows);

    final insertsToActive = <Map<String, dynamic>>[];
    final insertsToCandidate = <Map<String, dynamic>>[];
    final updatesToActive = <Map<String, dynamic>>[];
    final updatesToCandidate = <Map<String, dynamic>>[];
    final conflicts = <SyncConflict>[];

    final allGuids = {
      ...activeByGuid.keys,
      ...candidateByGuid.keys,
    };

    for (final guid in allGuids) {
      final activeRow = activeByGuid[guid];
      final candidateRow = candidateByGuid[guid];

      if (activeRow == null && candidateRow != null) {
        insertsToActive.add(candidateRow);
        continue;
      }

      if (candidateRow == null && activeRow != null) {
        insertsToCandidate.add(activeRow);
        continue;
      }

      if (activeRow == null || candidateRow == null) {
        continue;
      }

      if (_rowsEquivalent(activeRow, candidateRow)) {
        continue;
      }

      final activeUpdatedAt = _parseTimestamp(activeRow['__updated_at']);
      final candidateUpdatedAt = _parseTimestamp(candidateRow['__updated_at']);

      if (activeUpdatedAt == null || candidateUpdatedAt == null) {
        conflicts.add(
          SyncConflict(
            tableName: tableName,
            rowGuid: guid,
            activeRow: activeRow,
            candidateRow: candidateRow,
            reason: 'Missing or invalid __updated_at timestamp.',
          ),
        );
        continue;
      }

      if (activeUpdatedAt.isAfter(candidateUpdatedAt)) {
        updatesToCandidate.add(activeRow);
      } else if (candidateUpdatedAt.isAfter(activeUpdatedAt)) {
        updatesToActive.add(candidateRow);
      } else {
        conflicts.add(
          SyncConflict(
            tableName: tableName,
            rowGuid: guid,
            activeRow: activeRow,
            candidateRow: candidateRow,
            reason: 'Rows differ but have the same __updated_at timestamp.',
          ),
        );
      }
    }

    return TableSyncPlan(
      tableName: tableName,
      insertsToActive: insertsToActive,
      insertsToCandidate: insertsToCandidate,
      updatesToActive: updatesToActive,
      updatesToCandidate: updatesToCandidate,
      conflicts: conflicts,
    );
  }

  Map<String, Map<String, dynamic>> _indexByGuid(
    List<Map<String, dynamic>> rows,
  ) {
    final indexed = <String, Map<String, dynamic>>{};

    for (final row in rows) {
      final guid = row['__row_guid'];

      if (guid is String && guid.isNotEmpty) {
        indexed[guid] = row;
      }
    }

    return indexed;
  }

  DateTime? _parseTimestamp(dynamic value) {
    if (value is! String || value.isEmpty) {
      return null;
    }

    return DateTime.tryParse(value);
  }

  bool _rowsEquivalent(
    Map<String, dynamic> left,
    Map<String, dynamic> right,
  ) {
    if (left.length != right.length) {
      return false;
    }

    for (final entry in left.entries) {
      if (right[entry.key] != entry.value) {
        return false;
      }
    }

    return true;
  }
}