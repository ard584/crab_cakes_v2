import 'package:ui_prototype/application/project/interfaces/schema/project_database_builder.dart';

import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:ui_prototype/presentation/exceptions/project_db_exception.dart';

import 'dart:io';
import 'package:path/path.dart' as path;

import 'package:uuid/uuid.dart';
import 'package:ui_prototype/presentation/utils/logger.dart';

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
  AND name != '__app_metadata'""");

    return tables.isNotEmpty;
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

        // Add system columns to newly created table
        final match = RegExp(r'CREATE\s+TABLE\s+(\w+)', caseSensitive: false).firstMatch(statement);
        if (match != null) {
          final tableName = match.group(1)!;
          print('ADDING COLUMNS TO: $tableName');
          db.execute("ALTER TABLE $tableName ADD COLUMN __created_at_time TEXT DEFAULT (datetime('now', 'localtime'));");
          db.execute("ALTER TABLE $tableName ADD COLUMN __modified_in_program INTEGER DEFAULT 0;");
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
      createSystemTables(db);

      //validating
      if (!validateDb(db)) {
        throw Exception(
          "Database validation failed: No tables created or illegal objects found.",
        );
      }

      db.execute('COMMIT');
    } catch (e) {
      db.execute('ROLLBACK;');
      db.dispose();
      // Clean up temp file
      if (File(dbTempPath).existsSync()) File(dbTempPath).deleteSync();
      rethrow;
    } finally {
      //closing the database connection to prevent windows complaints
      try {db.dispose();} catch (_){}
    }

    return dbTempPath;
  }

  void createSystemTables(Database db) {

    //creating the Settings table (stores setting json), and inserting first row
    db.execute("""
    CREATE TABLE __project_settings (
      id INT PRIMARY KEY,
      settings_json TEXT NOT NULL
    );
    INSERT INTO __project_settings (id, settings_json)
    VALUES (1, '{}');
  """);
  }
}
