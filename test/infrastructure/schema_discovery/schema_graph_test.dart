import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:crab_cakes/infrastructure/schema_discovery/schema_graph.dart';

void main() {
  group('SchemaGraph pure graph methods', () {
    TableRelationship edge({
      required String childTable,
      required String childCol,
      required String parentTable,
      required String parentCol,
    }) {
      return TableRelationship(
        childTable: childTable,
        childCol: childCol,
        parentTable: parentTable,
        parentCol: parentCol,
      );
    }

    test('parentsOf returns empty list when table has no parent', () {
      final graph = SchemaGraph(
        tables: {'Trip'},
        relationships: [],
      );

      expect(graph.parentsOf('Trip'), isEmpty);
    });

    test('parentsOf returns direct parent table', () {
      final graph = SchemaGraph(
        tables: {'Trip', 'Sample'},
        relationships: [
          edge(
            childTable: 'Sample',
            childCol: 'trip_id',
            parentTable: 'Trip',
            parentCol: 'id',
          ),
        ],
      );

      expect(graph.parentsOf('Sample'), ['Trip']);
    });

    test('parentsOf deduplicates duplicate parent relationships', () {
      final graph = SchemaGraph(
        tables: {'Trip', 'Sample'},
        relationships: [
          edge(
            childTable: 'Sample',
            childCol: 'trip_id',
            parentTable: 'Trip',
            parentCol: 'id',
          ),
          edge(
            childTable: 'Sample',
            childCol: 'trip_id_copy',
            parentTable: 'Trip',
            parentCol: 'id',
          ),
        ],
      );

      expect(graph.parentsOf('Sample'), ['Trip']);
    });

    test('childrenOf returns empty list when table has no children', () {
      final graph = SchemaGraph(
        tables: {'Trip'},
        relationships: [],
      );

      expect(graph.childrenOf('Trip'), isEmpty);
    });

    test('childrenOf returns direct child table', () {
      final graph = SchemaGraph(
        tables: {'Trip', 'Sample'},
        relationships: [
          edge(
            childTable: 'Sample',
            childCol: 'trip_id',
            parentTable: 'Trip',
            parentCol: 'id',
          ),
        ],
      );

      expect(graph.childrenOf('Trip'), ['Sample']);
    });

    test('childrenOf deduplicates duplicate child relationships', () {
      final graph = SchemaGraph(
        tables: {'Trip', 'Sample'},
        relationships: [
          edge(
            childTable: 'Sample',
            childCol: 'trip_id',
            parentTable: 'Trip',
            parentCol: 'id',
          ),
          edge(
            childTable: 'Sample',
            childCol: 'trip_id_copy',
            parentTable: 'Trip',
            parentCol: 'id',
          ),
        ],
      );

      expect(graph.childrenOf('Trip'), ['Sample']);
    });

    test('rootTables returns single table when there are no relationships', () {
      final graph = SchemaGraph(
        tables: {'Trip'},
        relationships: [],
      );

      expect(graph.rootTables(), ['Trip']);
    });

    test('rootTables returns parent/root table in simple chain', () {
      final graph = SchemaGraph(
        tables: {'Trip', 'Sample', 'Specimen'},
        relationships: [
          edge(
            childTable: 'Sample',
            childCol: 'trip_id',
            parentTable: 'Trip',
            parentCol: 'id',
          ),
          edge(
            childTable: 'Specimen',
            childCol: 'sample_id',
            parentTable: 'Sample',
            parentCol: 'id',
          ),
        ],
      );

      expect(graph.rootTables(), ['Trip']);
    });

    test('leafTables returns single table when there are no relationships', () {
      final graph = SchemaGraph(
        tables: {'Trip'},
        relationships: [],
      );

      expect(graph.leafTables(), ['Trip']);
    });

    test('leafTables returns leaf table in simple chain', () {
      final graph = SchemaGraph(
        tables: {'Trip', 'Sample', 'Specimen'},
        relationships: [
          edge(
            childTable: 'Sample',
            childCol: 'trip_id',
            parentTable: 'Trip',
            parentCol: 'id',
          ),
          edge(
            childTable: 'Specimen',
            childCol: 'sample_id',
            parentTable: 'Sample',
            parentCol: 'id',
          ),
        ],
      );

      expect(graph.leafTables(), ['Specimen']);
    });

    test('allTables returns all table names', () {
      final graph = SchemaGraph(
        tables: {'Trip', 'Sample', 'Specimen'},
        relationships: [],
      );

      expect(
        graph.allTables().toSet(),
        {'Trip', 'Sample', 'Specimen'},
      );
    });

    test('parentEdgeOf returns null when table has no parent', () {
      final graph = SchemaGraph(
        tables: {'Trip'},
        relationships: [],
      );

      expect(graph.parentEdgeOf('Trip'), isNull);
    });

    test('parentEdgeOf returns parent relationship when there is one parent', () {
      final graph = SchemaGraph(
        tables: {'Trip', 'Sample'},
        relationships: [
          edge(
            childTable: 'Sample',
            childCol: 'trip_id',
            parentTable: 'Trip',
            parentCol: 'id',
          ),
        ],
      );

      final parentEdge = graph.parentEdgeOf('Sample');

      expect(parentEdge, isNotNull);
      expect(parentEdge!.childTable, 'Sample');
      expect(parentEdge.childCol, 'trip_id');
      expect(parentEdge.parentTable, 'Trip');
      expect(parentEdge.parentCol, 'id');
    });

    test('parentEdgeOf throws when table has multiple parents', () {
      final graph = SchemaGraph(
        tables: {'Trip', 'Site', 'Sample'},
        relationships: [
          edge(
            childTable: 'Sample',
            childCol: 'trip_id',
            parentTable: 'Trip',
            parentCol: 'id',
          ),
          edge(
            childTable: 'Sample',
            childCol: 'site_id',
            parentTable: 'Site',
            parentCol: 'id',
          ),
        ],
      );

      expect(
        () => graph.parentEdgeOf('Sample'),
        throwsException,
      );
    });

    test('ancestorPathFromLeaf returns empty path for root table', () {
      final graph = SchemaGraph(
        tables: {'Trip'},
        relationships: [],
      );

      expect(graph.ancestorPathFromLeaf('Trip'), isEmpty);
    });

    test('ancestorPathFromLeaf returns path from leaf toward root', () {
      final graph = SchemaGraph(
        tables: {'Trip', 'Sample', 'Specimen'},
        relationships: [
          edge(
            childTable: 'Sample',
            childCol: 'trip_id',
            parentTable: 'Trip',
            parentCol: 'id',
          ),
          edge(
            childTable: 'Specimen',
            childCol: 'sample_id',
            parentTable: 'Sample',
            parentCol: 'id',
          ),
        ],
      );

      final path = graph.ancestorPathFromLeaf('Specimen');

      expect(path.length, 2);

      expect(path[0].childTable, 'Specimen');
      expect(path[0].parentTable, 'Sample');

      expect(path[1].childTable, 'Sample');
      expect(path[1].parentTable, 'Trip');
    });

    test('ancestorPathFromLeaf throws when a table in path has multiple parents', () {
      final graph = SchemaGraph(
        tables: {'Trip', 'Site', 'Sample', 'Specimen'},
        relationships: [
          edge(
            childTable: 'Sample',
            childCol: 'trip_id',
            parentTable: 'Trip',
            parentCol: 'id',
          ),
          edge(
            childTable: 'Sample',
            childCol: 'site_id',
            parentTable: 'Site',
            parentCol: 'id',
          ),
          edge(
            childTable: 'Specimen',
            childCol: 'sample_id',
            parentTable: 'Sample',
            parentCol: 'id',
          ),
        ],
      );

      expect(
        () => graph.ancestorPathFromLeaf('Specimen'),
        throwsException,
      );
    });

    test('ancestorPathFromSelected returns empty path for single table schema', () {
      final graph = SchemaGraph(
        tables: {'Trip'},
        relationships: [],
      );

      expect(graph.ancestorPathFromSelected('Trip'), isEmpty);
    });

    test('ancestorPathFromSelected returns full chain when selected is leaf', () {
      final graph = SchemaGraph(
        tables: {'Trip', 'Sample', 'Specimen'},
        relationships: [
          edge(
            childTable: 'Sample',
            childCol: 'trip_id',
            parentTable: 'Trip',
            parentCol: 'id',
          ),
          edge(
            childTable: 'Specimen',
            childCol: 'sample_id',
            parentTable: 'Sample',
            parentCol: 'id',
          ),
        ],
      );

      final path = graph.ancestorPathFromSelected('Specimen');

      expect(path.length, 2);
      expect(path[0].childTable, 'Specimen');
      expect(path[0].parentTable, 'Sample');
      expect(path[1].childTable, 'Sample');
      expect(path[1].parentTable, 'Trip');
    });

    test('ancestorPathFromSelected returns full chain when selected is middle table', () {
      final graph = SchemaGraph(
        tables: {'Trip', 'Sample', 'Specimen'},
        relationships: [
          edge(
            childTable: 'Sample',
            childCol: 'trip_id',
            parentTable: 'Trip',
            parentCol: 'id',
          ),
          edge(
            childTable: 'Specimen',
            childCol: 'sample_id',
            parentTable: 'Sample',
            parentCol: 'id',
          ),
        ],
      );

      final path = graph.ancestorPathFromSelected('Sample');

      expect(path.length, 2);
      expect(path[0].childTable, 'Specimen');
      expect(path[0].parentTable, 'Sample');
      expect(path[1].childTable, 'Sample');
      expect(path[1].parentTable, 'Trip');
    });

    test('ancestorPathFromSelected returns full chain when selected is root table', () {
      final graph = SchemaGraph(
        tables: {'Trip', 'Sample', 'Specimen'},
        relationships: [
          edge(
            childTable: 'Sample',
            childCol: 'trip_id',
            parentTable: 'Trip',
            parentCol: 'id',
          ),
          edge(
            childTable: 'Specimen',
            childCol: 'sample_id',
            parentTable: 'Sample',
            parentCol: 'id',
          ),
        ],
      );

      final path = graph.ancestorPathFromSelected('Trip');

      expect(path.length, 2);
      expect(path[0].childTable, 'Specimen');
      expect(path[0].parentTable, 'Sample');
      expect(path[1].childTable, 'Sample');
      expect(path[1].parentTable, 'Trip');
    });

    test('orderedTablesRootToLeaf returns selected table for empty path', () {
      final graph = SchemaGraph(
        tables: {'Trip'},
        relationships: [],
      );

      final ordered = graph.orderedTablesRootToLeaf([], 'Trip');

      expect(ordered, ['Trip']);
    });

    test('orderedTablesRootToLeaf returns root to leaf order', () {
      final graph = SchemaGraph(
        tables: {'Trip', 'Sample', 'Specimen'},
        relationships: [
          edge(
            childTable: 'Sample',
            childCol: 'trip_id',
            parentTable: 'Trip',
            parentCol: 'id',
          ),
          edge(
            childTable: 'Specimen',
            childCol: 'sample_id',
            parentTable: 'Sample',
            parentCol: 'id',
          ),
        ],
      );

      final path = graph.ancestorPathFromLeaf('Specimen');
      final ordered = graph.orderedTablesRootToLeaf(path, 'Specimen');

      expect(ordered, ['Trip', 'Sample', 'Specimen']);
    });
  });

  group('buildGraph database discovery', () {
    late Database db;

    setUp(() {
      db = sqlite3.openInMemory();

      db.execute('PRAGMA foreign_keys = ON;');
    });

    tearDown(() {
      db.dispose();
    });

    test('buildGraph discovers single user table', () {
      db.execute('''
        CREATE TABLE Trip (
          id INTEGER PRIMARY KEY,
          name TEXT
        );
      ''');

      final graph = buildGraph(db);

      expect(graph.tables, {'Trip'});
      expect(graph.relationships, isEmpty);
      expect(graph.rootTables(), ['Trip']);
      expect(graph.leafTables(), ['Trip']);
    });

    test('buildGraph excludes __project_settings table', () {
      db.execute('''
        CREATE TABLE __project_settings (
          id INTEGER PRIMARY KEY,
          settings_json TEXT NOT NULL
        );
      ''');

      db.execute('''
        CREATE TABLE Trip (
          id INTEGER PRIMARY KEY,
          name TEXT
        );
      ''');

      final graph = buildGraph(db);

      expect(graph.tables, {'Trip'});
      expect(graph.tables.contains('__project_settings'), isFalse);
    });

    test('buildGraph discovers parent child relationship from foreign key', () {
      db.execute('''
        CREATE TABLE Trip (
          id INTEGER PRIMARY KEY,
          name TEXT
        );
      ''');

      db.execute('''
        CREATE TABLE Sample (
          id INTEGER PRIMARY KEY,
          trip_id INTEGER,
          FOREIGN KEY (trip_id) REFERENCES Trip(id)
        );
      ''');

      final graph = buildGraph(db);

      expect(graph.tables, {'Trip', 'Sample'});
      expect(graph.relationships.length, 1);

      final relationship = graph.relationships.first;

      expect(relationship.childTable, 'Sample');
      expect(relationship.childCol, 'trip_id');
      expect(relationship.parentTable, 'Trip');
      expect(relationship.parentCol, 'id');

      expect(graph.parentsOf('Sample'), ['Trip']);
      expect(graph.childrenOf('Trip'), ['Sample']);
    });

    test('buildGraph discovers full Trip Sample Specimen chain', () {
      db.execute('''
        CREATE TABLE Trip (
          id INTEGER PRIMARY KEY,
          name TEXT
        );
      ''');

      db.execute('''
        CREATE TABLE Sample (
          id INTEGER PRIMARY KEY,
          trip_id INTEGER,
          FOREIGN KEY (trip_id) REFERENCES Trip(id)
        );
      ''');

      db.execute('''
        CREATE TABLE Specimen (
          id INTEGER PRIMARY KEY,
          sample_id INTEGER,
          tag_id TEXT,
          FOREIGN KEY (sample_id) REFERENCES Sample(id)
        );
      ''');

      final graph = buildGraph(db);

      expect(graph.tables, {'Trip', 'Sample', 'Specimen'});
      expect(graph.relationships.length, 2);
      expect(graph.rootTables(), ['Trip']);
      expect(graph.leafTables(), ['Specimen']);

      final path = graph.ancestorPathFromLeaf('Specimen');
      final ordered = graph.orderedTablesRootToLeaf(path, 'Specimen');

      expect(ordered, ['Trip', 'Sample', 'Specimen']);
    });

    test('buildGraph supports custom parent key column', () {
      db.execute('''
        CREATE TABLE Trip (
          trip_code TEXT PRIMARY KEY,
          name TEXT
        );
      ''');

      db.execute('''
        CREATE TABLE Sample (
          id INTEGER PRIMARY KEY,
          trip_code TEXT,
          FOREIGN KEY (trip_code) REFERENCES Trip(trip_code)
        );
      ''');

      final graph = buildGraph(db);

      expect(graph.relationships.length, 1);

      final relationship = graph.relationships.first;

      expect(relationship.childTable, 'Sample');
      expect(relationship.childCol, 'trip_code');
      expect(relationship.parentTable, 'Trip');
      expect(relationship.parentCol, 'trip_code');
    });
  });
}