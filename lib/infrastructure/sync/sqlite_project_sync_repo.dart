import 'dart:convert';

import 'package:sqlite3/sqlite3.dart';
import 'package:ui_prototype/application/sync/dtos/projcet_sync_metadata.dart';
import 'package:ui_prototype/application/sync/interfaces/project_sync_repo.dart';
import 'package:ui_prototype/infrastructure/providers/column_filter_provider.dart';

class SqliteProjectSyncRepository implements ProjectSyncRepo {

  /// This function takes in a string path to the database in question, it then
  /// queries the __project_settings table and parses out:
  /// 
  /// 1) Project GUID
  /// 2) SchemaHash
  /// 3) Sync Version
  /// 
  /// This information is packaged into a ProjectSyncMetadata object and returned
  @override
  Future<ProjectSyncMetadata> readSyncMetadata(String dbPath) async {
    final db = sqlite3.open(dbPath);

    try {
      final result = db.select('''
        SELECT settings_json
        FROM __project_settings
        WHERE id = 1
      ''');

      if (result.isEmpty) {
        throw Exception(
          'Selected database is not a sync-enabled CRABCAKES project. '
          'Missing __project_settings row.',
        );
      }

      final rawSettingsJson = result.first['settings_json'];

      if (rawSettingsJson is! String || rawSettingsJson.isEmpty) {
        throw Exception(
          'Selected database has invalid project settings metadata.',
        );
      }

      final decoded = jsonDecode(rawSettingsJson);

      if (decoded is! Map<String, dynamic>) {
        throw Exception(
          'Selected database has malformed project settings metadata.',
        );
      }

      final projectGuid = decoded['projectGuid'];
      final schemaHash = decoded['schemaHash'];
      final syncVersion = decoded['syncVersion'];

      if (projectGuid is! String || projectGuid.isEmpty) {
        throw Exception(
          'Selected database is missing projectGuid. '
          'This may be an older backup or the wrong project database.',
        );
      }

      if (schemaHash is! String || schemaHash.isEmpty) {
        throw Exception(
          'Selected database is missing schemaHash. '
          'This may be an older backup or the wrong project database.',
        );
      }

      if (syncVersion is! int) {
        throw Exception(
          'Selected database is missing syncVersion. '
          'This may be an older backup or the wrong project database.',
        );
      }

      return ProjectSyncMetadata(
        projectGuid: projectGuid,
        schemaHash: schemaHash,
        syncVersion: syncVersion,
      );
    } finally {
      db.dispose();
    }
  }

  @override
  Future<List<String>> getUserTables(String dbPath) async {
    final db = sqlite3.open(dbPath);

    try {
      final result = db.select('''
        SELECT name
        FROM sqlite_master
        WHERE type = 'table'
          AND name NOT LIKE 'sqlite_%'
        ORDER BY name
      ''');

      return result
          .map((row) => row['name'] as String)
          .where((name) => !_isInternalName(name))
          .toList();
    } finally {
      db.dispose();
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getRowsForSync({
    required String dbPath,
    required String tableName,
  }) async {
    final db = sqlite3.open(dbPath);

    try {
      final quotedTableName = _quoteIdentifier(tableName);

      final hasDeletedAtColumn = _tableHasColumn(
        db: db,
        tableName: tableName,
        columnName: '__deleted_at',
      );

      final sql = hasDeletedAtColumn
          ? '''
            SELECT *
            FROM $quotedTableName
            WHERE __deleted_at IS NULL
          '''
          : '''
            SELECT *
            FROM $quotedTableName
          ''';

      final result = db.select(sql);

      return result.map((row) {
        return Map<String, dynamic>.from(row);
      }).toList();
    } finally {
      db.dispose();
    }
  }

  bool _tableHasColumn({
    required Database db,
    required String tableName,
    required String columnName,
  }) {
    final quotedTableName = _quoteIdentifier(tableName);

    final result = db.select('PRAGMA table_info($quotedTableName)');

    return result.any((row) => row['name'] == columnName);
  }

  String _quoteIdentifier(String identifier) {
    return '"${identifier.replaceAll('"', '""')}"';
  }

  bool _isInternalName(String name) {
    return name.startsWith('__') || name.startsWith(kColumnPrefixToHide);
  }

//------------------------ IMPLEMENTING WRITES ------------------------------
  @override
  Future<void> insertRowForSync({
    required String dbPath,
    required String tableName,
    required Map<String, dynamic> row,
  }) async {
    final db = sqlite3.open(dbPath);

    try {
      final filteredRow = _filterSyncWritableValues(row);

      if (filteredRow.isEmpty) {
        throw Exception('Cannot insert empty sync row into $tableName.');
      }

      final quotedTableName = _quoteIdentifier(tableName);

      final columns = filteredRow.keys.toList();
      final quotedColumns = columns.map(_quoteIdentifier).join(', ');
      final placeholders = List.filled(columns.length, '?').join(', ');
      final values = columns.map((column) => filteredRow[column]).toList();

      db.execute(
        '''
        INSERT INTO $quotedTableName ($quotedColumns)
        VALUES ($placeholders)
        ''',
        values,
      );
    } finally {
      db.dispose();
    }
  }

  @override
  Future<void> updateRowForSync({
    required String dbPath,
    required String tableName,
    required Map<String, dynamic> row,
  }) async {
    final db = sqlite3.open(dbPath);

    try {
      final rowGuid = row['__row_guid'];

      if (rowGuid is! String || rowGuid.isEmpty) {
        throw Exception('Cannot update sync row without __row_guid.');
      }

      final filteredRow = _filterSyncWritableValues(row);

      filteredRow.remove('__row_guid');

      if (filteredRow.isEmpty) {
        return;
      }

      final quotedTableName = _quoteIdentifier(tableName);

      final columns = filteredRow.keys.toList();

      final assignments = columns
          .map((column) => '${_quoteIdentifier(column)} = ?')
          .join(', ');

      final values = [
        ...columns.map((column) => filteredRow[column]),
        rowGuid,
      ];

      db.execute(
        '''
        UPDATE $quotedTableName
        SET $assignments
        WHERE "__row_guid" = ?
        ''',
        values,
      );

      if (db.updatedRows == 0) {
        throw Exception(
          'Sync update failed: no row found in $tableName with __row_guid=$rowGuid.',
        );
      }
    } finally {
      db.dispose();
    }
  }

  Map<String, dynamic> _filterSyncWritableValues(Map<String, dynamic> row) {
    final filtered = Map<String, dynamic>.from(row);

    // SQLite result maps sometimes include weird/null values depending on schema.
    // Keep nulls because inserts/updates may need to intentionally preserve null.
    filtered.removeWhere((columnName, _) {
      return columnName == 'rowid';
    });

    return filtered;
  }

}