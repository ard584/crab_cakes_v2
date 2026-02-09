import 'package:ui_prototype/application/backup/interfaces/backup_writer.dart';
import 'package:ui_prototype/application/backup/interfaces/drive_selection_repo.dart';
import 'package:ui_prototype/application/backup/interfaces/drive_discovery.dart';

// class WriteBackup {
//   final BackupWriter writer;
//   final DriveSelectionRepository repo;
//   final DriveDiscovery discoverer;

//   WriteBackup(this.writer, this.repo, this.discoverer);

//   Future<void> execute() async {

//     final detectedDrives = await discoverer.discover();
//     final selectedIdList = await repo.loadSelectedIds();

//     // Resolve selected targets that are currently present
//     final selectedTargets = detectedDrives
//         .where((drive) => selectedIdList.contains(drive.id))
//         .toList();

//     // Write to ALL selected targets that are available
//     for (final target in selectedTargets) {
//       await writer.backup(target.drivePath); // "D:\\"
//     }

//   }
// }

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

    for (final t in selectedTargets) {
      await writer.backup(sourceDbPath: sourceDbPath, targetRoot: t.drivePath);
    }
  }
}
