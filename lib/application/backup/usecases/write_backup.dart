import 'package:ui_prototype/application/backup/interfaces/backup_writer.dart';
import 'package:ui_prototype/application/backup/interfaces/drive_selection_repo.dart';
import 'package:ui_prototype/application/backup/interfaces/drive_discovery.dart';

class WriteBackup {
  final BackupWriter writer;
  final DriveSelectionRepository repo;
  final DriveDiscovery discovery;

  WriteBackup(this.writer, this.repo, this.discovery);

  Future<void> execute({required String sourceDbPath}) async {
    final detectedDrives = await discovery.discover();
    final selectedIds = await repo.loadSelectedIds();

    final selectedTargets = detectedDrives
        .where((d) => selectedIds.contains(d.id))
        .toList();

    for (final target in selectedTargets) {
      await writer.backup(sourceDbPath: sourceDbPath, targetRoot: target.drivePath);
    }
  }
}
