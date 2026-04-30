import 'package:ui_prototype/application/backup/dtos/backup_plan.dart';
import 'package:ui_prototype/application/backup/dtos/backup_request.dart';
import 'package:ui_prototype/application/backup/dtos/backup_target.dart';

abstract class BackupPlanner {
  Future<BackupPlan> prepareBackup(BackupRequest req, BackupTarget target);
}