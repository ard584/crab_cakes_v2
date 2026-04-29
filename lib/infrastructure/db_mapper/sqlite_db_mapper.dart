import 'package:sqlite3/sqlite3.dart';
import 'package:ui_prototype/application/db_mapper/db_mapper.dart';
import 'package:ui_prototype/domain/models/attribute.dart';
import 'package:ui_prototype/domain/models/project_db.dart';
import 'package:ui_prototype/domain/models/table.dart';

class SqliteDbMapper implements DbMapper {
  @override
  ProjectDb mapDB(db) {
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
    } catch (e) {
      throw Exception(
        "[createDbObject] Error occurred while mapping database: $e",
      );
    }
  }

  // Read attributes from given tablename
  List<Attribute> _readAttributes(Database db, String tableName) {
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
}


