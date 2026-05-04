import 'package:crab_cakes/application/project/interfaces/schema/project_database_builder.dart';

import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:crab_cakes/presentation/exceptions/project_db_exception.dart';

import 'dart:io';
import 'package:path/path.dart' as path;

import 'package:uuid/uuid.dart';
import 'package:crab_cakes/presentation/utils/logger.dart';

import 'package:crab_cakes/infrastructure/providers/column_filter_provider.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class SqliteProjectDatabaseBuilder implements ProjectDatabaseBuilder {


  bool validateDb(Database db) {
    // Check for anything not a table or index
    final illegalStuff = db.select("""
    SELECT name, type FROM sqlite_master 
    WHERE type NOT IN ('table', 'index') 
    AND name NOT LIKE 'sqlite_%'
  """);

    if (illegalStuff.isNotEmpty) return false;

    // Needs to have at least one valid created table
    final tables = db.select("""
      SELECT name FROM sqlite_master
      WHERE type = 'table'
      AND name NOT LIKE 'sqlite_%'
    """);

    final userTables = tables.where((row) {
      final tableName = row['name'] as String;
      return !_isInternalName(tableName);
    }).toList();

    return userTables.isNotEmpty;
  }

  bool _isInternalName(String name) {
    return name.startsWith('__') || name.startsWith(kColumnPrefixToHide);
  }

  String _quoteIdentifier(String identifier) {
    return '"${identifier.replaceAll('"', '""')}"';
  }

  void _addInternalColumnsIfMissing(Database db, String tableName) {
    final quotedTableName = _quoteIdentifier(tableName);

    final tableInfo = db.select('PRAGMA table_info($quotedTableName);');
    final existingColumns = tableInfo
        .map((row) => row['name'] as String)
        .toSet();

    void addColumnIfMissing(String columnName, String columnDefinition) {
      if (existingColumns.contains(columnName)) return;

      db.execute(
        'ALTER TABLE $quotedTableName ADD COLUMN $columnName $columnDefinition;',
      );

      existingColumns.add(columnName);
    }

    // Existing app/catch-history metadata columns.
    addColumnIfMissing(
      '${kColumnPrefixToHide}created_at_time',
      "TEXT DEFAULT (datetime('now', 'localtime'))",
    );

    addColumnIfMissing(
      '${kColumnPrefixToHide}modified_in_program',
      'INTEGER DEFAULT 0',
    );

    // Sync metadata columns.
    addColumnIfMissing(
      '${kColumnPrefixToHide}row_guid',
      'TEXT',
    );

    addColumnIfMissing(
      '${kColumnPrefixToHide}created_at',
      'TEXT',
    );

    addColumnIfMissing(
      '${kColumnPrefixToHide}updated_at',
      'TEXT',
    );

    addColumnIfMissing(
      '${kColumnPrefixToHide}deleted_at',
      'TEXT',
    );

    final rowGuidIndexName = _quoteIdentifier(
      '${tableName}_${kColumnPrefixToHide}row_guid_unique_idx',
    );

    final rowGuidColumn = '${kColumnPrefixToHide}row_guid';
    final quotedRowGuidColumn = _quoteIdentifier(rowGuidColumn);

    db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS $rowGuidIndexName
      ON $quotedTableName ($quotedRowGuidColumn);
    ''');
  }

  Map<String, Object?> getSecurityState(Database db) {
    return {
      'foreign_keys': db.select('PRAGMA foreign_keys').first.columnAt(0),
      'trusted_schema': db.select('PRAGMA trusted_schema').first.columnAt(0),
      'writable_schema': db.select('PRAGMA writable_schema').first.columnAt(0),
    };
  }

  int getSchemaVersion(Database db) {
    return db.select('PRAGMA schema_version;').first.columnAt(0) as int;
  }

  @override
  Future<String> buildFromSchema(List<String> statements) async {

    final tempDbPath = await createProjectInTemp(statements);
    final appDir = await getApplicationSupportDirectory();

    final permanentPath = path.join(
      appDir.path,
      'projects',
      'project_${DateTime.now().microsecondsSinceEpoch}.sqlite',
    );

    await Directory(path.dirname(permanentPath)).create(recursive: true);

    final tempFile = File(tempDbPath);
    await tempFile.rename(permanentPath);

    log.d('PERMANENT PATH: $permanentPath');

    return permanentPath;
  }

  Future<String> createProjectInTemp(
    List<String> statements
  ) async {


    final tempDir = Directory.systemTemp.createTempSync();
    final dbTempPath = path.join(
      tempDir.path,
      'temp_${const Uuid().v4()}.sqlite',
    );

    if (File(dbTempPath).existsSync()) {
      throw StateError('New database invariant violated');
    }

    late final Database db;

    try {
      db = sqlite3.open(dbTempPath);
    } catch (e, st) {
      throw ProjectDbException(
        type: ProjectDbErrorType.openFailed,
        message: 'Failed to open database at $dbTempPath',
        cause: e,
        stackTrace: st,
      );
    }

    // Lock down database
    db.execute('PRAGMA foreign_keys = ON;');
    db.execute('PRAGMA trusted_schema = OFF;');
    db.execute('PRAGMA writable_schema = OFF;');

    try {
      db.execute('BEGIN IMMEDIATE;');

      //execute user sql
      for (final statement in statements) {
        int lastSchemaVersion = getSchemaVersion(db);

        db.execute(statement);

        // Get all tables in the database
        final tables = db.select("SELECT name FROM sqlite_master WHERE type='table';");

        for (final table in tables) {
          final tableName = table['name'] as String;

          if (tableName.startsWith('sqlite_')) continue;
          if (_isInternalName(tableName)) continue;

          _addInternalColumnsIfMissing(db, tableName);
        }

        // check security state
        final securityState = getSecurityState(db);
        if (securityState["foreign_keys"] == 0 ||
            securityState["trusted_schema"] == 1 ||
            securityState["writable_schema"] == 1) {
          throw Exception("Security tampering detected: PRAGMA modified.");
        }

        // Check schema actually changed
        int newSchemaVersion = getSchemaVersion(db);
        if (newSchemaVersion == lastSchemaVersion) {
          // Schema didn't actually change, assume something weird happened
          throw Exception("Statement executed but no schema change detected.");
        }

        lastSchemaVersion = newSchemaVersion;
      }

      //adding system tables (i.e. Settings)
      createSystemTables(db, statements);

      //validating
      if (!validateDb(db)) {
        throw Exception(
          "Database validation failed: No tables created or illegal objects found.",
        );
      }

      db.execute('COMMIT');
    } catch (e) {
      try {
        db.execute('ROLLBACK;');
      } catch (_) {
        // Ignore rollback failures so the original failure can still be rethrown.
      }

      try {
        db.dispose();
      } catch (_) {
        // Ignore dispose failures during cleanup.
      }

      // Clean up temp file after closing the database connection.
      try {
        if (File(dbTempPath).existsSync()) {
          File(dbTempPath).deleteSync();
        }
      } catch (_) {
        // Ignore cleanup failure so the original error is preserved.
      }

      rethrow;
    } finally {
      //closing the database connection to prevent windows complaints
      try {db.dispose();} catch (_){}
    }

    return dbTempPath;
  }

  void createSystemTables(Database db, List<String> statements) {

    //generating the GUID and schema hash for the project
    final projectGuid = const Uuid().v4();
    final schemaHash = computeSchemaHash(db);

    final initialJson = jsonEncode({
    'formatVersion': 1,
    'projectGuid': projectGuid,
    'schemaHash': schemaHash,
    'syncVersion': 1,
    'schemaSql': statements,
    'settings': {},
    'integrity': {},
    });

    //creating the Settings table (stores setting json), and inserting first row
    db.execute('''
      CREATE TABLE __project_settings (
        id INTEGER PRIMARY KEY,
        settings_json TEXT NOT NULL
      );
    ''');

    db.execute('''
      INSERT INTO __project_settings (id, settings_json)
      VALUES (1, ?);
    ''', [initialJson]);
  }

  String computeSchemaHash(Database db) {
    final schemaParts = <Map<String, Object?>>[];


    final tables = db.select('''
      SELECT name
      FROM sqlite_master
      WHERE type = 'table'
        AND name NOT LIKE 'sqlite_%'
      ORDER BY name;
    ''');

    for (final tableRow in tables) {
      final tableName = tableRow['name'] as String;

      if (_isInternalName(tableName)) continue;

      final quotedTableName = _quoteIdentifier(tableName);

      final columns = db.select('PRAGMA table_info($quotedTableName);');

      final normalizedColumns = columns
          .where((column) {
            final columnName = column['name'] as String;
            return !_isInternalName(columnName);
          })
          .map((column) {
            return {
              'name': column['name'],
              'type': (column['type'] as String?)?.toUpperCase().trim(),
              'notnull': column['notnull'],
              'default': column['dflt_value'],
              'pk': column['pk'],
            };
          })
          .toList();

      final foreignKeys = db.select('PRAGMA foreign_key_list($quotedTableName);');

      final normalizedForeignKeys = foreignKeys
          .where((fk) {
            final fromColumn = fk['from'] as String;
            final referencedTable = fk['table'] as String;
            final toColumn = fk['to'] as String?;

            return !_isInternalName(fromColumn) &&
                !_isInternalName(referencedTable) &&
                (toColumn == null || !_isInternalName(toColumn));
          })
          .map((fk) {
            return {
              'from': fk['from'],
              'toTable': fk['table'],
              'to': fk['to'],
              'onUpdate': fk['on_update'],
              'onDelete': fk['on_delete'],
              'match': fk['match'],
            };
          })
          .toList();

      normalizedForeignKeys.sort((a, b) {
        final aKey = '${a['from']}|${a['toTable']}|${a['to']}';
        final bKey = '${b['from']}|${b['toTable']}|${b['to']}';
        return aKey.compareTo(bKey);
      });

      schemaParts.add({
        'table': tableName,
        'columns': normalizedColumns,
        'foreignKeys': normalizedForeignKeys,
      });
    }

    final canonicalSchemaJson = jsonEncode(schemaParts);
    return sha256.convert(utf8.encode(canonicalSchemaJson)).toString();
  }
}
