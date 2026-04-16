import 'package:sqlite3/sqlite3.dart';

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

  List<String> allTables() {
    return tables.toList();
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

  List<TableRelationship> ancestorPathFromSelected(String selected) {

    //checking for edge case: Single table, no relationships
    if(tables.length == 1 && tables.contains(selected)) {
      //return an empty list as there are NO relationships in this schema
      return [];
    }

    final pathList = <List<TableRelationship>>[];

    //building all possible ancestry paths (in case there are multiple chains)
    final leafList = leafTables();
    for(final leaf in leafList) {
      pathList.add(ancestorPathFromLeaf(leaf));
    }

    //identifying which chain the selected table actually belongs to
    for(final path in pathList) {

      //checking if the selected table is the root of this path
      if(path.isNotEmpty && path.last.parentTable == selected) {
        return path;
      }

      for(final edge in path) {
        if(edge.childTable == selected) {
          return path;
        }
      }
    }

    return pathList.first;
  }

  //returns the ordered list of table names from the root to the leaf table
  List<String> orderedTablesRootToLeaf(List<TableRelationship> pathFromLeaf, String selected) {

    //creating a list of table names, and populating the first one with the leaf
    final tables = <String>[];

    //guarding against single table case (no relationships)
    if(pathFromLeaf.isEmpty) {
      return [selected];
    }

    //adding the first (leaf) table to the path
    tables.add(pathFromLeaf.first.childTable);

    //populating the rest of the table names
    for(final edge in pathFromLeaf) {
      tables.add(edge.parentTable);
    }

    //returning the list from the root to the leaf rather than vice versa
    return tables.reversed.toList();
  }
}


SchemaGraph buildGraph( Database db ) {

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