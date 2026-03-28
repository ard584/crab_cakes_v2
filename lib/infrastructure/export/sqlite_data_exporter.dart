import 'dart:ffi';
import 'dart:io';
import 'package:sqlite3/sqlite3.dart';
import 'package:ui_prototype/application/export/interfaces/data_exporter.dart';


class SqliteDataExporter implements DataExporter {
  final Database db;
  
  var DELIMITER = ',';

  SqliteDataExporter( this.db );  

  @override
  Future<List<String>> getBaseTables() async {
    final graph = _buildGraph();

    return graph.leafTables();
  }


  @override //NOTE: EXPORTING ONY WORKS FOR TREE AND CHAIN SCHEMA STRUCTURES!
  Future<void> export(String tableName, String filePath, String delimiter) async {
    DELIMITER = delimiter;

    final file = File(filePath);
    final sink = file.openWrite();

    try {
      // Get column names
      // final columnInfo = db.select('PRAGMA table_info($tableName);');
      // final columns = columnInfo.map((row) => row['name'] as String).toList();

      //create the schema graph
      final graph = _buildGraph();
      
      final orderedTableList = graph.orderedTablesRootToLeaf(tableName);
      final columnMap = _getColumnMap();
      final ancestorPath = graph.ancestorPathFromLeaf(tableName);
      final aliases = _buildExportAliases(orderedTableList, columnMap, ancestorPath);

      // Write CSV header
      sink.writeln(_buildHeader(orderedTableList, columnMap, ancestorPath));

      //build the select statement
      final selectStatement = _buildSelectStatement(orderedTableList, columnMap, 
                                                                  ancestorPath);

      //build the join clause
      final joinClause = _buildJoinClause(tableName, ancestorPath);

      //build the complete select and join statement
      final finalQuery = '$selectStatement\n$joinClause';

      // Query all rows
      final rows = db.select(finalQuery);

      // Write each row
      for (final row in rows) {
        final values = aliases.map((alias)=> _escapeCsv(row[alias])).toList();

        //No idea what to do here.
        sink.writeln(values.join(DELIMITER));
      }
    } finally {
      await sink.close();
    }  
  }


  List<String> _buildExportAliases(          List<String> orderedTables,
                                Map<String, List<String>> columnsByTable,
                                List<TableRelationship> ancestorPath) {
    //extracting the foreign keys to exclude from the CSV file
    final foreignKeys = <String>{};

    for(final edge in ancestorPath) {
      foreignKeys.add('${edge.childTable}.${edge.childCol}');
    }

    final aliases = <String>[];

    for(final table in orderedTables) {
      final cols = columnsByTable[table] ?? [];

      for(final col in cols) {
      final selectedCol = "$table.$col";

      //making sure the selected column is NOT a foreign key (so its not redundant)
      if(!foreignKeys.contains(selectedCol)) {
        aliases.add(
          "${table}_$col"
        );
      }
      }
    }
    return aliases;
  }

  
  String _buildHeader(          List<String> orderedTables,
                                Map<String, List<String>> columnsByTable,
                                List<TableRelationship> ancestorPath) {

    final aliases = _buildExportAliases(orderedTables, columnsByTable, ancestorPath);

    return aliases.join(DELIMITER);
  }

  //builds a JOIN clause using the relationships from ancestor path from the schema graph
  String _buildJoinClause(String leafTable, List<TableRelationship> ancestorPath) {
    final buffer = StringBuffer('FROM $leafTable\n');

    for(final edge in ancestorPath) {
      buffer.writeln(
        'JOIN ${edge.parentTable} '
        'ON ${edge.childTable}.${edge.childCol} = '
        '${edge.parentTable}.${edge.parentCol}'
      );
    }
    return buffer.toString();
  }

  //iterates over the tables IN ORDER from root to leaf, selects all columns EXCEPT the foreign key columns
  String _buildSelectStatement( List<String> orderedTables,
                                Map<String, List<String>> columnsByTable,
                                List<TableRelationship> ancestorPath) {

    //extracting the foreign keys to exclude from the CSV file
    final foreignKeys = <String>{};

    for(final edge in ancestorPath) {
      foreignKeys.add('${edge.childTable}.${edge.childCol}');
    }

    final selectParts = <String>[];

    for(final table in orderedTables) {
       final cols = columnsByTable[table] ?? [];

       for(final col in cols) {
        final selectedCol = "$table.$col";

        //making sure the selected column is NOT a foreign key (so its not redundant)
        if(!foreignKeys.contains(selectedCol)) {
          selectParts.add(
            "$selectedCol AS ${table}_$col"
          );
        }
        
       }
    }

    return 'SELECT\n${selectParts.join(',\n')}';
  }

  String _escapeCsv(Object? value) {
    if (value == null) return '';

    final str = value.toString();

    if (str.contains(DELIMITER) || str.contains('"') || str.contains('\n')) {
      return '"${str.replaceAll('"', '""')}"';
    }

    return str;
  }


  SchemaGraph _buildGraph() {

    final tableList = db.select(''' 
      SELECT name
      FROM sqlite_master
      WHERE type = 'table'
      AND name NOT LIKE 'sqlite_%'
      AND name != '__project_settings'
      ORDER BY name;''');

    final tables = <String>{};
    final relationships = <TableRelationship>[];

    for(final row in tableList) {
      final tableName = row['name'] as String;
      tables.add(tableName);

      final fkRows = db.select('PRAGMA foreign_key_list($tableName);');

      for(final fk in fkRows) {
        relationships.add(
          TableRelationship(
            childTable: tableName,
            childCol: fk['from'] as String,
            parentTable: fk['table'] as String,
            parentCol: fk['to'] as String,
          ),
        );
      }
    }
    return SchemaGraph(relationships: relationships, tables: tables);
  }

  Map<String, List<String>> _getColumnMap() {

    final colMap = <String, List<String>>{};

    final tableList = db.select(''' 
      SELECT name
      FROM sqlite_master
      WHERE type = 'table'
      AND name NOT LIKE 'sqlite_%'
      AND name != '__project_settings'
      ORDER BY name;''');

    for(final row in tableList) {
      final tableName = row['name'] as String;
      final rows = db.select("PRAGMA table_info($tableName);");
      final cols = rows.map((r)=>r['name'] as String).toList();

      colMap[tableName] = cols;
    }

  return colMap;
  }
}

//----------------- HELPER CLASSES ----------------------------------

class TableRelationship {
  final String childTable;
  final String childCol;
  final String parentTable;
  final String parentCol;

  TableRelationship({
    required this.childTable,
    required this.childCol,
    required this.parentTable,
    required this.parentCol,
  });
}


class SchemaGraph {
  final Set<String> tables;
  final List<TableRelationship> relationships;

  SchemaGraph({
    required this.tables,
    required this.relationships,
  });

  List<String> parentsOf(String table) {
    return relationships
      .where((r)=> r.childTable == table)
      .map((r)=>r.parentTable)
      .toSet()
      .toList();
  }

  List<String> childrenOf(String table) {
    return relationships
      .where((r)=>r.parentTable == table)
      .map((r)=>r.childTable)
      .toSet()
      .toList();
  }

  List<String> rootTables() {
    return tables.where((r)=>(parentsOf(r).isEmpty)).toList();
  }

  List<String> leafTables() {
    return tables.where((r)=>(childrenOf(r).isEmpty)).toList();
  }

  TableRelationship? parentEdgeOf(String childTable) {
    final matches = relationships
        .where((r) => r.childTable == childTable)
        .toList();

    if (matches.isEmpty) return null;

    if (matches.length > 1) {
      throw Exception(
        'Table $childTable has multiple parents. '
        'This is outside current export support.',
      );
    }

    return matches.first;
  }

  List<TableRelationship> ancestorPathFromLeaf(String leafTable) {
    final path = <TableRelationship>[];
    var current = leafTable;

    while (true) {
      final parentEdge = parentEdgeOf(current);
      if (parentEdge == null) break;

      path.add(parentEdge);
      current = parentEdge.parentTable;
    }

    return path;
  }

  List<String> orderedTablesRootToLeaf(String leafTable) {
    final path = ancestorPathFromLeaf(leafTable);

    final tables = <String>[leafTable];
    for(final edge in path) {
      tables.add(edge.parentTable);
    }

    return tables.reversed.toList();
  }
}