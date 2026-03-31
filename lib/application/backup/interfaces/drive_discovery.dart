import 'package:ui_prototype/application/backup/dtos/backup_target.dart';

abstract class DriveDiscovery {

  Future<List<BackupTarget>> discover();
}