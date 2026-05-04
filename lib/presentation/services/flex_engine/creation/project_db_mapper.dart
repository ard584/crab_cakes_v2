import 'package:sqlite3/sqlite3.dart';
import 'package:crab_cakes/domain/models/table.dart';
import 'package:crab_cakes/domain/models/attribute.dart';
import 'package:crab_cakes/domain/models/project_db.dart';

ProjectDb createDbObject(db) {
  try {
    // Try to read the names of the tables
    List<String> tableNames = _readTableNames(db);

    // Define temporary list of tables
    List<TableModel> tableList = [];

    // Iterate through table names
    for (String tableName in tableNames) {
      // Get list of attributes
      List<Attribute> attributes = _readAttributes(db, tableName);

      // Add to table
      tableList.add(TableModel(name: tableName, attributeList: attributes));
    }

    // Convert list into map
    Map<String, TableModel> tableMap = {
      for (final table in tableList) table.name: table,
    };

    // Store instance internally
    final projectDb = ProjectDb(tables: tableMap);

    // Return the instance
    return projectDb;
  } catch(e) {
    throw Exception("[createDbObject] Error occurred while mapping database: $e");
  }
}

// Read attributes from given tablename
List<Attribute> _readAttributes(Database db, String tableName) {
  // Query database for attributes from table
  final attributes = db.select('''PRAGMA table_info($tableName)''');
  final fkRows = db.select('PRAGMA foreign_key_list($tableName)');

  //building a map that stores the child columns to ForeignKeyInfo objects
  //basically a lookup table for all foreign key columns in the specified table 
  final Map<String, ForeignKeyInfo> fkMap = {
    for (final fk in fkRows)
      fk['from'] as String: ForeignKeyInfo(
        referencedTable: fk['table'] as String,
        referencedColumn: fk['to'] as String,
      ),
  };

  // Initialize attributes list
  List<Attribute> attrList = [];

  // Iterate through attributes
  for (final attribute in attributes) {
    // Get formatted attribute and add it to attribute list
   final columnName = attribute['name'] as String;

    attrList.add(
      _getAttribute(
        attribute,
        fkInfo: fkMap[columnName],
        isAutoIncrement: isAutoIncrementColumn(db, tableName, columnName)
      ),
    );
  }

  // Return attribute list
  return attrList;
}

List<String> _readTableNames(Database db) {
  // Get name of tables
  final tables = db.select('''SELECT name FROM sqlite_master 
  WHERE type='table' 
  AND name NOT LIKE 'sqlite%'
  AND name NOT LIKE '\\_\\_%' ESCAPE '\\'
  ''');

  // Map to string
  return tables.map((row) => row['name'] as String).toList();
}

Attribute _getAttribute(Row attribute, {ForeignKeyInfo? fkInfo, bool isAutoIncrement = false}) {
  // Format and return attribute
  return Attribute(
    columnID: attribute["cid"],
    name: attribute["name"],
    dataType: attribute["type"],
    isNotNullable: attribute["notnull"] == 0 ? false : true,
    defaultValue: attribute["dflt_value"],
    isPrimaryKey: attribute["pk"] == 0 ? false : true,
    fkInfo: fkInfo,
    isAutoIncrement: isAutoIncrement,
  );

}


bool isAutoIncrementColumn(Database db, String tableName, String columnName) {
  final rows = db.select(
    '''
    SELECT sql
    FROM sqlite_master
    WHERE type = 'table'
      AND name = ?
    ''',
    [tableName],
  );

  if (rows.isEmpty) return false;

  final createSql = (rows.first['sql'] as String).toUpperCase();

  final pattern =
      '${columnName.toUpperCase()} INTEGER PRIMARY KEY AUTOINCREMENT';

  return createSql.contains(pattern);
}