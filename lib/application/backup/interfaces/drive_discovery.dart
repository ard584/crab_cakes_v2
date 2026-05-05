import 'package:crab_cakes/application/backup/dtos/backup_target.dart';

abstract class DriveDiscovery {

  Future<List<BackupTarget>> discover();
}