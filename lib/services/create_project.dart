import 'package:sqlite3/sqlite3.dart';
import 'package:ui_prototype/models/project_db.dart';
import 'package:ui_prototype/exceptions/project_db_exception.dart';
import 'package:ui_prototype/services/helpers/database.dart';

import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

/*
ATTACH is harmful as it attaches another database
DETACH only makes sense to be used with ATTACH
PRAGMA makes changes to SQLite behavior

VACUUM, REINDEX, ANALYZE are all functions that are irrelevant to creation

INSERT, UPDATE, DELETE, REPLACE, UPSERT are all for inserting data, which
should not happen in the creation flow. This can happen after.

DROP deletes tables, not needed in creation flow, dangerous if somehow gets
access to another database file

BEGIN, COMMIT, ROLLBACK, SAVEPOINT, RELEASE all relate to transactions. User
should not be able to start or stop transactions, may break safety features.

TRIGGER runs database operations automatically, not needed

SELECT for data leakage
*/

class SqlSecurityValidator {
  static const List<String> disallowedKeywords = [
    "ATTACH",
    "DETACH",
    "PRAGMA",
    "LOAD_EXTENSION",
    "VACUUM",
    "REINDEX",
    "ANALYZE",
    "INSERT",
    "UPDATE",
    "DELETE",
    "REPLACE",
    "UPSERT",
    "DROP",
    "BEGIN",
    "COMMIT",
    "ROLLBACK",
    "SAVEPOINT",
    "RELEASE",
    "TRIGGER",
    "SELECT",
  ];

  static const List<String> allowedKeywords = [
    "CREATE TABLE",
    "ALTER TABLE",
    "CREATE INDEX",
    "CREATE UNIQUE INDEX",
  ];

  bool _containsForbiddenKeywordsInCode(String statement) {

    // Define regex for finding anything that's in quotes
    final quotePattern = RegExp(
      r"("

      // Single quotes
      r"|'(?:''|[^'])*'"

      // Double quotes
      r'"(?:""|[^"])*"'
      r")"
    );

    int lastIndex = 0;

    for (final match in quotePattern.allMatches(statement)) {

      // Get codeBefore and codeAfter quotes
      final codeBefore = statement.substring(lastIndex, match.start);
      if(_hasDisallowedKeywords(codeBefore)) return true;

      // Update lastIndex
      lastIndex = match.end;
    }

    // Scan remaining code too
    final codeAfter = statement.substring(lastIndex);
    if(_hasDisallowedKeywords(codeAfter)) return true;

    return false;
  }

  bool _hasDisallowedKeywords(String sql) {
    
        // Check for blacklisted keywords
    // 2. Keyword Blacklist (Ensures no forbidden terms inside the statement)
    for (final forbidden in disallowedKeywords) {
      // Use word boundaries \b to allow names like "my_trigger_column"
      // but block the command "TRIGGER"
      if (sql.contains(RegExp('\\b$forbidden\\b'))) {
        return true;
      }
    }

    return false;

  }

  String _normalizeSql(sql) {
    return sql
    .replaceAll(RegExp(r'\s+'), ' ')
    .toUpperCase();
  }

  bool _hasOnlyAllowedKeywords(String sql) {

    // Check for matches
    final matches = allowedKeywords.any(
      (keyword) => sql.startsWith(keyword),
    );

    // If it doesn't match any allowed keywords, block
    if (!matches) return false;

  return true;
}

bool _isQuoted(String token) {

  return false;
}

String _removeComments(String sql) {
  final pattern = RegExp(
    r"("

    // Scan through anything surrounded by single quotes, 
    // ignore two consecutive single quotes
    r"'(?:''|[^'])*'"

    // Scan through anything surrounded by double quotes,
    // ignore two consecutive single quotes
    r'"(?:""|[^"])*"'

    // Match "/*" up to "*/" 
    // (need \ escape character for regex parser to look for *)
    // [\s\S] matches everything (consume everything up to */)
    // *? Makes it consume everything up to the first occurrence of */
    // (matches smallest block it can find)
    r"/\*[\s\S]*?\*/"

    // Match single line character up to newline
    r"|--.*"
    r")"
  );

  return sql.splitMapJoin(
    pattern,
    onMatch: (Match match) {
      final text = match.group(0)!;
      // If it starts with a quote, it's a string literal — KEEP IT
      if (text.startsWith("'")) {
        return text;
      }
      // Otherwise, it's a comment — DISCARD IT
      return '';
    },
    onNonMatch: (String text) => text,
  );
}

List<String> _splitSqlStatements(String sql) {
  // Pattern matches:
  // 1. Single quoted strings: '(?:''|[^'])*'
  // 2. Double quoted identifiers: "(?:""|[^"])*"
  // 3. Semicolons: ;
  final pattern = RegExp(
    r"('(?:''|[^'])*'"
    r'|"(?:""|[^"])*"'
    r"|;)"
  );

  List<String> statements = [];
  int lastStart = 0;

  for (final match in pattern.allMatches(sql)) {
    final matchedText = match.group(0)!;

    if (matchedText == ';') {
      // Found a delimiter
      // Add everything from the last semicolon to this one.
      statements.add(sql.substring(lastStart, match.start).trim());
      lastStart = match.end;
    }
  }

  // Add the final chunk (if any) after the last semicolon
  final remainder = sql.substring(lastStart).trim();
  if (remainder.isNotEmpty) {
    statements.add(remainder);
  }

  return statements.where((s) => s.isNotEmpty).toList();
}

List<String> getValidStatements(sql) {

  // Clean & split
  final clean = _removeComments(sql);
  final split = _splitSqlStatements(clean);

  return split;
}

bool isSafe(rawSql) {
  final statements = getValidStatements(rawSql);

  // Iterate through statements
  for (final statement in statements) {

    // Normalize
    final normalized = _normalizeSql(statement);

    // Check if statement is not allowed or has disallowed keywords
    if(!_hasOnlyAllowedKeywords(normalized)) return false;
    if (_containsForbiddenKeywordsInCode(normalized)) return false;
    
  }

  return true;

}

}

// Create database function
Future<Database> initializeDatabase({String path = ':memory:'}) async {
  return sqlite3.open(path);
}

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
    'foreign_keys': db.select('PRAGMA foreign_keys').first[0],
    'trusted_schema': db.select('PRAGMA trusted_schema').first[0],
    'writable_schema': db.select('PRAGMA writable_schema').first[0],
  };
}

int getSchemaVersion(Database db) {
  return db.select('PRAGMA schema_version;').first[0] as int;
}

typedef DatabaseOpener = Database Function();

Future<ProjectDb> createProject(
  String userSchema, {
  required DatabaseOpener opener,
}) async {

  // Check if is safe
  final validator = SqlSecurityValidator();
  if (!validator.isSafe(userSchema)) {
    throw Exception("Unsafe SQL detected");
  }

  // Split sql
  final statements = validator.getValidStatements(userSchema);

  final tempDir = Directory.systemTemp.createTempSync();
  final dbPath = path.join(tempDir.path, 'temp_${const Uuid().v4()}.sqlite');

  if (File(dbPath).existsSync()) {
    throw StateError('New database invariant violated');
  }

  late final Database db;

  try {
    db = opener();
  } catch (e, st) {
    throw ProjectDbException(
      type: ProjectDbErrorType.openFailed,
      message: 'Failed to open database at $dbPath',
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
    if (File(dbPath).existsSync()) File(dbPath).deleteSync();
    rethrow;
  }

  return await createDbObject(db);
}
