import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:crab_cakes/infrastructure/project/project_json_integrity_service.dart';
import 'package:crab_cakes/infrastructure/settings/settings_exporter.dart';

void main() {
  group('SettingsExporter', () {
    late Directory tempDir;
    late Database db;
    late ProjectJsonIntegrityService integrityService;
    late SettingsExporter exporter;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync(
        'settings_exporter_test_',
      );

      final dbPath = '${tempDir.path}/test.sqlite';
      db = sqlite3.open(dbPath);

      db.execute('''
        CREATE TABLE __project_settings (
          id INTEGER PRIMARY KEY,
          settings_json TEXT NOT NULL
        );
      ''');

      integrityService = ProjectJsonIntegrityService(
        hmacKey: utf8.encode('test-hmac-key'),
      );

      exporter = SettingsExporter(db, integrityService);
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

    File fileAt(String path) {
      return File(path);
    }

    String readFile(String path) {
      return File(path).readAsStringSync();
    }

    Map<String, dynamic> readJsonFile(String path) {
      return jsonDecode(readFile(path)) as Map<String, dynamic>;
    }

    Map<String, dynamic> verifiedPayloadFromFile(String path) {
      final exported = readJsonFile(path);
      return integrityService.extractVerifiedPayload(exported);
    }

    void expectValidSignedJsonFile({
      required String path,
      required Map<String, dynamic> expectedPayload,
    }) {
      final exported = readJsonFile(path);

      expect(exported['payload'], expectedPayload);
      expect(exported['integrity'], isA<Map<String, dynamic>>());

      final integrity = exported['integrity'] as Map<String, dynamic>;

      expect(
        integrity['algorithm'],
        ProjectJsonIntegrityService.algorithm,
      );

      expect(integrity['signature'], isA<String>());
      expect((integrity['signature'] as String).isNotEmpty, isTrue);

      final verifiedPayload = integrityService.extractVerifiedPayload(exported);

      expect(verifiedPayload, expectedPayload);
    }

    // -------------------------------------------------------------------------
    // Missing row behavior
    // -------------------------------------------------------------------------

    test('export returns without creating a file when settings row does not exist', () async {
      final outputPath = '${tempDir.path}/exported_settings.json';

      await exporter.export(outputPath);

      expect(fileAt(outputPath).existsSync(), isFalse);
    });

    test('export returns without creating a file when only non-id-1 row exists', () async {
      insertSettingsJson(
        {
          'formatVersion': 1,
          'settings': {
            'scanner': {
              'targetTable': 'specimen',
            },
          },
        },
        id: 2,
      );

      final outputPath = '${tempDir.path}/exported_settings.json';

      await exporter.export(outputPath);

      expect(fileAt(outputPath).existsSync(), isFalse);
    });

    // -------------------------------------------------------------------------
    // Path / extension behavior
    // -------------------------------------------------------------------------

    test('export writes to exact path when filePath already ends with .json', () async {
      final storedJson = {
        'formatVersion': 1,
        'settings': {},
      };

      insertSettingsJson(storedJson);

      final outputPath = '${tempDir.path}/settings.json';

      await exporter.export(outputPath);

      expect(fileAt(outputPath).existsSync(), isTrue);
      expect(fileAt('$outputPath.json').existsSync(), isFalse);

      expectValidSignedJsonFile(
        path: outputPath,
        expectedPayload: storedJson,
      );
    });

    test('export appends .json when filePath has no extension', () async {
      final storedJson = {
        'formatVersion': 1,
        'settings': {},
      };

      insertSettingsJson(storedJson);

      final outputPathWithoutExtension = '${tempDir.path}/settings_export';
      final expectedOutputPath = '$outputPathWithoutExtension.json';

      await exporter.export(outputPathWithoutExtension);

      expect(fileAt(expectedOutputPath).existsSync(), isTrue);
      expect(fileAt(outputPathWithoutExtension).existsSync(), isFalse);

      expectValidSignedJsonFile(
        path: expectedOutputPath,
        expectedPayload: storedJson,
      );
    });

    test('export appends .json when filePath has a non-json extension', () async {
      final storedJson = {
        'formatVersion': 1,
        'settings': {},
      };

      insertSettingsJson(storedJson);

      final outputPath = '${tempDir.path}/settings_export.txt';
      final expectedOutputPath = '$outputPath.json';

      await exporter.export(outputPath);

      expect(fileAt(expectedOutputPath).existsSync(), isTrue);
      expect(fileAt(outputPath).existsSync(), isFalse);

      expectValidSignedJsonFile(
        path: expectedOutputPath,
        expectedPayload: storedJson,
      );
    });

    test('export does not append .json when extension is uppercase .JSON', () async {
      final storedJson = {
        'formatVersion': 1,
        'settings': {},
      };

      insertSettingsJson(storedJson);

      final outputPath = '${tempDir.path}/settings.JSON';

      await exporter.export(outputPath);

      expect(fileAt(outputPath).existsSync(), isTrue);
      expect(fileAt('$outputPath.json').existsSync(), isFalse);

      expectValidSignedJsonFile(
        path: outputPath,
        expectedPayload: storedJson,
      );
    });

    test('export writes inside nested directory when directory already exists', () async {
      final storedJson = {
        'formatVersion': 1,
        'settings': {},
      };

      insertSettingsJson(storedJson);

      final nestedDir = Directory('${tempDir.path}/nested');
      nestedDir.createSync();

      final outputPath = '${nestedDir.path}/settings.json';

      await exporter.export(outputPath);

      expect(fileAt(outputPath).existsSync(), isTrue);

      expectValidSignedJsonFile(
        path: outputPath,
        expectedPayload: storedJson,
      );
    });

    // -------------------------------------------------------------------------
    // Integrity behavior
    // -------------------------------------------------------------------------

    test('export writes valid signed project JSON', () async {
      final storedJson = {
        'formatVersion': 1,
        'schemaSql': [
          'CREATE TABLE specimen (id INTEGER PRIMARY KEY);',
        ],
        'projectGuid': 'abc-123',
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

      final outputPath = '${tempDir.path}/settings.json';

      await exporter.export(outputPath);

      expectValidSignedJsonFile(
        path: outputPath,
        expectedPayload: storedJson,
      );
    });

    test('exported signature verifies with the same integrity service', () async {
      final storedJson = {
        'formatVersion': 1,
        'projectGuid': 'abc-123',
        'schemaHash': 'hash-123',
        'settings': {
          'scanner': {
            'targetTable': 'specimen',
            'targetColumn': 'tag_id',
          },
        },
      };

      insertSettingsJson(storedJson);

      final outputPath = '${tempDir.path}/settings.json';

      await exporter.export(outputPath);

      final verifiedPayload = verifiedPayloadFromFile(outputPath);

      expect(verifiedPayload, storedJson);
    });

    test('exported signature fails verification with a different hmac key', () async {
      final storedJson = {
        'formatVersion': 1,
        'settings': {
          'scanner': {
            'targetTable': 'specimen',
          },
        },
      };

      insertSettingsJson(storedJson);

      final outputPath = '${tempDir.path}/settings.json';

      await exporter.export(outputPath);

      final exported = readJsonFile(outputPath);

      final wrongIntegrityService = ProjectJsonIntegrityService(
        hmacKey: utf8.encode('wrong-test-hmac-key'),
      );

      expect(
        () => wrongIntegrityService.extractVerifiedPayload(exported),
        throwsA(isA<ProjectJsonIntegrityException>()),
      );
    });

    test('export signs normalized decoded JSON instead of raw stored JSON string', () async {
      const uglyJson = '''
      {
        "formatVersion": 1,
        "settings": {
          "scanner": {
            "targetTable": "specimen",
            "targetColumn": "tag_id"
          }
        }
      }
      ''';

      final expectedPayload = {
        'formatVersion': 1,
        'settings': {
          'scanner': {
            'targetTable': 'specimen',
            'targetColumn': 'tag_id',
          },
        },
      };

      insertRawSettingsJson(uglyJson);

      final outputPath = '${tempDir.path}/settings.json';

      await exporter.export(outputPath);

      expectValidSignedJsonFile(
        path: outputPath,
        expectedPayload: expectedPayload,
      );
    });

    test('exported file contains payload and integrity wrapper', () async {
      final storedJson = {
        'formatVersion': 1,
        'settings': {},
      };

      insertSettingsJson(storedJson);

      final outputPath = '${tempDir.path}/settings.json';

      await exporter.export(outputPath);

      final exported = readJsonFile(outputPath);

      expect(exported.containsKey('payload'), isTrue);
      expect(exported.containsKey('integrity'), isTrue);
      expect(exported['payload'], storedJson);
      expect(exported['integrity'], isA<Map<String, dynamic>>());
    });

    test('tampering with exported payload invalidates signature', () async {
      final storedJson = {
        'formatVersion': 1,
        'settings': {
          'scanner': {
            'targetTable': 'specimen',
          },
        },
      };

      insertSettingsJson(storedJson);

      final outputPath = '${tempDir.path}/settings.json';

      await exporter.export(outputPath);

      final exported = readJsonFile(outputPath);

      final payload = exported['payload'] as Map<String, dynamic>;
      final settings = payload['settings'] as Map<String, dynamic>;
      final scanner = settings['scanner'] as Map<String, dynamic>;

      scanner['targetTable'] = 'tampered_table';

      expect(
        () => integrityService.extractVerifiedPayload(exported),
        throwsA(isA<ProjectJsonIntegrityException>()),
      );
    });

    test('tampering with exported signature invalidates file', () async {
      final storedJson = {
        'formatVersion': 1,
        'settings': {},
      };

      insertSettingsJson(storedJson);

      final outputPath = '${tempDir.path}/settings.json';

      await exporter.export(outputPath);

      final exported = readJsonFile(outputPath);
      final integrity = exported['integrity'] as Map<String, dynamic>;

      integrity['signature'] = 'bad-signature';

      expect(
        () => integrityService.extractVerifiedPayload(exported),
        throwsA(isA<ProjectJsonIntegrityException>()),
      );
    });

    // -------------------------------------------------------------------------
    // Stored JSON shape behavior
    // -------------------------------------------------------------------------

    test('export works when settings key is missing', () async {
      final storedJson = {
        'formatVersion': 1,
        'schemaSql': [
          'CREATE TABLE specimen (id INTEGER PRIMARY KEY);',
        ],
      };

      insertSettingsJson(storedJson);

      final outputPath = '${tempDir.path}/settings.json';

      await exporter.export(outputPath);

      expect(fileAt(outputPath).existsSync(), isTrue);

      expectValidSignedJsonFile(
        path: outputPath,
        expectedPayload: storedJson,
      );
    });

    test('export works when settings key is null', () async {
      final storedJson = {
        'formatVersion': 1,
        'settings': null,
      };

      insertSettingsJson(storedJson);

      final outputPath = '${tempDir.path}/settings.json';

      await exporter.export(outputPath);

      expect(fileAt(outputPath).existsSync(), isTrue);

      expectValidSignedJsonFile(
        path: outputPath,
        expectedPayload: storedJson,
      );
    });

    test('export works when settings key is an empty map', () async {
      final storedJson = {
        'formatVersion': 1,
        'settings': <String, dynamic>{},
      };

      insertSettingsJson(storedJson);

      final outputPath = '${tempDir.path}/settings.json';

      await exporter.export(outputPath);

      expect(fileAt(outputPath).existsSync(), isTrue);

      expectValidSignedJsonFile(
        path: outputPath,
        expectedPayload: storedJson,
      );
    });

    test('export preserves all project metadata in signed payload', () async {
      final storedJson = {
        'formatVersion': 1,
        'schemaSql': [
          'CREATE TABLE trip (id INTEGER PRIMARY KEY);',
          'CREATE TABLE sample (id INTEGER PRIMARY KEY);',
          'CREATE TABLE specimen (id INTEGER PRIMARY KEY);',
        ],
        'projectGuid': 'project-guid-123',
        'schemaHash': 'schema-hash-456',
        'createdAt': '2026-05-03T12:00:00Z',
        'settings': {
          'scanner': {
            'targetTable': 'specimen',
            'targetColumn': 'tag_id',
          },
        },
      };

      insertSettingsJson(storedJson);

      final outputPath = '${tempDir.path}/settings.json';

      await exporter.export(outputPath);

      final verifiedPayload = verifiedPayloadFromFile(outputPath);

      expect(verifiedPayload['formatVersion'], 1);
      expect(verifiedPayload['schemaSql'], storedJson['schemaSql']);
      expect(verifiedPayload['projectGuid'], 'project-guid-123');
      expect(verifiedPayload['schemaHash'], 'schema-hash-456');
      expect(verifiedPayload['createdAt'], '2026-05-03T12:00:00Z');
      expect(verifiedPayload['settings'], storedJson['settings']);
    });

    test('export reads only row id 1', () async {
      final rowOneJson = {
        'formatVersion': 1,
        'settings': {
          'scanner': {
            'targetTable': 'correct_table',
          },
        },
      };

      final rowTwoJson = {
        'formatVersion': 1,
        'settings': {
          'scanner': {
            'targetTable': 'wrong_table',
          },
        },
      };

      insertSettingsJson(rowOneJson, id: 1);
      insertSettingsJson(rowTwoJson, id: 2);

      final outputPath = '${tempDir.path}/settings.json';

      await exporter.export(outputPath);

      expectValidSignedJsonFile(
        path: outputPath,
        expectedPayload: rowOneJson,
      );
    });

    // -------------------------------------------------------------------------
    // Invalid JSON / invalid storage behavior
    // -------------------------------------------------------------------------

    test('export throws FormatException when settings_json is invalid JSON', () async {
      insertRawSettingsJson('{ invalid json');

      final outputPath = '${tempDir.path}/settings.json';

      expect(
        () => exporter.export(outputPath),
        throwsA(isA<FormatException>()),
      );

      expect(fileAt(outputPath).existsSync(), isFalse);
    });

    test('export throws TypeError when settings_json is a JSON list', () async {
      insertRawSettingsJson(
        jsonEncode([
          'not',
          'a',
          'map',
        ]),
      );

      final outputPath = '${tempDir.path}/settings.json';

      expect(
        () => exporter.export(outputPath),
        throwsA(isA<TypeError>()),
      );

      expect(fileAt(outputPath).existsSync(), isFalse);
    });

    test('export throws TypeError when settings_json is a JSON string', () async {
      insertRawSettingsJson(jsonEncode('not-a-map'));

      final outputPath = '${tempDir.path}/settings.json';

      expect(
        () => exporter.export(outputPath),
        throwsA(isA<TypeError>()),
      );

      expect(fileAt(outputPath).existsSync(), isFalse);
    });

    test('export throws FileSystemException when parent directory does not exist', () async {
      insertSettingsJson({
        'formatVersion': 1,
        'settings': {},
      });

      final outputPath = '${tempDir.path}/does_not_exist/settings.json';

      expect(
        () => exporter.export(outputPath),
        throwsA(isA<FileSystemException>()),
      );
    });

    // -------------------------------------------------------------------------
    // Overwrite / repeated export behavior
    // -------------------------------------------------------------------------

    test('export overwrites existing file contents', () async {
      final storedJson = {
        'formatVersion': 1,
        'settings': {},
      };

      insertSettingsJson(storedJson);

      final outputPath = '${tempDir.path}/settings.json';

      File(outputPath).writeAsStringSync('old contents');

      await exporter.export(outputPath);

      expect(readFile(outputPath), isNot('old contents'));

      expectValidSignedJsonFile(
        path: outputPath,
        expectedPayload: storedJson,
      );
    });

    test('export can be called repeatedly and rewrites file each time', () async {
      final firstJson = {
        'formatVersion': 1,
        'settings': {
          'scanner': {
            'targetTable': 'first_table',
          },
        },
      };

      insertSettingsJson(firstJson);

      final outputPath = '${tempDir.path}/settings.json';

      await exporter.export(outputPath);

      expectValidSignedJsonFile(
        path: outputPath,
        expectedPayload: firstJson,
      );

      final secondJson = {
        'formatVersion': 1,
        'settings': {
          'scanner': {
            'targetTable': 'second_table',
          },
        },
      };

      db.execute(
        '''
        UPDATE __project_settings
        SET settings_json = ?
        WHERE id = 1
        ''',
        [jsonEncode(secondJson)],
      );

      await exporter.export(outputPath);

      expectValidSignedJsonFile(
        path: outputPath,
        expectedPayload: secondJson,
      );
    });

    test('export creates non-empty file when row exists', () async {
      final storedJson = {
        'formatVersion': 1,
        'settings': {},
      };

      insertSettingsJson(storedJson);

      final outputPath = '${tempDir.path}/settings.json';

      await exporter.export(outputPath);

      final file = File(outputPath);

      expect(file.existsSync(), isTrue);
      expect(file.lengthSync(), greaterThan(0));
    });
  });
}