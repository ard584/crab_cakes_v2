class BackupPlan {
  final String backupRootPath;
  final String projectRootPath;

  final String dataDir;
  final String exportDir;

  final String backupDbPath;
  final String textExportPath;

  final String manifestPath;


  const BackupPlan({
    required this.backupRootPath,
    required this.projectRootPath,

    required this.dataDir,
    required this.exportDir,

    required this.backupDbPath,
    required this.textExportPath,

    required this.manifestPath,
  });
}