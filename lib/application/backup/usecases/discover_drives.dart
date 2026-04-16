import 'package:ui_prototype/application/backup/dtos/backup_target.dart';
import 'package:ui_prototype/application/backup/interfaces/drive_discovery.dart';

class DiscoverDrives {
  final DriveDiscovery discoverer;

  DiscoverDrives(this.discoverer);

  Future<List<BackupTarget>> execute() async {
    final List<BackupTarget> driveList = await discoverer.discover();

    return driveList;

  }
}