import 'package:sqlite3/sqlite3.dart';
import 'package:ui_prototype/application/project/interfaces/schema_structure_validator.dart';
import 'package:ui_prototype/infrastructure/schema_discovery/schema_graph.dart';


class SqliteSchemaStructureValidator implements SchemaStructureValidator {
  @override
  Future<bool> isValid(List<String> statements) async {
    
    //construct a temporary database
    final Database db = sqlite3.openInMemory();

    try {
      db.execute('PRAGMA foreign_keys = ON;');

      for(final statement in statements) {
        db.execute(statement);
      }

      //generate the graph of the database
      final graph = buildGraph(db);

      // verify validity
      return _isLinearSchema(graph);
    } finally {
      //always close the temp db
      db.dispose();
    }
  }

  bool _isLinearSchema(SchemaGraph graph) {
    // Empty schema is not useful.
    if (graph.tables.isEmpty) return false;

    // Single table with no relationships is valid.
    if (graph.tables.length == 1 && graph.relationships.isEmpty) {
      return true;
    }

    // Every relationship should point to a known table.
    for (final rel in graph.relationships) {
      if (!graph.tables.contains(rel.childTable)) return false;
      if (!graph.tables.contains(rel.parentTable)) return false;
    }

    // No table may have more than one parent.
    for (final table in graph.tables) {
      if (graph.parentsOf(table).length > 1) {
        return false;
      }
    }

    // No table may have more than one child.
    // This prevents tree structures.
    for (final table in graph.tables) {
      if (graph.childrenOf(table).length > 1) {
        return false;
      }
    }

    final roots = graph.rootTables();
    final leaves = graph.leafTables();

    // A linear chain should have exactly one root and one leaf.
    if (roots.length != 1) return false;
    if (leaves.length != 1) return false;

    // Walk from root to leaf and make sure we visit every table once.
    final visited = <String>{};
    var current = roots.first;

    while (true) {
      if (visited.contains(current)) {
        return false; // cycle
      }

      visited.add(current);

      final children = graph.childrenOf(current);

      if (children.isEmpty) {
        break;
      }

      if (children.length > 1) {
        return false;
      }

      current = children.first;
    }

    // If some table was not visited, then the schema has disconnected parts.
    if (visited.length != graph.tables.length) {
      return false;
    }

    // Make sure the walk ended at the only leaf.
    if (current != leaves.first) {
      return false;
    }

    return true;
  }
}