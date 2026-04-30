
class BackupRequest {
  final String projectId;
  final String projectName;
  final String sourceDbPath;
  final bool includeTextExport;
  final DateTime createdAt;
  final String? baseTable;
  final String? exportDelimiter;

  const BackupRequest({
    required this.projectId,
    required this.projectName,
    required this.sourceDbPath,
    required this.includeTextExport,
    required this.createdAt,
    this.baseTable,
    this.exportDelimiter,
  });
}