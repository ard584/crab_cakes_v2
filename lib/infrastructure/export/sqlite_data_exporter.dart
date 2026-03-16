import 'dart:io';
import 'package:sqlite3/sqlite3.dart';
import 'package:ui_prototype/application/export/interfaces/data_exporter.dart';


class SqliteDataExporter implements DataExporter {
  final Database db;

  SqliteDataExporter( this.db );  


  @override //NOTE: EXPORTING ONY WORKS FOR SINGLE TABLE SCHEMAS FOR NOW
  Future<void> export(String tableName, String filePath) async {
    final file = File(filePath);
    final sink = file.openWrite();

    try {
      // Get column names
      final columnInfo = db.select('PRAGMA table_info($tableName);');
      final columns = columnInfo.map((row) => row['name'] as String).toList();

      // Write CSV header
      sink.writeln(columns.join(','));

      // Query all rows
      final rows = db.select('SELECT * FROM $tableName;');

      // Write each row
      for (final row in rows) {
        final values = columns.map((col) => _escapeCsv(row[col]));
        sink.writeln(values.join(','));
      }
    } finally {
      await sink.close();
    }
    
  }

  String _escapeCsv(Object? value) {
    if (value == null) return '';

    final str = value.toString();

    if (str.contains(',') || str.contains('"') || str.contains('\n')) {
      return '"${str.replaceAll('"', '""')}"';
    }

    return str;
  }

  // List<String> _formatRows() {
  //   final graph = _buildGraph();

  //   final leafTables = graph.leafTables();
  //   final rootTables = graph.rootTables();


  // }

  SchemaGraph _buildGraph() {

    final tableList = db.select(''' 
      SELECT name
      FROM sqlite_master
      WHERE type = 'table'
      AND name NOT LIKE 'sqlite_%'
      AND name NOT LIKE '__%
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
            childCol: tableName,
            childTable: fk['name'] as String,
            parentTable: fk['table'] as String,
            parentCol: fk['to'] as String,
          ),
        );
      }
    }
    return SchemaGraph(relationships: relationships, tables: tables);
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
}