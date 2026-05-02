import 'package:ui_prototype/application/sync/dtos/projcet_sync_metadata.dart';

abstract class ProjectSyncRepo {
  Future<ProjectSyncMetadata> readSyncMetadata(String dbPath);

  Future<List<String>> getUserTables(String dbPath);

  Future<List<Map<String, dynamic>>> getRowsForSync({
    required String dbPath,
    required String tableName,
  });

  Future<void> insertRowForSync({
    required String dbPath,
    required String tableName,
    required Map<String, dynamic> row,
  });

  Future<void> updateRowForSync({
    required String dbPath,
    required String tableName,
    required Map<String, dynamic> row,
  });
}