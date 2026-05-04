import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:crab_cakes/infrastructure/project/sqlite/sqlite_project_database_builder.dart';
import 'package:crab_cakes/infrastructure/providers/column_filter_provider.dart';

void main() {
  group('SqliteProjectDatabaseBuilder createProjectInTemp', () {
    late SqliteProjectDatabaseBuilder builder;
    final createdDbPaths = <String>[];

    setUp(() {
      builder = SqliteProjectDatabaseBuilder();
      createdDbPaths.clear();
    });

    tearDown(() {
      for (final dbPath in createdDbPaths) {
        final file = File(dbPath);

        if (file.existsSync()) {
          try {
            file.deleteSync();
          } catch (_) {
            // Best-effort cleanup.
          }
        }

        final parent = file.parent;
        if (parent.existsSync()) {
          try {
            parent.deleteSync(recursive: true);
          } catch (_) {
            // Best-effort cleanup.
          }
        }
      }
    });

    Database openCreatedDb(String dbPath) {
      return sqlite3.open(dbPath);
    }

    Future<String> createProject(List<String> statements) async {
      final dbPath = await builder.createProjectInTemp(statements);
      createdDbPaths.add(dbPath);
      return dbPath;
    }

    String quoteIdentifier(String identifier) {
      return '"${identifier.replaceAll('"', '""')}"';
    }

    List<String> tableNames(Database db) {
      final rows = db.select('''
        SELECT name
        FROM sqlite_master
        WHERE type = 'table'
        ORDER BY name;
      ''');

      return rows.map((row) => row['name'] as String).toList();
    }

    List<String> userTableNames(Database db) {
      final rows = db.select('''
        SELECT name
        FROM sqlite_master
        WHERE type = 'table'
          AND name NOT LIKE 'sqlite_%'
        ORDER BY name;
      ''');

      return rows
          .map((row) => row['name'] as String)
          .where((name) => !name.startsWith('__'))
          .where((name) => !name.startsWith(kColumnPrefixToHide))
          .toList();
    }

    List<String> indexNames(Database db) {
      final rows = db.select('''
        SELECT name
        FROM sqlite_master
        WHERE type = 'index'
        ORDER BY name;
      ''');

      return rows.map((row) => row['name'] as String).toList();
    }

    List<String> columnNames(Database db, String tableName) {
      final quoted = quoteIdentifier(tableName);

      final rows = db.select('PRAGMA table_info($quoted);');

      return rows.map((row) => row['name'] as String).toList();
    }

    Map<String, Object?> columnInfo(
      Database db,
      String tableName,
      String columnName,
    ) {
      final quoted = quoteIdentifier(tableName);

      final rows = db.select('PRAGMA table_info($quoted);');

      final matches = rows.where((row) => row['name'] == columnName).toList();

      expect(matches.length, 1);

      return matches.first;
    }

    List<Map<String, Object?>> foreignKeys(Database db, String tableName) {
      final quoted = quoteIdentifier(tableName);

      final rows = db.select('PRAGMA foreign_key_list($quoted);');

      return rows.map((row) => Map<String, Object?>.from(row)).toList();
    }

    Map<String, dynamic> readSettingsJson(Database db) {
      final rows = db.select('''
        SELECT settings_json
        FROM __project_settings
        WHERE id = 1;
      ''');

      expect(rows.length, 1);

      return jsonDecode(rows.first['settings_json'] as String)
          as Map<String, dynamic>;
    }

    String readRawSettingsJson(Database db) {
      final rows = db.select('''
        SELECT settings_json
        FROM __project_settings
        WHERE id = 1;
      ''');

      expect(rows.length, 1);

      return rows.first['settings_json'] as String;
    }

    // -------------------------------------------------------------------------
    // Basic creation behavior
    // -------------------------------------------------------------------------

    test('creates sqlite database file for a single table schema', () async {
      final dbPath = await createProject([
        '''
        CREATE TABLE Trip (
          id INTEGER PRIMARY KEY,
          name TEXT
        );
        ''',
      ]);

      expect(File(dbPath).existsSync(), isTrue);

      final db = openCreatedDb(dbPath);
      try {
        expect(tableNames(db), contains('Trip'));
      } finally {
        db.dispose();
      }
    });

    test('created database file has non-zero size', () async {
      final dbPath = await createProject([
        '''
        CREATE TABLE Trip (
          id INTEGER PRIMARY KEY,
          name TEXT
        );
        ''',
      ]);

      final file = File(dbPath);

      expect(file.existsSync(), isTrue);
      expect(file.lengthSync(), greaterThan(0));
    });

    test('created database can be reopened after builder disposes connection', () async {
      final dbPath = await createProject([
        '''
        CREATE TABLE Trip (
          id INTEGER PRIMARY KEY,
          name TEXT
        );
        ''',
      ]);

      final firstOpen = openCreatedDb(dbPath);
      firstOpen.dispose();

      final secondOpen = openCreatedDb(dbPath);
      try {
        expect(secondOpen.select('SELECT 1 AS value;').first['value'], 1);
      } finally {
        secondOpen.dispose();
      }
    });

    test('created database can accept inserts into user table', () async {
      final dbPath = await createProject([
        '''
        CREATE TABLE Trip (
          id INTEGER PRIMARY KEY,
          name TEXT
        );
        ''',
      ]);

      final db = openCreatedDb(dbPath);
      try {
        db.execute("INSERT INTO Trip (id, name) VALUES (1, 'Colorado River');");

        final rows = db.select('SELECT id, name FROM Trip;');

        expect(rows.length, 1);
        expect(rows.first['id'], 1);
        expect(rows.first['name'], 'Colorado River');
      } finally {
        db.dispose();
      }
    });

    test('supports table name with spaces', () async {
      final dbPath = await createProject([
        '''
        CREATE TABLE "Trip Data" (
          id INTEGER PRIMARY KEY,
          name TEXT
        );
        ''',
      ]);

      final db = openCreatedDb(dbPath);
      try {
        expect(tableNames(db), contains('Trip Data'));
        expect(columnNames(db, 'Trip Data'), contains('name'));
        expect(
          columnNames(db, 'Trip Data'),
          contains('${kColumnPrefixToHide}row_guid'),
        );
      } finally {
        db.dispose();
      }
    });

    test('supports table name with embedded double quote', () async {
      final dbPath = await createProject([
        '''
        CREATE TABLE "Trip ""Data""" (
          id INTEGER PRIMARY KEY,
          name TEXT
        );
        ''',
      ]);

      final db = openCreatedDb(dbPath);
      try {
        expect(tableNames(db), contains('Trip "Data"'));
        expect(columnNames(db, 'Trip "Data"'), contains('name'));
        expect(
          columnNames(db, 'Trip "Data"'),
          contains('${kColumnPrefixToHide}row_guid'),
        );
      } finally {
        db.dispose();
      }
    });

    test('supports column names with spaces', () async {
      final dbPath = await createProject([
        '''
        CREATE TABLE Trip (
          id INTEGER PRIMARY KEY,
          "trip name" TEXT
        );
        ''',
      ]);

      final db = openCreatedDb(dbPath);
      try {
        expect(columnNames(db, 'Trip'), contains('trip name'));
      } finally {
        db.dispose();
      }
    });

    // -------------------------------------------------------------------------
    // System settings table behavior
    // -------------------------------------------------------------------------

    test('created database contains __project_settings table', () async {
      final dbPath = await createProject([
        '''
        CREATE TABLE Trip (
          id INTEGER PRIMARY KEY,
          name TEXT
        );
        ''',
      ]);

      final db = openCreatedDb(dbPath);
      try {
        expect(tableNames(db), contains('__project_settings'));
      } finally {
        db.dispose();
      }
    });

    test('created settings table contains row id 1', () async {
      final dbPath = await createProject([
        '''
        CREATE TABLE Trip (
          id INTEGER PRIMARY KEY,
          name TEXT
        );
        ''',
      ]);

      final db = openCreatedDb(dbPath);
      try {
        final rows = db.select('''
          SELECT id, settings_json
          FROM __project_settings
          WHERE id = 1;
        ''');

        expect(rows.length, 1);
        expect(rows.first['id'], 1);
        expect(rows.first['settings_json'], isA<String>());
      } finally {
        db.dispose();
      }
    });

    test('settings_json is valid JSON', () async {
      final dbPath = await createProject([
        '''
        CREATE TABLE Trip (
          id INTEGER PRIMARY KEY,
          name TEXT
        );
        ''',
      ]);

      final db = openCreatedDb(dbPath);
      try {
        final raw = readRawSettingsJson(db);

        expect(() => jsonDecode(raw), returnsNormally);
      } finally {
        db.dispose();
      }
    });

    test('settings_json contains initial project metadata', () async {
      final statements = [
        '''
        CREATE TABLE Trip (
          id INTEGER PRIMARY KEY,
          name TEXT
        );
        ''',
      ];

      final dbPath = await createProject(statements);

      final db = openCreatedDb(dbPath);
      try {
        final settingsJson = readSettingsJson(db);

        expect(settingsJson['formatVersion'], 1);
        expect(settingsJson['projectGuid'], isA<String>());
        expect((settingsJson['projectGuid'] as String).isNotEmpty, isTrue);
        expect(settingsJson['schemaHash'], isA<String>());
        expect((settingsJson['schemaHash'] as String).length, 64);
        expect(settingsJson['syncVersion'], 1);
        expect(settingsJson['schemaSql'], statements);
        expect(settingsJson['settings'], <String, dynamic>{});
        expect(settingsJson['integrity'], <String, dynamic>{});
      } finally {
        db.dispose();
      }
    });

    test('projectGuid is different for separate project databases', () async {
      final firstPath = await createProject([
        '''
        CREATE TABLE Trip (
          id INTEGER PRIMARY KEY
        );
        ''',
      ]);

      final secondPath = await createProject([
        '''
        CREATE TABLE Trip (
          id INTEGER PRIMARY KEY
        );
        ''',
      ]);

      final firstDb = openCreatedDb(firstPath);
      final secondDb = openCreatedDb(secondPath);

      try {
        final firstSettings = readSettingsJson(firstDb);
        final secondSettings = readSettingsJson(secondDb);

        expect(firstSettings['projectGuid'], isNot(secondSettings['projectGuid']));
      } finally {
        firstDb.dispose();
        secondDb.dispose();
      }
    });

    test('schemaHash is same for separate project databases with same schema', () async {
      final statements = [
        '''
        CREATE TABLE Trip (
          id INTEGER PRIMARY KEY
        );
        ''',
      ];

      final firstPath = await createProject(statements);
      final secondPath = await createProject(statements);

      final firstDb = openCreatedDb(firstPath);
      final secondDb = openCreatedDb(secondPath);

      try {
        final firstSettings = readSettingsJson(firstDb);
        final secondSettings = readSettingsJson(secondDb);

        expect(firstSettings['schemaHash'], secondSettings['schemaHash']);
      } finally {
        firstDb.dispose();
        secondDb.dispose();
      }
    });

    test('schemaHash differs for separate project databases with different schemas', () async {
      final firstPath = await createProject([
        '''
        CREATE TABLE Trip (
          id INTEGER PRIMARY KEY
        );
        ''',
      ]);

      final secondPath = await createProject([
        '''
        CREATE TABLE Trip (
          id INTEGER PRIMARY KEY,
          name TEXT
        );
        ''',
      ]);

      final firstDb = openCreatedDb(firstPath);
      final secondDb = openCreatedDb(secondPath);

      try {
        final firstSettings = readSettingsJson(firstDb);
        final secondSettings = readSettingsJson(secondDb);

        expect(firstSettings['schemaHash'], isNot(secondSettings['schemaHash']));
      } finally {
        firstDb.dispose();
        secondDb.dispose();
      }
    });

    test('schemaSql stores statements exactly as provided', () async {
      final statements = [
        '''
        CREATE TABLE Trip (
          id INTEGER PRIMARY KEY,
          name TEXT
        );
        ''',
        '''
        CREATE TABLE Sample (
          id INTEGER PRIMARY KEY
        );
        ''',
      ];

      final dbPath = await createProject(statements);

      final db = openCreatedDb(dbPath);
      try {
        final settingsJson = readSettingsJson(db);

        expect(settingsJson['schemaSql'], statements);
      } finally {
        db.dispose();
      }
    });

    // -------------------------------------------------------------------------
    // Internal metadata columns
    // -------------------------------------------------------------------------

    test('adds internal metadata columns to user table', () async {
      final dbPath = await createProject([
        '''
        CREATE TABLE Trip (
          id INTEGER PRIMARY KEY,
          name TEXT
        );
        ''',
      ]);

      final db = openCreatedDb(dbPath);
      try {
        final columns = columnNames(db, 'Trip');

        expect(columns, contains('${kColumnPrefixToHide}created_at_time'));
        expect(columns, contains('${kColumnPrefixToHide}modified_in_program'));
        expect(columns, contains('${kColumnPrefixToHide}row_guid'));
        expect(columns, contains('${kColumnPrefixToHide}created_at'));
        expect(columns, contains('${kColumnPrefixToHide}updated_at'));
        expect(columns, contains('${kColumnPrefixToHide}deleted_at'));
      } finally {
        db.dispose();
      }
    });

    test('does not add internal metadata columns to __project_settings table', () async {
      final dbPath = await createProject([
        '''
        CREATE TABLE Trip (
          id INTEGER PRIMARY KEY,
          name TEXT
        );
        ''',
      ]);

      final db = openCreatedDb(dbPath);
      try {
        final columns = columnNames(db, '__project_settings');

        expect(columns, ['id', 'settings_json']);
      } finally {
        db.dispose();
      }
    });

    test('internal created_at_time column has default datetime expression', () async {
      final dbPath = await createProject([
        '''
        CREATE TABLE Trip (
          id INTEGER PRIMARY KEY,
          name TEXT
        );
        ''',
      ]);

      final db = openCreatedDb(dbPath);
      try {
        final info = columnInfo(
          db,
          'Trip',
          '${kColumnPrefixToHide}created_at_time',
        );

        expect(info['dflt_value'], "datetime('now', 'localtime')");
      } finally {
        db.dispose();
      }
    });

    test('internal modified_in_program column has default zero', () async {
      final dbPath = await createProject([
        '''
        CREATE TABLE Trip (
          id INTEGER PRIMARY KEY,
          name TEXT
        );
        ''',
      ]);

      final db = openCreatedDb(dbPath);
      try {
        final info = columnInfo(
          db,
          'Trip',
          '${kColumnPrefixToHide}modified_in_program',
        );

        expect(info['dflt_value'], '0');
      } finally {
        db.dispose();
      }
    });

    test('internal row_guid column defaults to null', () async {
      final dbPath = await createProject([
        '''
        CREATE TABLE Trip (
          id INTEGER PRIMARY KEY,
          name TEXT
        );
        ''',
      ]);

      final db = openCreatedDb(dbPath);
      try {
        final info = columnInfo(db, 'Trip', '${kColumnPrefixToHide}row_guid');

        expect(info['dflt_value'], isNull);
      } finally {
        db.dispose();
      }
    });

    test('inserted rows receive default modified_in_program value', () async {
      final dbPath = await createProject([
        '''
        CREATE TABLE Trip (
          id INTEGER PRIMARY KEY,
          name TEXT
        );
        ''',
      ]);

      final db = openCreatedDb(dbPath);
      try {
        db.execute("INSERT INTO Trip (id, name) VALUES (1, 'Trip A');");

        final rows = db.select('''
          SELECT
            ${kColumnPrefixToHide}created_at_time AS created_at_time,
            ${kColumnPrefixToHide}modified_in_program AS modified_in_program
          FROM Trip
          WHERE id = 1;
        ''');

        expect(rows.length, 1);

        // Current builder behavior: this column exists, but may be null unless
        // another layer explicitly writes it.
        expect(rows.first.containsKey('created_at_time'), isTrue);

        expect(rows.first['modified_in_program'], 0);
      } finally {
        db.dispose();
      }
    });

    test('does not duplicate internal columns if user already defined some of them', () async {
      final dbPath = await createProject([
        '''
        CREATE TABLE Trip (
          id INTEGER PRIMARY KEY,
          name TEXT,
          ${kColumnPrefixToHide}row_guid TEXT
        );
        ''',
      ]);

      final db = openCreatedDb(dbPath);
      try {
        final columns = columnNames(db, 'Trip');

        expect(
          columns.where((column) => column == '${kColumnPrefixToHide}row_guid'),
          hasLength(1),
        );
      } finally {
        db.dispose();
      }
    });

    test('does not duplicate internal columns across multiple schema statements', () async {
      final dbPath = await createProject([
        '''
        CREATE TABLE Trip (
          id INTEGER PRIMARY KEY,
          name TEXT
        );
        ''',
        '''
        CREATE INDEX idx_trip_name
        ON Trip(name);
        ''',
      ]);

      final db = openCreatedDb(dbPath);
      try {
        final columns = columnNames(db, 'Trip');

        expect(
          columns.where((column) => column == '${kColumnPrefixToHide}row_guid'),
          hasLength(1),
        );

        expect(
          columns.where((column) => column == '${kColumnPrefixToHide}created_at'),
          hasLength(1),
        );
      } finally {
        db.dispose();
      }
    });

    test('adds internal metadata columns to every user table', () async {
      final dbPath = await createProject([
        '''
        CREATE TABLE Trip (
          id INTEGER PRIMARY KEY,
          name TEXT
        );
        ''',
        '''
        CREATE TABLE Sample (
          id INTEGER PRIMARY KEY,
          trip_id INTEGER,
          FOREIGN KEY (trip_id) REFERENCES Trip(id)
        );
        ''',
      ]);

      final db = openCreatedDb(dbPath);
      try {
        final tripColumns = columnNames(db, 'Trip');
        final sampleColumns = columnNames(db, 'Sample');

        expect(tripColumns, contains('${kColumnPrefixToHide}row_guid'));
        expect(sampleColumns, contains('${kColumnPrefixToHide}row_guid'));
      } finally {
        db.dispose();
      }
    });

    test('does not add internal metadata columns to table whose name starts with hidden prefix', () async {
      final hiddenTableName = '${kColumnPrefixToHide}HiddenTable';

      final dbPath = await createProject([
        '''
        CREATE TABLE $hiddenTableName (
          id INTEGER PRIMARY KEY
        );
        ''',
        '''
        CREATE TABLE Trip (
          id INTEGER PRIMARY KEY
        );
        ''',
      ]);

      final db = openCreatedDb(dbPath);
      try {
        final columns = columnNames(db, hiddenTableName);

        expect(columns, ['id']);
      } finally {
        db.dispose();
      }
    });

    // -------------------------------------------------------------------------
    // Row GUID unique index
    // -------------------------------------------------------------------------

    test('creates unique row guid index for user table', () async {
      final dbPath = await createProject([
        '''
        CREATE TABLE Trip (
          id INTEGER PRIMARY KEY,
          name TEXT
        );
        ''',
      ]);

      final db = openCreatedDb(dbPath);
      try {
        final indexes = indexNames(db);

        expect(
          indexes,
          contains('Trip_${kColumnPrefixToHide}row_guid_unique_idx'),
        );
      } finally {
        db.dispose();
      }
    });

    test('creates row guid unique index for each user table', () async {
      final dbPath = await createProject([
        '''
        CREATE TABLE Trip (
          id INTEGER PRIMARY KEY
        );
        ''',
        '''
        CREATE TABLE Sample (
          id INTEGER PRIMARY KEY
        );
        ''',
      ]);

      final db = openCreatedDb(dbPath);
      try {
        final indexes = indexNames(db);

        expect(
          indexes,
          contains('Trip_${kColumnPrefixToHide}row_guid_unique_idx'),
        );

        expect(
          indexes,
          contains('Sample_${kColumnPrefixToHide}row_guid_unique_idx'),
        );
      } finally {
        db.dispose();
      }
    });

    test('row guid unique index enforces uniqueness when row guid is not null', () async {
      final dbPath = await createProject([
        '''
        CREATE TABLE Trip (
          id INTEGER PRIMARY KEY,
          name TEXT
        );
        ''',
      ]);

      final db = openCreatedDb(dbPath);
      try {
        db.execute('''
          INSERT INTO Trip (id, name, ${kColumnPrefixToHide}row_guid)
          VALUES (1, 'A', 'same-guid');
        ''');

        expect(
          () => db.execute('''
            INSERT INTO Trip (id, name, ${kColumnPrefixToHide}row_guid)
            VALUES (2, 'B', 'same-guid');
          '''),
          throwsA(isA<SqliteException>()),
        );
      } finally {
        db.dispose();
      }
    });

    test('row guid unique index allows multiple null row guid values', () async {
      final dbPath = await createProject([
        '''
        CREATE TABLE Trip (
          id INTEGER PRIMARY KEY,
          name TEXT
        );
        ''',
      ]);

      final db = openCreatedDb(dbPath);
      try {
        db.execute("INSERT INTO Trip (id, name) VALUES (1, 'A');");
        db.execute("INSERT INTO Trip (id, name) VALUES (2, 'B');");

        final rows = db.select('SELECT COUNT(*) AS count FROM Trip;');

        expect(rows.first['count'], 2);
      } finally {
        db.dispose();
      }
    });

    // -------------------------------------------------------------------------
    // Relationships and multiple table schemas
    // -------------------------------------------------------------------------

    test('supports multiple user tables', () async {
      final dbPath = await createProject([
        '''
        CREATE TABLE Trip (
          id INTEGER PRIMARY KEY,
          name TEXT
        );
        ''',
        '''
        CREATE TABLE Sample (
          id INTEGER PRIMARY KEY,
          trip_id INTEGER,
          FOREIGN KEY (trip_id) REFERENCES Trip(id)
        );
        ''',
      ]);

      final db = openCreatedDb(dbPath);
      try {
        final tables = tableNames(db);

        expect(tables, contains('Trip'));
        expect(tables, contains('Sample'));
        expect(tables, contains('__project_settings'));
      } finally {
        db.dispose();
      }
    });

    test('preserves foreign key relationships', () async {
      final dbPath = await createProject([
        '''
        CREATE TABLE Trip (
          id INTEGER PRIMARY KEY
        );
        ''',
        '''
        CREATE TABLE Sample (
          id INTEGER PRIMARY KEY,
          trip_id INTEGER,
          FOREIGN KEY (trip_id) REFERENCES Trip(id)
        );
        ''',
      ]);

      final db = openCreatedDb(dbPath);
      try {
        final fks = foreignKeys(db, 'Sample');

        expect(fks.length, 1);
        expect(fks.first['from'], 'trip_id');
        expect(fks.first['table'], 'Trip');
        expect(fks.first['to'], 'id');
      } finally {
        db.dispose();
      }
    });

    test('supports three table chain schema', () async {
      final dbPath = await createProject([
        '''
        CREATE TABLE Trip (
          id INTEGER PRIMARY KEY
        );
        ''',
        '''
        CREATE TABLE Sample (
          id INTEGER PRIMARY KEY,
          trip_id INTEGER,
          FOREIGN KEY (trip_id) REFERENCES Trip(id)
        );
        ''',
        '''
        CREATE TABLE Specimen (
          id INTEGER PRIMARY KEY,
          sample_id INTEGER,
          tag_id TEXT,
          FOREIGN KEY (sample_id) REFERENCES Sample(id)
        );
        ''',
      ]);

      final db = openCreatedDb(dbPath);
      try {
        expect(userTableNames(db), ['Sample', 'Specimen', 'Trip']);
        expect(foreignKeys(db, 'Specimen').first['table'], 'Sample');
      } finally {
        db.dispose();
      }
    });

    test('foreign keys can be enforced on reopened connection when enabled', () async {
      final dbPath = await createProject([
        '''
        CREATE TABLE Parent (
          id INTEGER PRIMARY KEY
        );
        ''',
        '''
        CREATE TABLE Child (
          id INTEGER PRIMARY KEY,
          parent_id INTEGER,
          FOREIGN KEY (parent_id) REFERENCES Parent(id)
        );
        ''',
      ]);

      final db = openCreatedDb(dbPath);
      try {
        db.execute('PRAGMA foreign_keys = ON;');

        expect(
          () => db.execute('''
            INSERT INTO Child (id, parent_id)
            VALUES (1, 999);
          '''),
          throwsA(isA<SqliteException>()),
        );
      } finally {
        db.dispose();
      }
    });

    test('allows valid foreign key insert when parent exists', () async {
      final dbPath = await createProject([
        '''
        CREATE TABLE Parent (
          id INTEGER PRIMARY KEY
        );
        ''',
        '''
        CREATE TABLE Child (
          id INTEGER PRIMARY KEY,
          parent_id INTEGER,
          FOREIGN KEY (parent_id) REFERENCES Parent(id)
        );
        ''',
      ]);

      final db = openCreatedDb(dbPath);
      try {
        db.execute('PRAGMA foreign_keys = ON;');

        db.execute('INSERT INTO Parent (id) VALUES (1);');
        db.execute('INSERT INTO Child (id, parent_id) VALUES (1, 1);');

        final rows = db.select('SELECT COUNT(*) AS count FROM Child;');

        expect(rows.first['count'], 1);
      } finally {
        db.dispose();
      }
    });

    // -------------------------------------------------------------------------
    // Error and validation behavior
    // -------------------------------------------------------------------------

    test('throws when no statements are provided', () async {
      await expectLater(
        () => builder.createProjectInTemp([]),
        throwsException,
      );
    });

    test('throws SqliteException when SQL statement is invalid', () async {
      await expectLater(
        () => builder.createProjectInTemp([
          '''
          CREATE TABLE Trip (
            id INTEGER PRIMARY KEY,
            name TEXT
          );
          ''',
          'THIS IS NOT VALID SQL;',
        ]),
        throwsA(isA<SqliteException>()),
      );
    });

    test('throws when statement does not change schema', () async {
      await expectLater(
        () => builder.createProjectInTemp([
          '''
          CREATE TABLE Trip (
            id INTEGER PRIMARY KEY
          );
          ''',
          'PRAGMA user_version = 1;',
        ]),
        throwsException,
      );
    });

    test('throws when statement creates a view because validation rejects illegal objects', () async {
      await expectLater(
        () => builder.createProjectInTemp([
          '''
          CREATE TABLE Trip (
            id INTEGER PRIMARY KEY
          );
          ''',
          '''
          CREATE VIEW TripView AS
          SELECT id FROM Trip;
          ''',
        ]),
        throwsException,
      );
    });

    test('throws when statement creates a trigger because validation rejects illegal objects', () async {
      await expectLater(
        () => builder.createProjectInTemp([
          '''
          CREATE TABLE Trip (
            id INTEGER PRIMARY KEY,
            name TEXT
          );
          ''',
          '''
          CREATE TRIGGER TripInsertTrigger
          AFTER INSERT ON Trip
          BEGIN
            UPDATE Trip SET name = NEW.name WHERE id = NEW.id;
          END;
          ''',
        ]),
        throwsException,
      );
    });

    test('throws when duplicate table is created', () async {
      await expectLater(
        () => builder.createProjectInTemp([
          '''
          CREATE TABLE Trip (
            id INTEGER PRIMARY KEY
          );
          ''',
          '''
          CREATE TABLE Trip (
            id INTEGER PRIMARY KEY
          );
          ''',
        ]),
        throwsA(isA<SqliteException>()),
      );
    });

    test('throws when table creation statement is syntactically incomplete', () async {
      await expectLater(
        () => builder.createProjectInTemp([
          '''
          CREATE TABLE Trip (
            id INTEGER PRIMARY KEY
          ''',
        ]),
        throwsA(isA<SqliteException>()),
      );
    });

    test('allows indexes because validation accepts tables and indexes', () async {
      final dbPath = await createProject([
        '''
        CREATE TABLE Trip (
          id INTEGER PRIMARY KEY,
          name TEXT
        );
        ''',
        '''
        CREATE INDEX idx_trip_name
        ON Trip(name);
        ''',
      ]);

      final db = openCreatedDb(dbPath);
      try {
        expect(indexNames(db), contains('idx_trip_name'));
      } finally {
        db.dispose();
      }
    });

    test('allows unique indexes because validation accepts indexes', () async {
      final dbPath = await createProject([
        '''
        CREATE TABLE Trip (
          id INTEGER PRIMARY KEY,
          name TEXT
        );
        ''',
        '''
        CREATE UNIQUE INDEX idx_trip_name_unique
        ON Trip(name);
        ''',
      ]);

      final db = openCreatedDb(dbPath);
      try {
        expect(indexNames(db), contains('idx_trip_name_unique'));
      } finally {
        db.dispose();
      }
    });

    // -------------------------------------------------------------------------
    // validateDb direct tests
    // -------------------------------------------------------------------------

    test('validateDb returns false for database with no user tables', () {
      final db = sqlite3.openInMemory();

      try {
        expect(builder.validateDb(db), isFalse);
      } finally {
        db.dispose();
      }
    });

    test('validateDb returns false for database with only internal settings table', () {
      final db = sqlite3.openInMemory();

      try {
        db.execute('''
          CREATE TABLE __project_settings (
            id INTEGER PRIMARY KEY,
            settings_json TEXT NOT NULL
          );
        ''');

        expect(builder.validateDb(db), isFalse);
      } finally {
        db.dispose();
      }
    });

    test('validateDb returns false for database with only hidden-prefix table', () {
      final db = sqlite3.openInMemory();

      try {
        db.execute('''
          CREATE TABLE ${kColumnPrefixToHide}Hidden (
            id INTEGER PRIMARY KEY
          );
        ''');

        expect(builder.validateDb(db), isFalse);
      } finally {
        db.dispose();
      }
    });

    test('validateDb returns true for database with one user table', () {
      final db = sqlite3.openInMemory();

      try {
        db.execute('''
          CREATE TABLE Trip (
            id INTEGER PRIMARY KEY
          );
        ''');

        expect(builder.validateDb(db), isTrue);
      } finally {
        db.dispose();
      }
    });

    test('validateDb returns true for database with user table and index', () {
      final db = sqlite3.openInMemory();

      try {
        db.execute('''
          CREATE TABLE Trip (
            id INTEGER PRIMARY KEY,
            name TEXT
          );
        ''');

        db.execute('CREATE INDEX idx_trip_name ON Trip(name);');

        expect(builder.validateDb(db), isTrue);
      } finally {
        db.dispose();
      }
    });

    test('validateDb returns false when database contains a view', () {
      final db = sqlite3.openInMemory();

      try {
        db.execute('''
          CREATE TABLE Trip (
            id INTEGER PRIMARY KEY
          );
        ''');

        db.execute('''
          CREATE VIEW TripView AS
          SELECT id FROM Trip;
        ''');

        expect(builder.validateDb(db), isFalse);
      } finally {
        db.dispose();
      }
    });

    test('validateDb returns false when database contains a trigger', () {
      final db = sqlite3.openInMemory();

      try {
        db.execute('''
          CREATE TABLE Trip (
            id INTEGER PRIMARY KEY,
            name TEXT
          );
        ''');

        db.execute('''
          CREATE TRIGGER TripInsertTrigger
          AFTER INSERT ON Trip
          BEGIN
            UPDATE Trip SET name = NEW.name WHERE id = NEW.id;
          END;
        ''');

        expect(builder.validateDb(db), isFalse);
      } finally {
        db.dispose();
      }
    });

    // -------------------------------------------------------------------------
    // Security state / schema version helpers
    // -------------------------------------------------------------------------

    test('getSecurityState returns expected keys', () {
      final db = sqlite3.openInMemory();

      try {
        final state = builder.getSecurityState(db);

        expect(state.containsKey('foreign_keys'), isTrue);
        expect(state.containsKey('trusted_schema'), isTrue);
        expect(state.containsKey('writable_schema'), isTrue);
      } finally {
        db.dispose();
      }
    });

    test('getSecurityState reflects foreign_keys pragma', () {
      final db = sqlite3.openInMemory();

      try {
        db.execute('PRAGMA foreign_keys = ON;');

        final state = builder.getSecurityState(db);

        expect(state['foreign_keys'], 1);
      } finally {
        db.dispose();
      }
    });

    test('getSecurityState reflects writable_schema pragma', () {
      final db = sqlite3.openInMemory();

      try {
        db.execute('PRAGMA writable_schema = ON;');

        final state = builder.getSecurityState(db);

        expect(state['writable_schema'], 1);
      } finally {
        db.dispose();
      }
    });

    test('getSchemaVersion increases after schema change', () {
      final db = sqlite3.openInMemory();

      try {
        final before = builder.getSchemaVersion(db);

        db.execute('CREATE TABLE Trip (id INTEGER PRIMARY KEY);');

        final after = builder.getSchemaVersion(db);

        expect(after, greaterThan(before));
      } finally {
        db.dispose();
      }
    });

    test('getSchemaVersion does not change after data insert', () {
      final db = sqlite3.openInMemory();

      try {
        db.execute('CREATE TABLE Trip (id INTEGER PRIMARY KEY);');

        final before = builder.getSchemaVersion(db);

        db.execute('INSERT INTO Trip (id) VALUES (1);');

        final after = builder.getSchemaVersion(db);

        expect(after, before);
      } finally {
        db.dispose();
      }
    });

    // -------------------------------------------------------------------------
    // computeSchemaHash direct tests
    // -------------------------------------------------------------------------

    test('computeSchemaHash returns 64 character sha256 hex string', () {
      final db = sqlite3.openInMemory();

      try {
        db.execute('''
          CREATE TABLE Trip (
            id INTEGER PRIMARY KEY,
            name TEXT
          );
        ''');

        final hash = builder.computeSchemaHash(db);

        expect(hash.length, 64);
        expect(RegExp(r'^[0-9a-f]{64}$').hasMatch(hash), isTrue);
      } finally {
        db.dispose();
      }
    });

    test('computeSchemaHash ignores internal columns', () {
      final dbWithoutInternal = sqlite3.openInMemory();
      final dbWithInternal = sqlite3.openInMemory();

      try {
        dbWithoutInternal.execute('''
          CREATE TABLE Trip (
            id INTEGER PRIMARY KEY,
            name TEXT
          );
        ''');

        dbWithInternal.execute('''
          CREATE TABLE Trip (
            id INTEGER PRIMARY KEY,
            name TEXT,
            ${kColumnPrefixToHide}row_guid TEXT,
            ${kColumnPrefixToHide}created_at TEXT,
            ${kColumnPrefixToHide}updated_at TEXT
          );
        ''');

        final firstHash = builder.computeSchemaHash(dbWithoutInternal);
        final secondHash = builder.computeSchemaHash(dbWithInternal);

        expect(firstHash, secondHash);
      } finally {
        dbWithoutInternal.dispose();
        dbWithInternal.dispose();
      }
    });

    test('computeSchemaHash ignores internal tables', () {
      final firstDb = sqlite3.openInMemory();
      final secondDb = sqlite3.openInMemory();

      try {
        firstDb.execute('''
          CREATE TABLE Trip (
            id INTEGER PRIMARY KEY
          );
        ''');

        secondDb.execute('''
          CREATE TABLE Trip (
            id INTEGER PRIMARY KEY
          );
        ''');

        secondDb.execute('''
          CREATE TABLE __project_settings (
            id INTEGER PRIMARY KEY,
            settings_json TEXT NOT NULL
          );
        ''');

        final firstHash = builder.computeSchemaHash(firstDb);
        final secondHash = builder.computeSchemaHash(secondDb);

        expect(firstHash, secondHash);
      } finally {
        firstDb.dispose();
        secondDb.dispose();
      }
    });

    test('computeSchemaHash changes when user column is added', () {
      final firstDb = sqlite3.openInMemory();
      final secondDb = sqlite3.openInMemory();

      try {
        firstDb.execute('''
          CREATE TABLE Trip (
            id INTEGER PRIMARY KEY,
            name TEXT
          );
        ''');

        secondDb.execute('''
          CREATE TABLE Trip (
            id INTEGER PRIMARY KEY,
            name TEXT,
            notes TEXT
          );
        ''');

        final firstHash = builder.computeSchemaHash(firstDb);
        final secondHash = builder.computeSchemaHash(secondDb);

        expect(firstHash, isNot(secondHash));
      } finally {
        firstDb.dispose();
        secondDb.dispose();
      }
    });

    test('computeSchemaHash changes when column type changes', () {
      final firstDb = sqlite3.openInMemory();
      final secondDb = sqlite3.openInMemory();

      try {
        firstDb.execute('CREATE TABLE Trip (id INTEGER PRIMARY KEY, value TEXT);');
        secondDb.execute('CREATE TABLE Trip (id INTEGER PRIMARY KEY, value INTEGER);');

        final firstHash = builder.computeSchemaHash(firstDb);
        final secondHash = builder.computeSchemaHash(secondDb);

        expect(firstHash, isNot(secondHash));
      } finally {
        firstDb.dispose();
        secondDb.dispose();
      }
    });

    test('computeSchemaHash normalizes column type casing', () {
      final firstDb = sqlite3.openInMemory();
      final secondDb = sqlite3.openInMemory();

      try {
        firstDb.execute('CREATE TABLE Trip (id INTEGER PRIMARY KEY, name text);');
        secondDb.execute('CREATE TABLE Trip (id INTEGER PRIMARY KEY, name TEXT);');

        final firstHash = builder.computeSchemaHash(firstDb);
        final secondHash = builder.computeSchemaHash(secondDb);

        expect(firstHash, secondHash);
      } finally {
        firstDb.dispose();
        secondDb.dispose();
      }
    });

    test('computeSchemaHash changes when NOT NULL constraint changes', () {
      final firstDb = sqlite3.openInMemory();
      final secondDb = sqlite3.openInMemory();

      try {
        firstDb.execute('CREATE TABLE Trip (id INTEGER PRIMARY KEY, name TEXT);');
        secondDb.execute('CREATE TABLE Trip (id INTEGER PRIMARY KEY, name TEXT NOT NULL);');

        final firstHash = builder.computeSchemaHash(firstDb);
        final secondHash = builder.computeSchemaHash(secondDb);

        expect(firstHash, isNot(secondHash));
      } finally {
        firstDb.dispose();
        secondDb.dispose();
      }
    });

    test('computeSchemaHash changes when default value changes', () {
      final firstDb = sqlite3.openInMemory();
      final secondDb = sqlite3.openInMemory();

      try {
        firstDb.execute('CREATE TABLE Trip (id INTEGER PRIMARY KEY, status TEXT DEFAULT "A");');
        secondDb.execute('CREATE TABLE Trip (id INTEGER PRIMARY KEY, status TEXT DEFAULT "B");');

        final firstHash = builder.computeSchemaHash(firstDb);
        final secondHash = builder.computeSchemaHash(secondDb);

        expect(firstHash, isNot(secondHash));
      } finally {
        firstDb.dispose();
        secondDb.dispose();
      }
    });

    test('computeSchemaHash changes when primary key changes', () {
      final firstDb = sqlite3.openInMemory();
      final secondDb = sqlite3.openInMemory();

      try {
        firstDb.execute('CREATE TABLE Trip (id INTEGER PRIMARY KEY, name TEXT);');
        secondDb.execute('CREATE TABLE Trip (id INTEGER, name TEXT PRIMARY KEY);');

        final firstHash = builder.computeSchemaHash(firstDb);
        final secondHash = builder.computeSchemaHash(secondDb);

        expect(firstHash, isNot(secondHash));
      } finally {
        firstDb.dispose();
        secondDb.dispose();
      }
    });

    test('computeSchemaHash changes when table name changes', () {
      final firstDb = sqlite3.openInMemory();
      final secondDb = sqlite3.openInMemory();

      try {
        firstDb.execute('CREATE TABLE Trip (id INTEGER PRIMARY KEY);');
        secondDb.execute('CREATE TABLE Sample (id INTEGER PRIMARY KEY);');

        final firstHash = builder.computeSchemaHash(firstDb);
        final secondHash = builder.computeSchemaHash(secondDb);

        expect(firstHash, isNot(secondHash));
      } finally {
        firstDb.dispose();
        secondDb.dispose();
      }
    });

    test('computeSchemaHash changes when foreign key changes', () {
      final firstDb = sqlite3.openInMemory();
      final secondDb = sqlite3.openInMemory();

      try {
        firstDb.execute('''
          CREATE TABLE Trip (
            id INTEGER PRIMARY KEY
          );
        ''');

        firstDb.execute('''
          CREATE TABLE Sample (
            id INTEGER PRIMARY KEY,
            trip_id INTEGER,
            FOREIGN KEY (trip_id) REFERENCES Trip(id)
          );
        ''');

        secondDb.execute('''
          CREATE TABLE Trip (
            id INTEGER PRIMARY KEY
          );
        ''');

        secondDb.execute('''
          CREATE TABLE Sample (
            id INTEGER PRIMARY KEY,
            trip_code INTEGER,
            FOREIGN KEY (trip_code) REFERENCES Trip(id)
          );
        ''');

        final firstHash = builder.computeSchemaHash(firstDb);
        final secondHash = builder.computeSchemaHash(secondDb);

        expect(firstHash, isNot(secondHash));
      } finally {
        firstDb.dispose();
        secondDb.dispose();
      }
    });

    test('computeSchemaHash changes when foreign key on delete action changes', () {
      final firstDb = sqlite3.openInMemory();
      final secondDb = sqlite3.openInMemory();

      try {
        firstDb.execute('CREATE TABLE Trip (id INTEGER PRIMARY KEY);');
        firstDb.execute('''
          CREATE TABLE Sample (
            id INTEGER PRIMARY KEY,
            trip_id INTEGER,
            FOREIGN KEY (trip_id) REFERENCES Trip(id) ON DELETE CASCADE
          );
        ''');

        secondDb.execute('CREATE TABLE Trip (id INTEGER PRIMARY KEY);');
        secondDb.execute('''
          CREATE TABLE Sample (
            id INTEGER PRIMARY KEY,
            trip_id INTEGER,
            FOREIGN KEY (trip_id) REFERENCES Trip(id) ON DELETE RESTRICT
          );
        ''');

        final firstHash = builder.computeSchemaHash(firstDb);
        final secondHash = builder.computeSchemaHash(secondDb);

        expect(firstHash, isNot(secondHash));
      } finally {
        firstDb.dispose();
        secondDb.dispose();
      }
    });

    test('computeSchemaHash is stable regardless of table creation order', () {
      final firstDb = sqlite3.openInMemory();
      final secondDb = sqlite3.openInMemory();

      try {
        firstDb.execute('''
          CREATE TABLE Trip (
            id INTEGER PRIMARY KEY
          );
        ''');

        firstDb.execute('''
          CREATE TABLE Sample (
            id INTEGER PRIMARY KEY
          );
        ''');

        secondDb.execute('''
          CREATE TABLE Sample (
            id INTEGER PRIMARY KEY
          );
        ''');

        secondDb.execute('''
          CREATE TABLE Trip (
            id INTEGER PRIMARY KEY
          );
        ''');

        final firstHash = builder.computeSchemaHash(firstDb);
        final secondHash = builder.computeSchemaHash(secondDb);

        expect(firstHash, secondHash);
      } finally {
        firstDb.dispose();
        secondDb.dispose();
      }
    });

    test('computeSchemaHash is stable when indexes differ', () {
      final firstDb = sqlite3.openInMemory();
      final secondDb = sqlite3.openInMemory();

      try {
        firstDb.execute('CREATE TABLE Trip (id INTEGER PRIMARY KEY, name TEXT);');
        secondDb.execute('CREATE TABLE Trip (id INTEGER PRIMARY KEY, name TEXT);');
        secondDb.execute('CREATE INDEX idx_trip_name ON Trip(name);');

        final firstHash = builder.computeSchemaHash(firstDb);
        final secondHash = builder.computeSchemaHash(secondDb);

        expect(firstHash, secondHash);
      } finally {
        firstDb.dispose();
        secondDb.dispose();
      }
    });

    // -------------------------------------------------------------------------
    // createSystemTables direct tests
    // -------------------------------------------------------------------------

    test('createSystemTables creates settings table and inserts row', () {
      final db = sqlite3.openInMemory();

      try {
        final statements = [
          '''
          CREATE TABLE Trip (
            id INTEGER PRIMARY KEY
          );
          ''',
        ];

        db.execute(statements.first);

        builder.createSystemTables(db, statements);

        expect(tableNames(db), contains('__project_settings'));

        final rows = db.select('SELECT id FROM __project_settings;');

        expect(rows.length, 1);
        expect(rows.first['id'], 1);
      } finally {
        db.dispose();
      }
    });

    test('createSystemTables inserts schema hash matching computeSchemaHash', () {
      final db = sqlite3.openInMemory();

      try {
        final statements = [
          '''
          CREATE TABLE Trip (
            id INTEGER PRIMARY KEY,
            name TEXT
          );
          ''',
        ];

        db.execute(statements.first);

        final expectedHash = builder.computeSchemaHash(db);

        builder.createSystemTables(db, statements);

        final settingsJson = readSettingsJson(db);

        expect(settingsJson['schemaHash'], expectedHash);
      } finally {
        db.dispose();
      }
    });

    test('createSystemTables throws if called twice because settings table already exists', () {
      final db = sqlite3.openInMemory();

      try {
        final statements = [
          'CREATE TABLE Trip (id INTEGER PRIMARY KEY);',
        ];

        db.execute(statements.first);

        builder.createSystemTables(db, statements);

        expect(
          () => builder.createSystemTables(db, statements),
          throwsA(isA<SqliteException>()),
        );
      } finally {
        db.dispose();
      }
    });

    test('createSystemTables stores empty settings object', () {
      final db = sqlite3.openInMemory();

      try {
        final statements = [
          'CREATE TABLE Trip (id INTEGER PRIMARY KEY);',
        ];

        db.execute(statements.first);

        builder.createSystemTables(db, statements);

        final settingsJson = readSettingsJson(db);

        expect(settingsJson['settings'], <String, dynamic>{});
      } finally {
        db.dispose();
      }
    });

    test('createSystemTables stores empty integrity object', () {
      final db = sqlite3.openInMemory();

      try {
        final statements = [
          'CREATE TABLE Trip (id INTEGER PRIMARY KEY);',
        ];

        db.execute(statements.first);

        builder.createSystemTables(db, statements);

        final settingsJson = readSettingsJson(db);

        expect(settingsJson['integrity'], <String, dynamic>{});
      } finally {
        db.dispose();
      }
    });
  });
}