import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqlite3/sqlite3.dart';

import 'package:crab_cakes/infrastructure/providers/column_filter_provider.dart';
import 'package:crab_cakes/infrastructure/sync/sqlite_project_sync_repo.dart';

void main() {
  group('SqliteProjectSyncRepository', () {
    late Directory tempDir;
    late SqliteProjectSyncRepository repo;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync(
        'sqlite_project_sync_repo_test_',
      );

      repo = SqliteProjectSyncRepository();
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    String dbPath([String fileName = 'project.sqlite']) {
      return path.join(tempDir.path, fileName);
    }

    String createDb({
      String fileName = 'project.sqlite',
      Map<String, dynamic>? settingsJson,
      bool createSettingsTable = true,
      bool insertSettingsRow = true,
    }) {
      final filePath = dbPath(fileName);
      final db = sqlite3.open(filePath);

      try {
        if (createSettingsTable) {
          db.execute('''
            CREATE TABLE __project_settings (
              id INTEGER PRIMARY KEY,
              settings_json TEXT NOT NULL
            );
          ''');

          if (insertSettingsRow) {
            db.execute(
              '''
              INSERT INTO __project_settings (id, settings_json)
              VALUES (1, ?);
              ''',
              [
                jsonEncode(
                  settingsJson ??
                      {
                        'formatVersion': 1,
                        'projectGuid': 'project-guid-123',
                        'schemaHash': 'schema-hash-456',
                        'syncVersion': 1,
                        'settings': {},
                      },
                ),
              ],
            );
          }
        }
      } finally {
        db.dispose();
      }

      return filePath;
    }

    void createSyncTable(
      String filePath, {
      String tableName = 'Trip',
      bool includeDeletedAt = true,
    }) {
      final db = sqlite3.open(filePath);

      try {
        final deletedAtColumn = includeDeletedAt ? '__deleted_at TEXT,' : '';

        db.execute('''
          CREATE TABLE "$tableName" (
            id INTEGER PRIMARY KEY,
            name TEXT,
            notes TEXT,
            __row_guid TEXT UNIQUE,
            $deletedAtColumn
            __updated_at TEXT
          );
        ''');
      } finally {
        db.dispose();
      }
    }

    void insertTripRow(
      String filePath, {
      int id = 1,
      String name = 'Trip A',
      String? notes = 'Note A',
      String rowGuid = 'guid-1',
      String? deletedAt,
      String tableName = 'Trip',
    }) {
      final db = sqlite3.open(filePath);

      try {
        final hasDeletedAt = db
            .select('PRAGMA table_info("${tableName.replaceAll('"', '""')}");')
            .any((row) => row['name'] == '__deleted_at');

        if (hasDeletedAt) {
          db.execute(
            '''
            INSERT INTO "$tableName" (
              id,
              name,
              notes,
              __row_guid,
              __deleted_at,
              __updated_at
            )
            VALUES (?, ?, ?, ?, ?, ?);
            ''',
            [
              id,
              name,
              notes,
              rowGuid,
              deletedAt,
              '2026-05-03T12:00:00Z',
            ],
          );
        } else {
          db.execute(
            '''
            INSERT INTO "$tableName" (
              id,
              name,
              notes,
              __row_guid,
              __updated_at
            )
            VALUES (?, ?, ?, ?, ?);
            ''',
            [
              id,
              name,
              notes,
              rowGuid,
              '2026-05-03T12:00:00Z',
            ],
          );
        }
      } finally {
        db.dispose();
      }
    }

    List<Map<String, Object?>> selectAll(
      String filePath,
      String tableName,
    ) {
      final db = sqlite3.open(filePath);

      try {
        final quoted = '"${tableName.replaceAll('"', '""')}"';
        final rows = db.select('SELECT * FROM $quoted ORDER BY id;');

        return rows.map((row) => Map<String, Object?>.from(row)).toList();
      } finally {
        db.dispose();
      }
    }

    test('readSyncMetadata returns metadata from valid settings row', () async {
      final filePath = createDb();

      final metadata = await repo.readSyncMetadata(filePath);

      expect(metadata.projectGuid, 'project-guid-123');
      expect(metadata.schemaHash, 'schema-hash-456');
      expect(metadata.syncVersion, 1);
    });

    test('readSyncMetadata ignores unrelated settings fields', () async {
      final filePath = createDb(
        settingsJson: {
          'formatVersion': 1,
          'projectGuid': 'guid',
          'schemaHash': 'hash',
          'syncVersion': 2,
          'schemaSql': ['CREATE TABLE Trip (id INTEGER PRIMARY KEY);'],
          'settings': {
            'scanner': {
              'targetTable': 'Trip',
            },
          },
        },
      );

      final metadata = await repo.readSyncMetadata(filePath);

      expect(metadata.projectGuid, 'guid');
      expect(metadata.schemaHash, 'hash');
      expect(metadata.syncVersion, 2);
    });

    test('readSyncMetadata throws when settings table is missing', () async {
      final filePath = createDb(createSettingsTable: false);

      await expectLater(
        () => repo.readSyncMetadata(filePath),
        throwsA(isA<SqliteException>()),
      );
    });

    test('readSyncMetadata throws when settings row is missing', () async {
      final filePath = createDb(insertSettingsRow: false);

      await expectLater(
        () => repo.readSyncMetadata(filePath),
        throwsException,
      );
    });

    test('readSyncMetadata throws when settings_json is empty', () async {
      final filePath = createDb(insertSettingsRow: false);

      final db = sqlite3.open(filePath);
      try {
        db.execute(
          '''
          INSERT INTO __project_settings (id, settings_json)
          VALUES (1, ?);
          ''',
          [''],
        );
      } finally {
        db.dispose();
      }

      await expectLater(
        () => repo.readSyncMetadata(filePath),
        throwsException,
      );
    });

    test('readSyncMetadata throws when settings_json is invalid JSON', () async {
      final filePath = createDb(insertSettingsRow: false);

      final db = sqlite3.open(filePath);
      try {
        db.execute(
          '''
          INSERT INTO __project_settings (id, settings_json)
          VALUES (1, ?);
          ''',
          ['{ invalid json'],
        );
      } finally {
        db.dispose();
      }

      await expectLater(
        () => repo.readSyncMetadata(filePath),
        throwsA(isA<FormatException>()),
      );
    });

    test('readSyncMetadata throws when settings_json is JSON list', () async {
      final filePath = createDb(insertSettingsRow: false);

      final db = sqlite3.open(filePath);
      try {
        db.execute(
          '''
          INSERT INTO __project_settings (id, settings_json)
          VALUES (1, ?);
          ''',
          [
            jsonEncode(['not', 'a', 'map']),
          ],
        );
      } finally {
        db.dispose();
      }

      await expectLater(
        () => repo.readSyncMetadata(filePath),
        throwsException,
      );
    });

    test('readSyncMetadata throws when projectGuid is missing', () async {
      final filePath = createDb(
        settingsJson: {
          'schemaHash': 'hash',
          'syncVersion': 1,
        },
      );

      await expectLater(
        () => repo.readSyncMetadata(filePath),
        throwsException,
      );
    });

    test('readSyncMetadata throws when projectGuid is empty', () async {
      final filePath = createDb(
        settingsJson: {
          'projectGuid': '',
          'schemaHash': 'hash',
          'syncVersion': 1,
        },
      );

      await expectLater(
        () => repo.readSyncMetadata(filePath),
        throwsException,
      );
    });

    test('readSyncMetadata throws when schemaHash is missing', () async {
      final filePath = createDb(
        settingsJson: {
          'projectGuid': 'guid',
          'syncVersion': 1,
        },
      );

      await expectLater(
        () => repo.readSyncMetadata(filePath),
        throwsException,
      );
    });

    test('readSyncMetadata throws when schemaHash is empty', () async {
      final filePath = createDb(
        settingsJson: {
          'projectGuid': 'guid',
          'schemaHash': '',
          'syncVersion': 1,
        },
      );

      await expectLater(
        () => repo.readSyncMetadata(filePath),
        throwsException,
      );
    });

    test('readSyncMetadata throws when syncVersion is missing', () async {
      final filePath = createDb(
        settingsJson: {
          'projectGuid': 'guid',
          'schemaHash': 'hash',
        },
      );

      await expectLater(
        () => repo.readSyncMetadata(filePath),
        throwsException,
      );
    });

    test('readSyncMetadata throws when syncVersion is string', () async {
      final filePath = createDb(
        settingsJson: {
          'projectGuid': 'guid',
          'schemaHash': 'hash',
          'syncVersion': '1',
        },
      );

      await expectLater(
        () => repo.readSyncMetadata(filePath),
        throwsException,
      );
    });

    test('getUserTables returns empty list when database has no user tables', () async {
      final filePath = createDb();

      final tables = await repo.getUserTables(filePath);

      expect(tables, isEmpty);
    });

    test('getUserTables returns user tables sorted by name', () async {
      final filePath = createDb();

      final db = sqlite3.open(filePath);
      try {
        db.execute('CREATE TABLE Specimen (id INTEGER PRIMARY KEY);');
        db.execute('CREATE TABLE Trip (id INTEGER PRIMARY KEY);');
        db.execute('CREATE TABLE Sample (id INTEGER PRIMARY KEY);');
      } finally {
        db.dispose();
      }

      final tables = await repo.getUserTables(filePath);

      expect(tables, ['Sample', 'Specimen', 'Trip']);
    });

    test('getUserTables excludes __project_settings table', () async {
      final filePath = createDb();

      final db = sqlite3.open(filePath);
      try {
        db.execute('CREATE TABLE Trip (id INTEGER PRIMARY KEY);');
      } finally {
        db.dispose();
      }

      final tables = await repo.getUserTables(filePath);

      expect(tables, ['Trip']);
      expect(tables.contains('__project_settings'), isFalse);
    });

    test('getUserTables excludes sqlite internal tables', () async {
      final filePath = createDb();

      final db = sqlite3.open(filePath);
      try {
        db.execute('CREATE TABLE Trip (id INTEGER PRIMARY KEY AUTOINCREMENT);');
      } finally {
        db.dispose();
      }

      final tables = await repo.getUserTables(filePath);

      expect(tables, ['Trip']);
      expect(tables.any((table) => table.startsWith('sqlite_')), isFalse);
    });

    test('getUserTables excludes hidden-prefix internal tables', () async {
      final filePath = createDb();

      final db = sqlite3.open(filePath);
      try {
        db.execute('CREATE TABLE Trip (id INTEGER PRIMARY KEY);');
        db.execute(
          'CREATE TABLE ${kColumnPrefixToHide}Internal (id INTEGER PRIMARY KEY);',
        );
      } finally {
        db.dispose();
      }

      final tables = await repo.getUserTables(filePath);

      expect(tables, ['Trip']);
    });

    test('getRowsForSync returns all rows when table has no deleted_at column', () async {
      final filePath = createDb();
      createSyncTable(filePath, includeDeletedAt: false);

      insertTripRow(filePath, id: 1, rowGuid: 'guid-1');
      insertTripRow(filePath, id: 2, rowGuid: 'guid-2');

      final rows = await repo.getRowsForSync(
        dbPath: filePath,
        tableName: 'Trip',
      );

      expect(rows.length, 2);
      expect(rows.map((row) => row['__row_guid']).toSet(), {'guid-1', 'guid-2'});
    });

    test('getRowsForSync excludes rows with deleted_at when column exists', () async {
      final filePath = createDb();
      createSyncTable(filePath, includeDeletedAt: true);

      insertTripRow(filePath, id: 1, rowGuid: 'guid-1', deletedAt: null);
      insertTripRow(filePath, id: 2, rowGuid: 'guid-2', deletedAt: '2026-05-03');

      final rows = await repo.getRowsForSync(
        dbPath: filePath,
        tableName: 'Trip',
      );

      expect(rows.length, 1);
      expect(rows.single['__row_guid'], 'guid-1');
    });

    test('getRowsForSync returns maps with column values', () async {
      final filePath = createDb();
      createSyncTable(filePath);

      insertTripRow(
        filePath,
        id: 1,
        name: 'Trip A',
        notes: 'Note A',
        rowGuid: 'guid-1',
      );

      final rows = await repo.getRowsForSync(
        dbPath: filePath,
        tableName: 'Trip',
      );

      expect(rows.single['id'], 1);
      expect(rows.single['name'], 'Trip A');
      expect(rows.single['notes'], 'Note A');
      expect(rows.single['__row_guid'], 'guid-1');
    });

    test('getRowsForSync supports table names with spaces', () async {
      final filePath = createDb();
      createSyncTable(filePath, tableName: 'Trip Data');

      insertTripRow(
        filePath,
        tableName: 'Trip Data',
        id: 1,
        rowGuid: 'guid-1',
      );

      final rows = await repo.getRowsForSync(
        dbPath: filePath,
        tableName: 'Trip Data',
      );

      expect(rows.length, 1);
      expect(rows.single['__row_guid'], 'guid-1');
    });

    test('insertRowForSync inserts row into table', () async {
      final filePath = createDb();
      createSyncTable(filePath);

      await repo.insertRowForSync(
        dbPath: filePath,
        tableName: 'Trip',
        row: {
          'id': 1,
          'name': 'Trip A',
          'notes': 'Note A',
          '__row_guid': 'guid-1',
          '__updated_at': '2026-05-03T12:00:00Z',
        },
      );

      final rows = selectAll(filePath, 'Trip');

      expect(rows.length, 1);
      expect(rows.single['id'], 1);
      expect(rows.single['name'], 'Trip A');
      expect(rows.single['__row_guid'], 'guid-1');
    });

    test('insertRowForSync preserves null values', () async {
      final filePath = createDb();
      createSyncTable(filePath);

      await repo.insertRowForSync(
        dbPath: filePath,
        tableName: 'Trip',
        row: {
          'id': 1,
          'name': 'Trip A',
          'notes': null,
          '__row_guid': 'guid-1',
        },
      );

      final rows = selectAll(filePath, 'Trip');

      expect(rows.single['notes'], isNull);
    });

    test('insertRowForSync removes rowid key before inserting', () async {
      final filePath = createDb();
      createSyncTable(filePath);

      await repo.insertRowForSync(
        dbPath: filePath,
        tableName: 'Trip',
        row: {
          'rowid': 999,
          'id': 1,
          'name': 'Trip A',
          '__row_guid': 'guid-1',
        },
      );

      final rows = selectAll(filePath, 'Trip');

      expect(rows.single['id'], 1);
      expect(rows.single['__row_guid'], 'guid-1');
    });

    test('insertRowForSync throws when filtered row is empty', () async {
      final filePath = createDb();
      createSyncTable(filePath);

      await expectLater(
        () => repo.insertRowForSync(
          dbPath: filePath,
          tableName: 'Trip',
          row: {
            'rowid': 999,
          },
        ),
        throwsException,
      );
    });

    test('insertRowForSync supports table name with spaces', () async {
      final filePath = createDb();
      createSyncTable(filePath, tableName: 'Trip Data');

      await repo.insertRowForSync(
        dbPath: filePath,
        tableName: 'Trip Data',
        row: {
          'id': 1,
          'name': 'Trip A',
          '__row_guid': 'guid-1',
        },
      );

      final rows = selectAll(filePath, 'Trip Data');

      expect(rows.length, 1);
      expect(rows.single['name'], 'Trip A');
    });

    test('insertRowForSync supports column names with spaces', () async {
      final filePath = createDb();

      final db = sqlite3.open(filePath);
      try {
        db.execute('''
          CREATE TABLE Trip (
            id INTEGER PRIMARY KEY,
            "trip name" TEXT,
            __row_guid TEXT UNIQUE
          );
        ''');
      } finally {
        db.dispose();
      }

      await repo.insertRowForSync(
        dbPath: filePath,
        tableName: 'Trip',
        row: {
          'id': 1,
          'trip name': 'Trip A',
          '__row_guid': 'guid-1',
        },
      );

      final db2 = sqlite3.open(filePath);
      try {
        final rows = db2.select('SELECT "trip name" FROM Trip;');
        expect(rows.single['trip name'], 'Trip A');
      } finally {
        db2.dispose();
      }
    });

    test('updateRowForSync updates row by __row_guid', () async {
      final filePath = createDb();
      createSyncTable(filePath);
      insertTripRow(filePath, id: 1, name: 'Old Name', rowGuid: 'guid-1');

      await repo.updateRowForSync(
        dbPath: filePath,
        tableName: 'Trip',
        row: {
          '__row_guid': 'guid-1',
          'name': 'New Name',
          'notes': 'New Note',
        },
      );

      final rows = selectAll(filePath, 'Trip');

      expect(rows.single['name'], 'New Name');
      expect(rows.single['notes'], 'New Note');
    });

    test('updateRowForSync does not update __row_guid value itself', () async {
      final filePath = createDb();
      createSyncTable(filePath);
      insertTripRow(filePath, id: 1, name: 'Old Name', rowGuid: 'guid-1');

      await repo.updateRowForSync(
        dbPath: filePath,
        tableName: 'Trip',
        row: {
          '__row_guid': 'guid-1',
          'name': 'New Name',
        },
      );

      final rows = selectAll(filePath, 'Trip');

      expect(rows.single['__row_guid'], 'guid-1');
      expect(rows.single['name'], 'New Name');
    });

    test('updateRowForSync preserves null values', () async {
      final filePath = createDb();
      createSyncTable(filePath);
      insertTripRow(filePath, id: 1, notes: 'Old Note', rowGuid: 'guid-1');

      await repo.updateRowForSync(
        dbPath: filePath,
        tableName: 'Trip',
        row: {
          '__row_guid': 'guid-1',
          'notes': null,
        },
      );

      final rows = selectAll(filePath, 'Trip');

      expect(rows.single['notes'], isNull);
    });

    test('updateRowForSync throws when __row_guid is missing', () async {
      final filePath = createDb();
      createSyncTable(filePath);

      await expectLater(
        () => repo.updateRowForSync(
          dbPath: filePath,
          tableName: 'Trip',
          row: {
            'name': 'New Name',
          },
        ),
        throwsException,
      );
    });

    test('updateRowForSync throws when __row_guid is empty', () async {
      final filePath = createDb();
      createSyncTable(filePath);

      await expectLater(
        () => repo.updateRowForSync(
          dbPath: filePath,
          tableName: 'Trip',
          row: {
            '__row_guid': '',
            'name': 'New Name',
          },
        ),
        throwsException,
      );
    });

    test('updateRowForSync throws when matching row is not found', () async {
      final filePath = createDb();
      createSyncTable(filePath);

      await expectLater(
        () => repo.updateRowForSync(
          dbPath: filePath,
          tableName: 'Trip',
          row: {
            '__row_guid': 'missing-guid',
            'name': 'New Name',
          },
        ),
        throwsException,
      );
    });

    test('updateRowForSync returns without change when only __row_guid is writable', () async {
      final filePath = createDb();
      createSyncTable(filePath);
      insertTripRow(filePath, id: 1, name: 'Old Name', rowGuid: 'guid-1');

      await repo.updateRowForSync(
        dbPath: filePath,
        tableName: 'Trip',
        row: {
          '__row_guid': 'guid-1',
        },
      );

      final rows = selectAll(filePath, 'Trip');

      expect(rows.single['name'], 'Old Name');
    });

    test('updateRowForSync supports table name with spaces', () async {
      final filePath = createDb();
      createSyncTable(filePath, tableName: 'Trip Data');
      insertTripRow(
        filePath,
        tableName: 'Trip Data',
        id: 1,
        name: 'Old Name',
        rowGuid: 'guid-1',
      );

      await repo.updateRowForSync(
        dbPath: filePath,
        tableName: 'Trip Data',
        row: {
          '__row_guid': 'guid-1',
          'name': 'New Name',
        },
      );

      final rows = selectAll(filePath, 'Trip Data');

      expect(rows.single['name'], 'New Name');
    });

    test('database can be reopened after repository methods dispose connections', () async {
      final filePath = createDb();
      createSyncTable(filePath);

      await repo.insertRowForSync(
        dbPath: filePath,
        tableName: 'Trip',
        row: {
          'id': 1,
          'name': 'Trip A',
          '__row_guid': 'guid-1',
        },
      );

      final db = sqlite3.open(filePath);
      try {
        final rows = db.select('SELECT COUNT(*) AS count FROM Trip;');
        expect(rows.first['count'], 1);
      } finally {
        db.dispose();
      }
    });
  });
}