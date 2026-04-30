import 'package:ui_prototype/application/backup/dtos/backup_target.dart';

class BackupRequest {
  final String projectId;
  final String projectName;
  final String sourceDbPath;
  final List<BackupTarget> targets;
  final bool includeTextExport;
  final DateTime createdAt;
  final String baseTable;

  const BackupRequest({
    required this.projectId,
    required this.projectName,
    required this.sourceDbPath,
    required this.targets,
    required this.includeTextExport,
    required this.createdAt,
    required this.baseTable,
  });
}