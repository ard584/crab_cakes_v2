import 'package:ui_prototype/application/backup/dtos/backup_plan.dart';
import 'package:ui_prototype/application/backup/dtos/backup_request.dart';
import 'package:ui_prototype/application/backup/interfaces/backup_manifest_writer.dart';

class DummyManifestWriter implements BackupManifestWriter {
  Future<void> writeManifest({
    required BackupRequest request,
    required BackupPlan plan,
  }) {
    throw UnsupportedError('Backup is only supported on Windows right now.');
  }
}