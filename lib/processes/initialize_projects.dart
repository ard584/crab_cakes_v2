import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

// Define constants
const int EXPECTED_VERSION = 1;
const String CRITICAL_TABLE = 'projects';
const String DATABASE_FILE_NAME = 'projects.db';

// Define function to get file path
Future<String> getProjectsDatabasePath() async {
  // Get app directory
  final Directory appDirectory = await getApplicationSupportDirectory();

  // Append with database path
  final String path = join(appDirectory.path, DATABASE_FILE_NAME);

  return path;
}

// Main function
Future<bool> initializeDatabase() async {
  // Get database path
  final String dbPath = await getProjectsDatabasePath();

  // Create database
  final Database db = await createDatabase(dbPath);

  return false;
}

// Check for existing projects database
Future<Database> createDatabase(String dbPath) async {
  // Attempt to connect to database
  try {

    // Create or open the database
    final Database db = sqlite3.open(dbPath);

    return db;

  } on SqliteException catch (error) {
    print("SQLite Initialization error: ${error.message}");
    rethrow;
  } on FileSystemException catch (error) {
    print("File system error: ${error.message}");
    rethrow;
  } catch (error) {
    print("Unexpected database initialization error: $error");
    rethrow;
  }
}

// If doesn't exist, create database

// If exists, check if expected structure exists

// If expected structure does not exist,

// Check if database is empty

// If database is not empty, alert user project database may be corrupted

// If database is empty, create expected structure
