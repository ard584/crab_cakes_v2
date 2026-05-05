import 'package:crab_cakes/application/backup/dtos/backup_target.dart';
import 'package:crab_cakes/application/backup/interfaces/drive_discovery.dart';

class DummyDriveDiscovery implements DriveDiscovery{

  @override
  Future<List<BackupTarget>> discover() async {
    return [];
  }

}