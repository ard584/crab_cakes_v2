import 'dart:io';
import 'package:sqlite3/sqlite3.dart';
import 'package:ui_prototype/presentation/exceptions/project_db_exception.dart';
import 'package:ui_prototype/presentation/models/project_db.dart';
import 'package:ui_prototype/presentation/services/flex_engine/creation/project_db_mapper.dart';
import 'package:path/path.dart' as path;
import 'package:ui_prototype/presentation/utils/logger.dart';

class FlexDbMapper {
  final String dbPath;

  FlexDbMapper({required this.dbPath});

  bool _isValidDbPath(String dbPath) {
    // Check if empty
    if (dbPath.isEmpty) throw Exception("Empty database path");

    try {
      final filename = path.basename(dbPath);

      // Check for illegal characters
      final illegalChars = RegExp(r'[<>:"/\\|?*]');
      if (illegalChars.hasMatch(filename)) {
        throw Exception("Invalid characters in database filename: $filename");
      }

      log.d("ISVALIDDBPATH CALLED: $dbPath");

      // Check if files exists
      final file = File(dbPath);
      if(!file.existsSync()) {
        log.d("FILE DOES NOT EXIST");
        throw Exception("File at $dbPath does not exist.");
      }

      log.d("FILE DOES EXIST");

      log.d("DBPATH: $dbPath");
    } catch (e) {
      throw Exception("Error occurred retrieving database path: $e");
    }

    return true;
  }

  Future<ProjectDb> mapFromDatabase() async {
    // Open the database
    final Database db;

    log.d("MAP FROM DATABASE CALLED!");

    // Validate path
    _isValidDbPath(dbPath);


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
