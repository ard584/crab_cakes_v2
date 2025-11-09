import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

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


// Check for existing projects database

// If doesn't exist, create database

// If exists, check if expected structure exists

// If expected structure does not exist,

// Check if database is empty

// If database is not empty, alert user project database may be corrupted

// If database is empty, create expected structure