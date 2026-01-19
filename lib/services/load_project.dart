import 'package:sqlite3/sqlite3.dart';
import 'package:ui_prototype/exceptions/project_db_exception.dart';
import 'package:ui_prototype/models/project_db.dart';
import 'package:ui_prototype/services/helpers/database.dart';
import 'package:path/path.dart' as path;
import 'package:ui_prototype/utils/logger.dart';

bool isValidDbPath(String dbPath) {
  // Check if empty
  if (dbPath.isEmpty) return false;

  try {
    final filename = path.basename(dbPath);

    // Check for illegal characters

    final illegalChars = RegExp(r'[<>:"/\\|?*]');
    if (illegalChars.hasMatch(filename)) return false;

    log.d("DBPATH: $dbPath");

  } catch (e) {
    return false;
  }

  return true;
}

Future<ProjectDb> readProjectSchema(String dbPath) async {
  // Open the database
  final Database db;

  // Validate path
  if (!isValidDbPath(dbPath)) {

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

  log.d("CALLING CREATE DB OBJECT");
  final projectDb = await createDbObject(db);
  log.d("PROJECTDB: $projectDb");
  return projectDb;
}
