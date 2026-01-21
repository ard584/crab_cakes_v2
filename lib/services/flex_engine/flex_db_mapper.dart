import 'package:sqlite3/sqlite3.dart';
import 'package:ui_prototype/exceptions/project_db_exception.dart';
import 'package:ui_prototype/models/project_db.dart';
import 'package:ui_prototype/services/flex_engine/creation/project_db_mapper.dart';
import 'package:path/path.dart' as path;
import 'package:ui_prototype/utils/logger.dart';

class FlexDbMapper {
  final String dbPath;

  FlexDbMapper({required this.dbPath});

  bool _isValidDbPath(String dbPath) {
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

  Future<ProjectDb> mapFromDatabase() async {
    // Open the database
    final Database db;

    // Validate path
    if (!_isValidDbPath(dbPath)) {}

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
}
