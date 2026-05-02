import 'package:ui_prototype/application/sync/dtos/sync_compat_result.dart';
import 'package:ui_prototype/application/sync/interfaces/project_sync_repo.dart';

class CheckSyncCompat {
  final ProjectSyncRepo repo;

  CheckSyncCompat(this.repo);

  Future<SyncCompatibilityResult> call({
    required String activeDbPath,
    required String candidateDbPath,
  }) async {
    final active = await repo.readSyncMetadata(activeDbPath);
    final candidate = await repo.readSyncMetadata(candidateDbPath);

    if(active.syncVersion != candidate.syncVersion) {
      return const SyncCompatibilityResult.incompatible(
        'These projects use different sync metadata versions',
      );
    }

    if (active.projectGuid != candidate.projectGuid) {
      return const SyncCompatibilityResult.incompatible(
        'These databases are not from the same project.',
      );
    }

    if (active.schemaHash != candidate.schemaHash) {
      return const SyncCompatibilityResult.incompatible(
        'These databases have different schemas.',
      );
    }

    return const SyncCompatibilityResult.compatible();
  }
}