import 'package:sqlite3/sqlite3.dart';
import 'package:ui_prototype/exceptions/project_db_exception.dart';
import 'package:ui_prototype/models/project_db.dart';
import 'package:ui_prototype/services/helpers/database.dart';

bool isValidDbPath(String dbPath) {
  // Check if empty
  if (dbPath.isEmpty) return false;

  // Check if ends with db
  if (!dbPath.endsWith('db')) return false;

  // Validate it doesn't have spaces
  if (dbPath.contains(' ')) return false;

  // Check for illegal characters
  final illegalChars = RegExp(r'[<>:"/\\|?*]');
  if (illegalChars.hasMatch(dbPath)) return false;

  return true;
}

Future<ProjectDb> readProjectSchema(String dbPath) async {
  // Open the database
  final Database db;

  // Validate path
  if (!isValidDbPath(dbPath)) {
    print("test");
  }

  // Make name for new database

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

  final projectDb = await createDbObject(db);
  return projectDb;
}
