import 'package:ui_prototype/application/backup/dtos/backup_plan.dart';
import 'package:ui_prototype/application/backup/dtos/backup_request.dart';

abstract class BackupManifestWriter {
  Future<void> writeManifest({
    required BackupRequest request,
    required BackupPlan plan,
  });
}