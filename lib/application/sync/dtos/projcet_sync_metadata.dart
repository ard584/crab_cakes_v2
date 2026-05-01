class ProjectSyncMetadata {
  final String projectGuid;
  final String schemaHash;
  final int syncVersion;

  ProjectSyncMetadata({
    required this.projectGuid,
    required this.schemaHash,
    required this.syncVersion,
  });
}