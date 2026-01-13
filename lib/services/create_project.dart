import 'package:sqlite3/sqlite3.dart';
import 'package:ui_prototype/models/project_db.dart';
import 'package:ui_prototype/exceptions/project_db_exception.dart';
import 'package:ui_prototype/services/helpers/database.dart';

bool validateDb(Database db) {

  // Needs to have at least one valid created table
  final tables = db.select("""
  SELECT name FROM sqlite_master
  WHERE type = 'table'
  AND name NOT LIKE sqlite_%
  AND name != '__app_metadata'""");

  return tables.isNotEmpty;
}

Future<ProjectDb> readProjectSchema(String userSchema) async {
  // Open the database
  final Database db;

  // Make name for new database
  final dbPath = "temp";

  try {
    db = sqlite3.open(dbPath);
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
  db.execute('PRAGMA enable_load_extension = OFF;');

  try {
    db.execute('BEGIN IMMEDIATE;');

    //execute user sql
    db.execute(userSchema);

    db.execute('COMMIT');
  } catch (e) {
    db.execute('ROLLBACK;');
    db.dispose();
    rethrow;
  }

  // Validate the database
  validateDb(db);

  final projectDb = await createDbObject(db);
  return projectDb;
}
