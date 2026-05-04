import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:ui_prototype/domain/entities/settings/project_settings.dart';
import 'package:ui_prototype/infrastructure/settings/project_settings_sqlite_repo.dart';

void main() {
  group('ProjectSettingsSqliteRepo', () {
    late Directory tempDir;
    late Database db;
    late ProjectSettingsSqliteRepo repo;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync(
        'project_settings_repo_test_',
      );

      final dbPath = '${tempDir.path}/test.sqlite';
      db = sqlite3.open(dbPath);

      db.execute('''
        CREATE TABLE __project_settings (
          id INTEGER PRIMARY KEY,
          settings_json TEXT NOT NULL
        );
      ''');

      repo = ProjectSettingsSqliteRepo(db);
    });

    tearDown(() {
      db.dispose();

      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    // -------------------------------------------------------------------------
    // Test helpers
    // -------------------------------------------------------------------------

    void insertSettingsJson(Map<String, dynamic> json, {int id = 1}) {
      db.execute(
        '''
        INSERT INTO __project_settings (id, settings_json)
        VALUES (?, ?)
        ''',
        [id, jsonEncode(json)],
      );
    }

    void insertRawSettingsJson(String rawJson, {int id = 1}) {
      db.execute(
        '''
        INSERT INTO __project_settings (id, settings_json)
        VALUES (?, ?)
        ''',
        [id, rawJson],
      );
    }

    Map<String, dynamic> readStoredJson({int id = 1}) {
      final result = db.select(
        'SELECT settings_json FROM __project_settings WHERE id = ?',
        [id],
      );

      expect(result.length, 1);

      return jsonDecode(result.first['settings_json'] as String)
          as Map<String, dynamic>;
    }

    int countSettingsRows() {
      final result = db.select(
        'SELECT COUNT(*) AS count FROM __project_settings',
      );

      return result.first['count'] as int;
    }

    // -------------------------------------------------------------------------
    // getSettings
    // -------------------------------------------------------------------------

    test('getSettings returns ProjectSettings.empty when settings row does not exist', () async {
      final settings = await repo.getSettings();

      expect(settings.toJson(), ProjectSettings.empty().toJson());
    });

    test('getSettings reads nested settings object from settings_json', () async {
      final storedJson = {
        'formatVersion': 1,
        'schemaSql': [
          'CREATE TABLE specimen (id INTEGER PRIMARY KEY);',
        ],
        'settings': {
          'scanner': {
            'targetTable': 'specimen',
            'targetColumn': 'tag_id',
          },
          'export': {
            'baseTable': 'specimen',
            'delimiter': ',',
          },
        },
      };

      insertSettingsJson(storedJson);

      final settings = await repo.getSettings();

      final settingsJson = settings.toJson();

      expect(settingsJson['scanner']['targetTable'], 'specimen');
      expect(settingsJson['scanner']['targetColumn'], 'tag_id');
      expect(settingsJson['export']['baseTable'], 'specimen');
      expect(settingsJson['export']['delimiter'], ',');
    });

    test('getSettings returns empty settings when settings key is missing', () async {
      final storedJson = {
        'formatVersion': 1,
        'schemaSql': [
          'CREATE TABLE specimen (id INTEGER PRIMARY KEY);',
        ],
      };

      insertSettingsJson(storedJson);

      final settings = await repo.getSettings();

      expect(settings.toJson(), ProjectSettings.empty().toJson());
    });

    test('getSettings returns empty settings when settings key is null', () async {
      final storedJson = {
        'formatVersion': 1,
        'schemaSql': [
          'CREATE TABLE specimen (id INTEGER PRIMARY KEY);',
        ],
        'settings': null,
      };

      insertSettingsJson(storedJson);

      final settings = await repo.getSettings();

      expect(settings.toJson(), ProjectSettings.empty().toJson());
    });

    test('getSettings returns empty settings when settings key is an empty map', () async {
      final storedJson = {
        'formatVersion': 1,
        'schemaSql': [
          'CREATE TABLE specimen (id INTEGER PRIMARY KEY);',
        ],
        'settings': <String, dynamic>{},
      };

      insertSettingsJson(storedJson);

      final settings = await repo.getSettings();

      expect(settings.toJson(), ProjectSettings.empty().toJson());
    });

    test('getSettings ignores project metadata and only parses the nested settings map', () async {
      final storedJson = {
        'formatVersion': 999,
        'schemaSql': [
          'CREATE TABLE trip (id INTEGER PRIMARY KEY);',
        ],
        'projectGuid': 'project-guid-123',
        'schemaHash': 'schema-hash-456',
        'lastOpenedAt': '2026-05-03T12:00:00Z',
        'settings': {
          'scanner': {
            'targetTable': 'fish',
            'targetColumn': 'tag_code',
          },
          'export': {
            'baseTable': 'fish',
            'delimiter': '\t',
          },
        },
      };

      insertSettingsJson(storedJson);

      final settings = await repo.getSettings();
      final settingsJson = settings.toJson();

      expect(settingsJson['scanner']['targetTable'], 'fish');
      expect(settingsJson['scanner']['targetColumn'], 'tag_code');
      expect(settingsJson['export']['baseTable'], 'fish');
      expect(settingsJson['export']['delimiter'], '\t');

      expect(settingsJson.containsKey('formatVersion'), isFalse);
      expect(settingsJson.containsKey('schemaSql'), isFalse);
      expect(settingsJson.containsKey('projectGuid'), isFalse);
      expect(settingsJson.containsKey('schemaHash'), isFalse);
    });

    test('getSettings reads only row id 1', () async {
      insertSettingsJson(
        {
          'settings': {
            'scanner': {
              'targetTable': 'correct_table',
              'targetColumn': 'correct_column',
            },
          },
        },
        id: 1,
      );

      insertSettingsJson(
        {
          'settings': {
            'scanner': {
              'targetTable': 'wrong_table',
              'targetColumn': 'wrong_column',
            },
          },
        },
        id: 2,
      );

      final settings = await repo.getSettings();
      final settingsJson = settings.toJson();

      expect(settingsJson['scanner']['targetTable'], 'correct_table');
      expect(settingsJson['scanner']['targetColumn'], 'correct_column');
    });

    test('getSettings throws FormatException when settings_json is not valid JSON', () async {
      insertRawSettingsJson('{ this is not valid json }');

      expect(
        () => repo.getSettings(),
        throwsA(isA<FormatException>()),
      );
    });

    test('getSettings throws when settings_json is a JSON list instead of an object', () async {
      insertRawSettingsJson(
        jsonEncode([
          'not',
          'a',
          'map',
        ]),
      );

      expect(
        () => repo.getSettings(),
        throwsA(isA<TypeError>()),
      );
    });

    test('getSettings throws when settings key is not a map', () async {
      insertSettingsJson({
        'formatVersion': 1,
        'settings': 'not-a-map',
      });

      expect(
        () => repo.getSettings(),
        throwsA(isA<TypeError>()),
      );
    });

    // -------------------------------------------------------------------------
    // updateSettings
    // -------------------------------------------------------------------------

    test('updateSettings inserts row when settings row does not exist', () async {
      final newSettings = ProjectSettings.empty();

      await repo.updateSettings(newSettings);

      final result = db.select(
        'SELECT settings_json FROM __project_settings WHERE id = 1',
      );

      expect(result.length, 1);

      final decoded = jsonDecode(result.first['settings_json'] as String)
          as Map<String, dynamic>;

      expect(decoded['settings'], newSettings.toJson());
    });

    test('updateSettings updates existing row', () async {
      final originalJson = {
        'formatVersion': 1,
        'schemaSql': [
          'CREATE TABLE specimen (id INTEGER PRIMARY KEY);',
        ],
        'settings': {
          'scanner': {
            'targetTable': 'old_table',
            'targetColumn': 'old_column',
          },
        },
      };

      insertSettingsJson(originalJson);

      final newSettings = ProjectSettings.empty();

      await repo.updateSettings(newSettings);

      final decoded = readStoredJson();

      expect(decoded['settings'], newSettings.toJson());
    });

    test('updateSettings preserves non-settings project metadata', () async {
      final originalJson = {
        'formatVersion': 1,
        'schemaSql': [
          'CREATE TABLE trip (id INTEGER PRIMARY KEY);',
          'CREATE TABLE specimen (id INTEGER PRIMARY KEY);',
        ],
        'projectGuid': 'abc-123',
        'schemaHash': 'hash-123',
        'settings': {
          'scanner': {
            'targetTable': 'old_table',
            'targetColumn': 'old_column',
          },
        },
      };

      insertSettingsJson(originalJson);

      final newSettings = ProjectSettings.empty();

      await repo.updateSettings(newSettings);

      final decoded = readStoredJson();

      expect(decoded['formatVersion'], 1);
      expect(decoded['schemaSql'], originalJson['schemaSql']);
      expect(decoded['projectGuid'], 'abc-123');
      expect(decoded['schemaHash'], 'hash-123');
      expect(decoded['settings'], newSettings.toJson());
    });

    test('updateSettings creates only one row when called repeatedly with no existing row', () async {
      final newSettings = ProjectSettings.empty();

      await repo.updateSettings(newSettings);
      await repo.updateSettings(newSettings);
      await repo.updateSettings(newSettings);

      expect(countSettingsRows(), 1);

      final decoded = readStoredJson();

      expect(decoded['settings'], newSettings.toJson());
    });

    test('updateSettings does not modify unrelated rows', () async {
      final rowTwoJson = {
        'formatVersion': 1,
        'settings': {
          'scanner': {
            'targetTable': 'row_two_table',
            'targetColumn': 'row_two_column',
          },
        },
      };

      insertSettingsJson(rowTwoJson, id: 2);

      final newSettings = ProjectSettings.empty();

      await repo.updateSettings(newSettings);

      final rowOne = readStoredJson(id: 1);
      final rowTwo = readStoredJson(id: 2);

      expect(rowOne['settings'], newSettings.toJson());
      expect(rowTwo, rowTwoJson);
    });

    test('updateSettings replaces old nested settings completely', () async {
      final originalJson = {
        'formatVersion': 1,
        'settings': {
          'scanner': {
            'targetTable': 'old_table',
            'targetColumn': 'old_column',
          },
          'export': {
            'baseTable': 'old_base',
            'delimiter': ',',
          },
          'extraOldSettingsSection': {
            'shouldDisappear': true,
          },
        },
      };

      insertSettingsJson(originalJson);

      final newSettings = ProjectSettings.empty();

      await repo.updateSettings(newSettings);

      final decoded = readStoredJson();
      final storedSettings = decoded['settings'] as Map<String, dynamic>;

      expect(storedSettings, newSettings.toJson());
      expect(storedSettings.containsKey('extraOldSettingsSection'), isFalse);
    });

    test('updateSettings preserves metadata even when existing settings key is missing', () async {
      final originalJson = {
        'formatVersion': 1,
        'schemaSql': [
          'CREATE TABLE sample (id INTEGER PRIMARY KEY);',
        ],
        'projectGuid': 'guid-without-settings',
      };

      insertSettingsJson(originalJson);

      final newSettings = ProjectSettings.empty();

      await repo.updateSettings(newSettings);

      final decoded = readStoredJson();

      expect(decoded['formatVersion'], 1);
      expect(decoded['schemaSql'], originalJson['schemaSql']);
      expect(decoded['projectGuid'], 'guid-without-settings');
      expect(decoded['settings'], newSettings.toJson());
    });

    test('updateSettings preserves metadata even when existing settings key is null', () async {
      final originalJson = {
        'formatVersion': 1,
        'schemaSql': [
          'CREATE TABLE sample (id INTEGER PRIMARY KEY);',
        ],
        'settings': null,
      };

      insertSettingsJson(originalJson);

      final newSettings = ProjectSettings.empty();

      await repo.updateSettings(newSettings);

      final decoded = readStoredJson();

      expect(decoded['formatVersion'], 1);
      expect(decoded['schemaSql'], originalJson['schemaSql']);
      expect(decoded['settings'], newSettings.toJson());
    });

    test('updateSettings writes valid JSON', () async {
      final newSettings = ProjectSettings.empty();

      await repo.updateSettings(newSettings);

      final result = db.select(
        'SELECT settings_json FROM __project_settings WHERE id = 1',
      );

      final rawJson = result.first['settings_json'] as String;

      expect(() => jsonDecode(rawJson), returnsNormally);
    });

    test('updateSettings writes a top-level JSON object', () async {
      final newSettings = ProjectSettings.empty();

      await repo.updateSettings(newSettings);

      final decoded = readStoredJson();

      expect(decoded, isA<Map<String, dynamic>>());
      expect(decoded.containsKey('settings'), isTrue);
    });

    test('updateSettings throws FormatException when existing row has invalid JSON', () async {
      insertRawSettingsJson('{ invalid json');

      final newSettings = ProjectSettings.empty();

      expect(
        () => repo.updateSettings(newSettings),
        throwsA(isA<FormatException>()),
      );
    });

    test('updateSettings throws when existing settings_json is a JSON list', () async {
      insertRawSettingsJson(jsonEncode(['not', 'a', 'map']));

      final newSettings = ProjectSettings.empty();

      expect(
        () => repo.updateSettings(newSettings),
        throwsA(isA<TypeError>()),
      );
    });

    // -------------------------------------------------------------------------
    // Round-trip behavior
    // -------------------------------------------------------------------------

    test('settings can be updated and then read back through the same repo', () async {
      final newSettings = ProjectSettings.empty();

      await repo.updateSettings(newSettings);

      final readBackSettings = await repo.getSettings();

      expect(readBackSettings.toJson(), newSettings.toJson());
    });

    test('settings can be updated, database reopened, and read back', () async {
      final dbPath = '${tempDir.path}/reopen_test.sqlite';

      // This test uses its own DB so we can safely close/reopen it inside the test.
      db.dispose();

      db = sqlite3.open(dbPath);

      db.execute('''
        CREATE TABLE __project_settings (
          id INTEGER PRIMARY KEY,
          settings_json TEXT NOT NULL
        );
      ''');

      repo = ProjectSettingsSqliteRepo(db);

      final newSettings = ProjectSettings.empty();

      await repo.updateSettings(newSettings);

      db.dispose();

      db = sqlite3.open(dbPath);
      repo = ProjectSettingsSqliteRepo(db);

      final readBackSettings = await repo.getSettings();

      expect(readBackSettings.toJson(), newSettings.toJson());
    });

    test('metadata survives update and read-back cycle', () async {
      final originalJson = {
        'formatVersion': 1,
        'schemaSql': [
          'CREATE TABLE trip (id INTEGER PRIMARY KEY);',
          'CREATE TABLE sample (id INTEGER PRIMARY KEY);',
          'CREATE TABLE specimen (id INTEGER PRIMARY KEY);',
        ],
        'projectGuid': 'stable-project-guid',
        'schemaHash': 'stable-schema-hash',
        'settings': {
          'scanner': {
            'targetTable': 'old_table',
            'targetColumn': 'old_column',
          },
        },
      };

      insertSettingsJson(originalJson);

      final newSettings = ProjectSettings.empty();

      await repo.updateSettings(newSettings);

      final storedAfterUpdate = readStoredJson();

      expect(storedAfterUpdate['formatVersion'], 1);
      expect(storedAfterUpdate['schemaSql'], originalJson['schemaSql']);
      expect(storedAfterUpdate['projectGuid'], 'stable-project-guid');
      expect(storedAfterUpdate['schemaHash'], 'stable-schema-hash');
      expect(storedAfterUpdate['settings'], newSettings.toJson());

      final readBackSettings = await repo.getSettings();

      expect(readBackSettings.toJson(), newSettings.toJson());
    });
  });
}