import 'package:sqlite3/sqlite3.dart';
import 'package:ui_prototype/exceptions/project_db_exception.dart';
import 'package:ui_prototype/models/table.dart';
import 'package:ui_prototype/models/attribute.dart';
import 'package:ui_prototype/models/project_db.dart';

bool isValidDbPath(String dbPath) {

  // Check if empty
  if (dbPath.isEmpty) return false;

  // Check if ends with db
  if (!dbPath.endsWith('db')) return false;

  // Validate it doesn't have spaces
  if(dbPath.contains(' ')) return false;

  // Check for illegal characters
  final illegalChars = RegExp(r'[<>:"/\\|?*]');
  if (illegalChars.hasMatch(dbPath)) return false;

  return true;
}

Future<ProjectDb> readProjectSchema(String dbPath) async {
  // Open the database
  final Database db;

  // Validate path
  if (!isValidDbPath(dbPath))
  {

  }


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

  try {
    // Try to read the names of the tables
    List<String> tableNames = await _readTableNames(db);

    // Define temporary list of tables
    List<TableModel> tableList = [];

    // Iterate through table names
    for (String tableName in tableNames) {
      // Get list of attributes
      List<Attribute> attributes = await _readAttributes(db, tableName);

      // Add to table
      tableList.add(TableModel(name: tableName, attributeList: attributes));
    }

    // Convert list into map
    Map<String, TableModel> tableMap = {
      for (final table in tableList) table.name: table,
    };

    // Store instance internally
    final project_db = ProjectDb(tables: tableMap);

    // Return the instance
    return project_db;
  } finally {
    // Close database connection
    db.dispose();
  }
}

Future<List<String>> _readTableNames(Database db) async {
  // Get name of tables
  final tables = db.select('''SELECT name FROM sqlite_master 
  WHERE type="table" 
  AND name NOT LIKE "sqlite%"''');

  // Map to string
  return tables.map((row) => row['name'] as String).toList();
}

Attribute _getAttribute(Row attribute) {
  // Format and return attribute
  return Attribute(
    columnID: attribute["cid"],
    name: attribute["name"],
    dataType: attribute["type"],
    isNotNullable: attribute["notnull"] == 0 ? false : true,
    defaultValue: attribute["dflt_value"],
    isPrimaryKey: attribute["pk"] == 0 ? false : true,
  );
}

// Read attributes from given tablename
Future<List<Attribute>> _readAttributes(Database db, String tableName) async {
  // Query database for attributes from table
  final attributes = db.select('''PRAGMA table_info($tableName)''');

  // Initialize attributes list
  List<Attribute> attrList = [];

  // Iterate through attributes
  for (final attribute in attributes) {
    // Get formatted attribute and add it to attribute list
    attrList.add(_getAttribute(attribute));
  }

  // Return attribute list
  return attrList;
}
