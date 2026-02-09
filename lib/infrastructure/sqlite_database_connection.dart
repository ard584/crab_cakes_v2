import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:sqlite3/sqlite3.dart';
import 'package:ui_prototype/application/interfaces/database_connection.dart';

import 'package:ui_prototype/presentation/utils/logger.dart';

class SqliteDatabaseConnection implements DatabaseConnection<Database> {
  
  @override
  open(String path) {
    _isValidDbPath(path);
    return sqlite3.open(path);
  }

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
}