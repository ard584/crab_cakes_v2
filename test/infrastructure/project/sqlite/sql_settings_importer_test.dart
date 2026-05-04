import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqlite3/sqlite3.dart';

import 'package:crab_cakes/infrastructure/project/sqlite/sql_settings_importer.dart';

void main() {
  group('SqlSettingsImporter', () {
    late Directory tempDir;
    late SqlSettingsImporter importer;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync(
        'sql_settings_importer_test_',
      );

      importer = SqlSettingsImporter();
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    String createDb({
      bool createSettingsTable = true,
      bool insertSettingsRow = true,
      String initialSettingsJson = '{}',
    }) {
      final dbPath = path.join(tempDir.path, 'test.sqlite');

      final db = sqlite3.open(dbPath);

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
              VALUES (1, ?)
              ''',
              [initialSettingsJson],
            );
          }
        }
      } finally {
        db.dispose();
      }

      return dbPath;
    }

    String readSettingsJson(String dbPath, {int id = 1}) {
      final db = sqlite3.open(dbPath);

      try {
        final result = db.select(
          '''
          SELECT settings_json
          FROM __project_settings
          WHERE id = ?
          ''',
          [id],
        );

        expect(result.length, 1);

        return result.first['settings_json'] as String;
      } finally {
        db.dispose();
      }
    }

    int countSettingsRows(String dbPath) {
      final db = sqlite3.open(dbPath);

      try {
        final result = db.select(
          'SELECT COUNT(*) AS count FROM __project_settings',
        );

        return result.first['count'] as int;
      } finally {
        db.dispose();
      }
    }

    test('replaceSettingsJson updates settings_json for row id 1', () async {
      final dbPath = createDb(initialSettingsJson: '{}');

      const newSettingsJson = '{"settings":{"scanner":{"targetTable":"Specimen"}}}';

      await importer.replaceSettingsJson(
        dbPath: dbPath,
        settingsJson: newSettingsJson,
      );

      expect(readSettingsJson(dbPath), newSettingsJson);
    });

    test('replaceSettingsJson replaces existing project metadata json', () async {
      final dbPath = createDb(
        initialSettingsJson: jsonEncode({
          'formatVersion': 1,
          'schemaSql': [
            'CREATE TABLE OldTable (id INTEGER PRIMARY KEY);',
          ],
          'settings': {},
        }),
      );

      final newSettingsJson = jsonEncode({
        'formatVersion': 1,
        'schemaSql': [
          'CREATE TABLE NewTable (id INTEGER PRIMARY KEY);',
        ],
        'settings': {
          'scanner': {
            'targetTable': 'NewTable',
            'targetColumn': 'tag_id',
          },
        },
      });

      await importer.replaceSettingsJson(
        dbPath: dbPath,
        settingsJson: newSettingsJson,
      );

      expect(readSettingsJson(dbPath), newSettingsJson);
    });

    test('replaceSettingsJson preserves valid JSON text exactly as provided', () async {
      final dbPath = createDb();

      const newSettingsJson = '''
{
  "formatVersion": 1,
  "settings": {
    "export": {
      "baseTable": "Specimen",
      "delimiter": "\\t"
    }
  }
}
''';

      await importer.replaceSettingsJson(
        dbPath: dbPath,
        settingsJson: newSettingsJson,
      );

      expect(readSettingsJson(dbPath), newSettingsJson);
    });

    test('replaceSettingsJson stores invalid JSON text because importer only writes text', () async {
      final dbPath = createDb();

      const invalidJson = '{ this is not valid json';

      await importer.replaceSettingsJson(
        dbPath: dbPath,
        settingsJson: invalidJson,
      );

      expect(readSettingsJson(dbPath), invalidJson);
    });

    test('replaceSettingsJson stores empty string if provided', () async {
      final dbPath = createDb();

      await importer.replaceSettingsJson(
        dbPath: dbPath,
        settingsJson: '',
      );

      expect(readSettingsJson(dbPath), '');
    });

    test('replaceSettingsJson stores large settings json', () async {
      final dbPath = createDb();

      final largeSettings = {
        'formatVersion': 1,
        'schemaSql': List.generate(
          100,
          (index) => 'CREATE TABLE Table_$index (id INTEGER PRIMARY KEY);',
        ),
        'settings': {
          'fieldConfig': {
            for (var i = 0; i < 100; i++)
              'Table_$i': {
                'column_$i': {
                  'useDropdown': true,
                  'allowCustomValues': false,
                  'options': List.generate(20, (j) => 'Option_$j'),
                },
              },
          },
        },
      };

      final largeJson = jsonEncode(largeSettings);

      await importer.replaceSettingsJson(
        dbPath: dbPath,
        settingsJson: largeJson,
      );

      expect(readSettingsJson(dbPath), largeJson);
    });

    test('replaceSettingsJson only updates row id 1', () async {
      final dbPath = createDb(initialSettingsJson: '{"row":1}');

      final db = sqlite3.open(dbPath);
      try {
        db.execute(
          '''
          INSERT INTO __project_settings (id, settings_json)
          VALUES (2, ?)
          ''',
          ['{"row":2}'],
        );
      } finally {
        db.dispose();
      }

      const newSettingsJson = '{"updated":true}';

      await importer.replaceSettingsJson(
        dbPath: dbPath,
        settingsJson: newSettingsJson,
      );

      expect(readSettingsJson(dbPath, id: 1), newSettingsJson);
      expect(readSettingsJson(dbPath, id: 2), '{"row":2}');
    });

    test('replaceSettingsJson does not insert row when row id 1 is missing', () async {
      final dbPath = createDb(insertSettingsRow: false);

      expect(
        () => importer.replaceSettingsJson(
          dbPath: dbPath,
          settingsJson: '{}',
        ),
        throwsException,
      );

      expect(countSettingsRows(dbPath), 0);
    });

    test('replaceSettingsJson throws when only non-id-1 row exists', () async {
      final dbPath = createDb(insertSettingsRow: false);

      final db = sqlite3.open(dbPath);
      try {
        db.execute(
          '''
          INSERT INTO __project_settings (id, settings_json)
          VALUES (2, ?)
          ''',
          ['{"row":2}'],
        );
      } finally {
        db.dispose();
      }

      expect(
        () => importer.replaceSettingsJson(
          dbPath: dbPath,
          settingsJson: '{}',
        ),
        throwsException,
      );

      expect(readSettingsJson(dbPath, id: 2), '{"row":2}');
    });

    test('replaceSettingsJson throws when __project_settings table is missing', () async {
      final dbPath = createDb(createSettingsTable: false);

      expect(
        () => importer.replaceSettingsJson(
          dbPath: dbPath,
          settingsJson: '{}',
        ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('replaceSettingsJson throws when db path does not exist', () async {
      final dbPath = path.join(tempDir.path, 'missing.sqlite');

      expect(
        () => importer.replaceSettingsJson(
          dbPath: dbPath,
          settingsJson: '{}',
        ),
        throwsA(anyOf(isA<SqliteException>(), isA<FileSystemException>())),
      );
    });

    test('replaceSettingsJson disposes database after successful update', () async {
      final dbPath = createDb();

      await importer.replaceSettingsJson(
        dbPath: dbPath,
        settingsJson: '{"updated":true}',
      );

      final db = sqlite3.open(dbPath);
      try {
        final result = db.select('SELECT settings_json FROM __project_settings WHERE id = 1');

        expect(result.first['settings_json'], '{"updated":true}');
      } finally {
        db.dispose();
      }
    });

    test('replaceSettingsJson disposes database after failed update', () async {
      final dbPath = createDb(insertSettingsRow: false);

      try {
        await importer.replaceSettingsJson(
          dbPath: dbPath,
          settingsJson: '{"updated":true}',
        );
      } catch (_) {
        // Expected.
      }

      final db = sqlite3.open(dbPath);
      try {
        final result = db.select('SELECT COUNT(*) AS count FROM __project_settings');

        expect(result.first['count'], 0);
      } finally {
        db.dispose();
      }
    });

    test('replaceSettingsJson can be called multiple times on same database', () async {
      final dbPath = createDb();

      await importer.replaceSettingsJson(
        dbPath: dbPath,
        settingsJson: '{"version":1}',
      );

      await importer.replaceSettingsJson(
        dbPath: dbPath,
        settingsJson: '{"version":2}',
      );

      await importer.replaceSettingsJson(
        dbPath: dbPath,
        settingsJson: '{"version":3}',
      );

      expect(readSettingsJson(dbPath), '{"version":3}');
    });

    test('replaceSettingsJson does not change row count after repeated updates', () async {
      final dbPath = createDb();

      await importer.replaceSettingsJson(
        dbPath: dbPath,
        settingsJson: '{"version":1}',
      );

      await importer.replaceSettingsJson(
        dbPath: dbPath,
        settingsJson: '{"version":2}',
      );

      expect(countSettingsRows(dbPath), 1);
    });

    test('replaceSettingsJson can store scanner settings json', () async {
      final dbPath = createDb();

      final settingsJson = jsonEncode({
        'formatVersion': 1,
        'settings': {
          'scanner': {
            'targetTable': 'Specimen',
            'targetColumn': 'tag_id',
          },
        },
      });

      await importer.replaceSettingsJson(
        dbPath: dbPath,
        settingsJson: settingsJson,
      );

      final decoded = jsonDecode(readSettingsJson(dbPath)) as Map<String, dynamic>;

      expect(decoded['settings']['scanner']['targetTable'], 'Specimen');
      expect(decoded['settings']['scanner']['targetColumn'], 'tag_id');
    });

    test('replaceSettingsJson can store field config settings json', () async {
      final dbPath = createDb();

      final settingsJson = jsonEncode({
        'formatVersion': 1,
        'settings': {
          'fieldConfig': {
            'Specimen': {
              'tag_id': {
                'useDropdown': true,
                'allowCustomValues': false,
                'isRequired': true,
                'options': ['A', 'B', 'C'],
              },
            },
          },
        },
      });

      await importer.replaceSettingsJson(
        dbPath: dbPath,
        settingsJson: settingsJson,
      );

      final decoded = jsonDecode(readSettingsJson(dbPath)) as Map<String, dynamic>;

      expect(
        decoded['settings']['fieldConfig']['Specimen']['tag_id']['useDropdown'],
        isTrue,
      );

      expect(
        decoded['settings']['fieldConfig']['Specimen']['tag_id']['options'],
        ['A', 'B', 'C'],
      );
    });

    test('replaceSettingsJson can store export settings json', () async {
      final dbPath = createDb();

      final settingsJson = jsonEncode({
        'formatVersion': 1,
        'settings': {
          'export': {
            'baseTable': 'Specimen',
            'delimiter': ',',
          },
        },
      });

      await importer.replaceSettingsJson(
        dbPath: dbPath,
        settingsJson: settingsJson,
      );

      final decoded = jsonDecode(readSettingsJson(dbPath)) as Map<String, dynamic>;

      expect(decoded['settings']['export']['baseTable'], 'Specimen');
      expect(decoded['settings']['export']['delimiter'], ',');
    });

    test('replaceSettingsJson can store schemaSql list', () async {
      final dbPath = createDb();

      final settingsJson = jsonEncode({
        'formatVersion': 1,
        'schemaSql': [
          'CREATE TABLE Trip (id INTEGER PRIMARY KEY);',
          'CREATE TABLE Sample (id INTEGER PRIMARY KEY, trip_id INTEGER);',
        ],
        'settings': {},
      });

      await importer.replaceSettingsJson(
        dbPath: dbPath,
        settingsJson: settingsJson,
      );

      final decoded = jsonDecode(readSettingsJson(dbPath)) as Map<String, dynamic>;

      expect(decoded['schemaSql'], [
        'CREATE TABLE Trip (id INTEGER PRIMARY KEY);',
        'CREATE TABLE Sample (id INTEGER PRIMARY KEY, trip_id INTEGER);',
      ]);
    });

    test('replaceSettingsJson can store project identity metadata', () async {
      final dbPath = createDb();

      final settingsJson = jsonEncode({
        'formatVersion': 1,
        'projectGuid': 'project-guid-123',
        'schemaHash': 'schema-hash-456',
        'syncVersion': 1,
        'settings': {},
      });

      await importer.replaceSettingsJson(
        dbPath: dbPath,
        settingsJson: settingsJson,
      );

      final decoded = jsonDecode(readSettingsJson(dbPath)) as Map<String, dynamic>;

      expect(decoded['projectGuid'], 'project-guid-123');
      expect(decoded['schemaHash'], 'schema-hash-456');
      expect(decoded['syncVersion'], 1);
    });

    test('replaceSettingsJson supports unicode text', () async {
      final dbPath = createDb();

      final settingsJson = jsonEncode({
        'formatVersion': 1,
        'settings': {
          'fieldConfig': {
            'Specimen': {
              'notes': {
                'helpText': 'Café résumé jalapeño',
              },
            },
          },
        },
      });

      await importer.replaceSettingsJson(
        dbPath: dbPath,
        settingsJson: settingsJson,
      );

      final decoded = jsonDecode(readSettingsJson(dbPath)) as Map<String, dynamic>;

      expect(
        decoded['settings']['fieldConfig']['Specimen']['notes']['helpText'],
        'Café résumé jalapeño',
      );
    });

    test('replaceSettingsJson supports newline characters inside json string values', () async {
      final dbPath = createDb();

      final settingsJson = jsonEncode({
        'formatVersion': 1,
        'settings': {
          'fieldConfig': {
            'Specimen': {
              'notes': {
                'helpText': 'Line one\nLine two\nLine three',
              },
            },
          },
        },
      });

      await importer.replaceSettingsJson(
        dbPath: dbPath,
        settingsJson: settingsJson,
      );

      final decoded = jsonDecode(readSettingsJson(dbPath)) as Map<String, dynamic>;

      expect(
        decoded['settings']['fieldConfig']['Specimen']['notes']['helpText'],
        'Line one\nLine two\nLine three',
      );
    });

    test('replaceSettingsJson throws when settings_json column is constrained by CHECK', () async {
      final dbPath = path.join(tempDir.path, 'check_constraint.sqlite');

      final db = sqlite3.open(dbPath);
      try {
        db.execute('''
          CREATE TABLE __project_settings (
            id INTEGER PRIMARY KEY,
            settings_json TEXT NOT NULL CHECK(length(settings_json) > 2)
          );
        ''');

        db.execute(
          '''
          INSERT INTO __project_settings (id, settings_json)
          VALUES (1, ?)
          ''',
          ['{"initial":true}'],
        );
      } finally {
        db.dispose();
      }

      expect(
        () => importer.replaceSettingsJson(
          dbPath: dbPath,
          settingsJson: '{}',
        ),
        throwsA(isA<SqliteException>()),
      );

      expect(readSettingsJson(dbPath), '{"initial":true}');
    });

    test('replaceSettingsJson throws when settings_json column is NOT NULL and null would be impossible through method', () async {
      final dbPath = createDb();

      await importer.replaceSettingsJson(
        dbPath: dbPath,
        settingsJson: '{}',
      );

      expect(readSettingsJson(dbPath), '{}');
    });
  });
}