import 'dart:io';
import 'package:sqlite3/sqlite3.dart';
import 'package:crab_cakes/application/export/interfaces/data_exporter.dart';
import 'package:crab_cakes/infrastructure/schema_discovery/schema_graph.dart';

import 'package:crab_cakes/infrastructure/providers/column_filter_provider.dart';


class SqliteDataExporter implements DataExporter {
  final Database db;
  
  var DELIMITER = ',';

  SqliteDataExporter( this.db );  

  @override
  Future<List<String>> getTables() async {
    final graph = buildGraph(db);

    final tableList = graph.allTables();

    return _filterTableList(tableList);

  }


  @override //NOTE: EXPORTING ONY WORKS FOR CHAIN SCHEMA STRUCTURES!
  Future<void> export(String tableName, String filePath, String delimiter) async {
    DELIMITER = delimiter;

    //add extension to the end of the file name
    filePath = filePath;

    final file = File(filePath);
    final sink = file.openWrite();

    try {

      //create the schema graph
      final graph = buildGraph(db);
      final columnMap = _getColumnMap();

      //this ancestor path starts at the leaf table, ends at the root, and contains
      //the specified table
      final ancestorPath = graph.ancestorPathFromSelected(tableName);
      final orderedTableList = graph.orderedTablesRootToLeaf(ancestorPath, tableName);
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

      // Write each row to the CSV file
      for (final row in rows) {
        final values = aliases.map((alias)=> _escapeCsv(row[alias])).toList();

        sink.writeln(values.join(DELIMITER));
      }
    } finally {
      await sink.close();
    }  
  }

  List<String> _filterTableList( List<String> list ) {
    final filtered = list.where((t) {
      final rows = db.select('''
        SELECT 1 FROM "$t" LIMIT 1
      ''');

        return rows.isNotEmpty;
    }).toList();

    return filtered;
  }


  List<String> _buildExportAliases(          List<String> orderedTables,
                                Map<String, List<String>> columnsByTable,
                                List<TableRelationship> ancestorPath) {

    //building the specs by excluding the foreign key redundancies
    final specs = _buildExportColumnSpecs(orderedTables, columnsByTable, ancestorPath);

    //selecting only the list of aliases to return 
    return specs.map((s)=>s.alias).toList();
  }

  
  String _buildHeader(          List<String> orderedTables,
                                Map<String, List<String>> columnsByTable,
                                List<TableRelationship> ancestorPath) {

    final aliases = _buildExportAliases(orderedTables, columnsByTable, ancestorPath);

    return aliases.join(DELIMITER);
  }

  //builds a JOIN clause using the relationships from ancestor path from the schema graph
  String _buildJoinClause(String selectedTable, List<TableRelationship> ancestorPathFromLeaf) {

    //checking for edge case: single table, no relationships
    if(ancestorPathFromLeaf.isEmpty) {
      return 'FROM $selectedTable\n';
    }

    final buffer = StringBuffer('FROM $selectedTable\n');

    //checking for edge case: selected table IS the root table
    final isRootSelected = ancestorPathFromLeaf.isNotEmpty &&
                        ancestorPathFromLeaf.last.parentTable == selectedTable;

    var index = 0;
    var selectedIndex = ancestorPathFromLeaf.indexWhere((rel)=>rel.childTable == selectedTable);

    //guarding against the selected table not being in the provided chain
    if (!isRootSelected && selectedIndex == -1) {
      throw Exception('Selected table $selectedTable is not on the export path.');
    }
    
    //if the selected table is the root, there are NO ancestors, skip this part
    if(!isRootSelected) {
      //generating all ancestor Joins (No special treatment needed)
      for(index = selectedIndex; index < ancestorPathFromLeaf.length; index++) {
        final edge = ancestorPathFromLeaf[index];    
        buffer.writeln(
          'JOIN ${edge.parentTable} '
          'ON ${edge.childTable}.${edge.childCol} = '
          '${edge.parentTable}.${edge.parentCol}'
        );
      }
    } else {
      //setting the selected index to the end of the list
      selectedIndex = ancestorPathFromLeaf.length;
    }
    

    //resetting the index to the beginning of the list, now we iterate from the
    //beginning (leaf) to the table right before the selected table. These are
    //the descendents of the selected table (I.E. VIE marks is a descendent to Specimen)
    // Important: ancestorPathFromLeaf is ordered leaf -> root, so descendant joins
    
    // must be emitted in reverse order. Otherwise SQLite can see an ON clause that
    // references a table that has not been joined yet.
    for (index = selectedIndex - 1; index >= 0; index--) {
      final edge = ancestorPathFromLeaf[index];

      buffer.writeln(
        'LEFT JOIN ${edge.childTable} '
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

    //building the specs by excluding the foreign key redundancies
    final specs = _buildExportColumnSpecs(orderedTables, columnsByTable, ancestorPath);

    //using the aliases to create select statements for all cols
    final selectParts = specs.map((s)=>'${s.table}.${s.column} AS ${s.alias}').toList();

    return 'SELECT\n${selectParts.join(',\n')}';
  }

  //helper class to decide which columns to include and which to exclude.
  // NOTE: This is the same logic used for both select and header builder
  List<ExportColumnSpec> _buildExportColumnSpecs(
    List<String> orderedTables,
    Map<String, List<String>> colsByTable,
    List<TableRelationship> ancestorPath
  ) {
    //extracting the foreign keys to exclude from the CSV file
    final foreignKeys = <String>{};

    for(final edge in ancestorPath) {
      foreignKeys.add('${edge.childTable}.${edge.childCol}');
    }

    final specs = <ExportColumnSpec>[];

    for (final table in orderedTables) {
      final cols = colsByTable[table] ?? [];

      for(final col in cols) {
        final selectedCol = '$table.$col';

        //excluding redundant foreign key columns
        if(!foreignKeys.contains(selectedCol)) {
          specs.add(
            ExportColumnSpec(table: table, column: col, alias: '${table}_$col')
          );
        }
      }
    }
    return specs;
  }

  String _escapeCsv(Object? value) {
    if (value == null) return '';

    final str = value.toString();

    if (str.contains(DELIMITER) || str.contains('"') || str.contains('\n')) {
      return '"${str.replaceAll('"', '""')}"';
    }

    return str;
  }

  Map<String, List<String>> _getColumnMap() {

    final colMap = <String, List<String>>{};

    final tableList = db.select(''' 
      SELECT name
      FROM sqlite_master
      WHERE type = 'table'
      AND name NOT LIKE 'sqlite_%'
      AND name NOT LIKE '\\_\\_%' ESCAPE '\\'
      ORDER BY name;''');

    for(final row in tableList) {
      final tableName = row['name'] as String;
      final rows = db.select("PRAGMA table_info($tableName);");
      final cols = filterColumnsByPrefix(rows.map((r) => r['name'] as String).toList(), true);

      colMap[tableName] = cols;
    }

  return colMap;
  }
}

//----------------- HELPER CLASSES ----------------------------------



//helper class that contains the specs for one column to be exported
//I.E. the table and column it originates from + its alias
class ExportColumnSpec {
  final String table;
  final String column;
  final String alias;

  ExportColumnSpec({
    required this.table,
    required this.column,
    required this.alias
  });
}