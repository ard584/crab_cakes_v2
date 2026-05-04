import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:crab_cakes/infrastructure/schema_discovery/sqlite_schema_discovery_repo.dart';

void main() {
  group('SqliteSchemaDiscoveryRepo getTables', () {
    late Database db;
    late SqliteSchemaDiscoveryRepo repo;

    setUp(() {
      db = sqlite3.openInMemory();
      repo = SqliteSchemaDiscoveryRepo(db);
    });

    tearDown(() {
      db.dispose();
    });

    test('returns empty list when database has no user tables', () async {
      final tables = await repo.getTables();

      expect(tables, isEmpty);
    });

    test('returns a single user table', () async {
      db.execute('''
        CREATE TABLE Trip (
          id INTEGER PRIMARY KEY,
          name TEXT
        );
      ''');

      final tables = await repo.getTables();

      expect(tables, ['Trip']);
    });

    test('returns multiple user tables sorted by name', () async {
      db.execute('''
        CREATE TABLE Specimen (
          id INTEGER PRIMARY KEY
        );
      ''');

      db.execute('''
        CREATE TABLE Trip (
          id INTEGER PRIMARY KEY
        );
      ''');

      db.execute('''
        CREATE TABLE Sample (
          id INTEGER PRIMARY KEY
        );
      ''');

      final tables = await repo.getTables();

      expect(tables, ['Sample', 'Specimen', 'Trip']);
    });

    test('excludes __project_settings table', () async {
      db.execute('''
        CREATE TABLE __project_settings (
          id INTEGER PRIMARY KEY,
          settings_json TEXT NOT NULL
        );
      ''');

      db.execute('''
        CREATE TABLE Trip (
          id INTEGER PRIMARY KEY
        );
      ''');

      final tables = await repo.getTables();

      expect(tables, ['Trip']);
      expect(tables.contains('__project_settings'), isFalse);
    });

    test('excludes sqlite internal tables created by AUTOINCREMENT', () async {
      db.execute('''
        CREATE TABLE Trip (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT
        );
      ''');

      final tables = await repo.getTables();

      expect(tables, ['Trip']);
      expect(tables.any((table) => table.startsWith('sqlite_')), isFalse);
    });

    test('does not exclude tables whose names merely contain sqlite later in the name', () async {
      db.execute('''
        CREATE TABLE UserSqliteTable (
          id INTEGER PRIMARY KEY
        );
      ''');

      final tables = await repo.getTables();

      expect(tables, ['UserSqliteTable']);
    });

    test('does not exclude tables whose names contain project_settings but are not exactly __project_settings', () async {
      db.execute('''
        CREATE TABLE project_settings_archive (
          id INTEGER PRIMARY KEY
        );
      ''');

      final tables = await repo.getTables();

      expect(tables, ['project_settings_archive']);
    });

    test('includes table with underscores in name', () async {
      db.execute('''
        CREATE TABLE sampling_event (
          id INTEGER PRIMARY KEY
        );
      ''');

      final tables = await repo.getTables();

      expect(tables, ['sampling_event']);
    });

    test('includes table with numbers in name', () async {
      db.execute('''
        CREATE TABLE Site2026 (
          id INTEGER PRIMARY KEY
        );
      ''');

      final tables = await repo.getTables();

      expect(tables, ['Site2026']);
    });

    test('does not return views', () async {
      db.execute('''
        CREATE TABLE Trip (
          id INTEGER PRIMARY KEY,
          name TEXT
        );
      ''');

      db.execute('''
        CREATE VIEW TripView AS
        SELECT id, name FROM Trip;
      ''');

      final tables = await repo.getTables();

      expect(tables, ['Trip']);
      expect(tables.contains('TripView'), isFalse);
    });

    test('does not return indexes', () async {
      db.execute('''
        CREATE TABLE Trip (
          id INTEGER PRIMARY KEY,
          name TEXT
        );
      ''');

      db.execute('''
        CREATE INDEX idx_trip_name ON Trip(name);
      ''');

      final tables = await repo.getTables();

      expect(tables, ['Trip']);
      expect(tables.contains('idx_trip_name'), isFalse);
    });

    test('does not return triggers', () async {
      db.execute('''
        CREATE TABLE Trip (
          id INTEGER PRIMARY KEY,
          name TEXT
        );
      ''');

      db.execute('''
        CREATE TABLE TripAudit (
          id INTEGER PRIMARY KEY,
          trip_id INTEGER
        );
      ''');

      db.execute('''
        CREATE TRIGGER trip_insert_audit
        AFTER INSERT ON Trip
        BEGIN
          INSERT INTO TripAudit (trip_id) VALUES (NEW.id);
        END;
      ''');

      final tables = await repo.getTables();

      expect(tables, ['Trip', 'TripAudit']);
      expect(tables.contains('trip_insert_audit'), isFalse);
    });

    test('table ordering is alphabetical regardless of creation order', () async {
      db.execute('CREATE TABLE Zebra (id INTEGER PRIMARY KEY);');
      db.execute('CREATE TABLE Apple (id INTEGER PRIMARY KEY);');
      db.execute('CREATE TABLE Monkey (id INTEGER PRIMARY KEY);');

      final tables = await repo.getTables();

      expect(tables, ['Apple', 'Monkey', 'Zebra']);
    });
  });

  group('SqliteSchemaDiscoveryRepo getColumns', () {
    late Database db;
    late SqliteSchemaDiscoveryRepo repo;

    setUp(() {
      db = sqlite3.openInMemory();
      repo = SqliteSchemaDiscoveryRepo(db);
    });

    tearDown(() {
      db.dispose();
    });

    test('returns empty list for table that does not exist', () async {
      final columns = await repo.getColumns('DoesNotExist');

      expect(columns, isEmpty);
    });

    test('returns columns for a single-column table', () async {
      db.execute('''
        CREATE TABLE Trip (
          id INTEGER PRIMARY KEY
        );
      ''');

      final columns = await repo.getColumns('Trip');

      expect(columns, ['id']);
    });

    test('returns columns in declared order', () async {
      db.execute('''
        CREATE TABLE Trip (
          id INTEGER PRIMARY KEY,
          name TEXT,
          date TEXT,
          notes TEXT
        );
      ''');

      final columns = await repo.getColumns('Trip');

      expect(columns, ['id', 'name', 'date', 'notes']);
    });

    test('returns foreign key column names', () async {
      db.execute('PRAGMA foreign_keys = ON;');

      db.execute('''
        CREATE TABLE Trip (
          id INTEGER PRIMARY KEY
        );
      ''');

      db.execute('''
        CREATE TABLE Sample (
          id INTEGER PRIMARY KEY,
          trip_id INTEGER,
          FOREIGN KEY (trip_id) REFERENCES Trip(id)
        );
      ''');

      final columns = await repo.getColumns('Sample');

      expect(columns, ['id', 'trip_id']);
    });

    test('returns system columns if they physically exist in the table', () async {
      db.execute('''
        CREATE TABLE Specimen (
          id INTEGER PRIMARY KEY,
          tag_id TEXT,
          __row_guid TEXT,
          __created_at TEXT,
          __updated_at TEXT,
          __deleted INTEGER
        );
      ''');

      final columns = await repo.getColumns('Specimen');

      expect(columns, [
        'id',
        'tag_id',
        '__row_guid',
        '__created_at',
        '__updated_at',
        '__deleted',
      ]);
    });

    test('returns columns with underscores and numbers', () async {
      db.execute('''
        CREATE TABLE Specimen (
          id INTEGER PRIMARY KEY,
          tag_code_1 TEXT,
          fish_length_mm REAL
        );
      ''');

      final columns = await repo.getColumns('Specimen');

      expect(columns, ['id', 'tag_code_1', 'fish_length_mm']);
    });

    test('does not return generated column names when using table_info', () async {
      db.execute('''
        CREATE TABLE Measurement (
          id INTEGER PRIMARY KEY,
          length REAL,
          width REAL,
          area REAL GENERATED ALWAYS AS (length * width) VIRTUAL
        );
      ''');

      final columns = await repo.getColumns('Measurement');

      expect(columns, ['id', 'length', 'width']);
      expect(columns.contains('area'), isFalse);
    });

    test('returns columns for table with NOT NULL and DEFAULT constraints', () async {
      db.execute('''
        CREATE TABLE Trip (
          id INTEGER PRIMARY KEY,
          name TEXT NOT NULL,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP
        );
      ''');

      final columns = await repo.getColumns('Trip');

      expect(columns, ['id', 'name', 'created_at']);
    });

    test('returns columns for table with composite primary key', () async {
      db.execute('''
        CREATE TABLE SamplingAssignment (
          trip_id INTEGER,
          site_id INTEGER,
          assigned_to TEXT,
          PRIMARY KEY (trip_id, site_id)
        );
      ''');

      final columns = await repo.getColumns('SamplingAssignment');

      expect(columns, ['trip_id', 'site_id', 'assigned_to']);
    });

    test('returns columns for table name with spaces when passed unquoted', () async {
      db.execute('''
        CREATE TABLE "Trip Data" (
          id INTEGER PRIMARY KEY,
          name TEXT
        );
      ''');

      final columns = await repo.getColumns('Trip Data');

      expect(columns, ['id', 'name']);
    });

    test('returns empty list when table name is passed with literal quote characters', () async {
      db.execute('''
        CREATE TABLE "Trip Data" (
          id INTEGER PRIMARY KEY,
          name TEXT
        );
      ''');

      final columns = await repo.getColumns('"Trip Data"');

      expect(columns, isEmpty);
    });

    test('returns columns for table name with underscore', () async {
      db.execute('''
        CREATE TABLE sampling_event (
          id INTEGER PRIMARY KEY,
          event_name TEXT
        );
      ''');

      final columns = await repo.getColumns('sampling_event');

      expect(columns, ['id', 'event_name']);
    });
  });
}