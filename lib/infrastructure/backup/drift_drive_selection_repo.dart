import 'package:ui_prototype/application/backup/interfaces/drive_selection_repo.dart';
import 'package:ui_prototype/infrastructure/backup/backup_settings_db.dart';

class DriftDriveSelectionRepository implements DriveSelectionRepository {
  DriftDriveSelectionRepository(this.db);
  final BackupSettingsDb db;

  @override
  Future<Set<String>> loadSelectedIds() async {
    final rows = await db.select(db.selectedBackupTargets).get();
    return rows.map((r) => r.targetId).toSet();
  }

  @override
  Future<void> saveSelectedIds(Set<String> ids) async {
    await db.transaction(() async {
      await db.delete(db.selectedBackupTargets).go();
      await db.batch((batch) {
        batch.insertAll(
          db.selectedBackupTargets,
          ids.map((id) => SelectedBackupTargetsCompanion.insert(targetId: id)).toList(),
        );
      });
    });
  }
}
