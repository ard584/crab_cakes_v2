import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqlite3/sqlite3.dart';

import 'package:crab_cakes/infrastructure/project/sqlite_database_connection.dart';

void main() {
  group('SqliteDatabaseConnection', () {
    late Directory tempDir;
    late SqliteDatabaseConnection connection;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync(
        'sqlite_database_connection_test_',
      );

      connection = SqliteDatabaseConnection();
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    String createTempDbFile({
      String fileName = 'test.sqlite',
    }) {
      final dbPath = path.join(tempDir.path, fileName);

      final db = sqlite3.open(dbPath);
      try {
        db.execute('''
          CREATE TABLE Parent (
            id INTEGER PRIMARY KEY
          );
        ''');

        db.execute('''
          CREATE TABLE Child (
            id INTEGER PRIMARY KEY,
            parent_id INTEGER,
            FOREIGN KEY (parent_id) REFERENCES Parent(id)
          );
        ''');
      } finally {
        db.dispose();
      }

      return dbPath;
    }

    test('open returns a Database for an existing sqlite file', () {
      final dbPath = createTempDbFile();

      final db = connection.open(dbPath);

      try {
        expect(db, isA<Database>());
        expect(db.select('SELECT 1 AS value').first['value'], 1);
      } finally {
        db.dispose();
      }
    });

    test('open enables foreign keys on returned database', () {
      final dbPath = createTempDbFile();

      final db = connection.open(dbPath);

      try {
        final result = db.select('PRAGMA foreign_keys;');
        expect(result.first['foreign_keys'], 1);
      } finally {
        db.dispose();
      }
    });

    test('open enforces foreign key constraints after enabling foreign keys', () {
      final dbPath = createTempDbFile();

      final db = connection.open(dbPath);

      try {
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

    test('open allows valid foreign key insert after enabling foreign keys', () {
      final dbPath = createTempDbFile();

      final db = connection.open(dbPath);

      try {
        db.execute('INSERT INTO Parent (id) VALUES (1);');

        expect(
          () => db.execute('''
            INSERT INTO Child (id, parent_id)
            VALUES (1, 1);
          '''),
          returnsNormally,
        );

        final rows = db.select('SELECT COUNT(*) AS count FROM Child;');
        expect(rows.first['count'], 1);
      } finally {
        db.dispose();
      }
    });

    test('open throws for empty database path', () {
      expect(
        () => connection.open(''),
        throwsException,
      );
    });

    test('open throws for path that does not exist', () {
      final dbPath = path.join(tempDir.path, 'missing.sqlite');

      expect(
        () => connection.open(dbPath),
        throwsException,
      );
    });

    test('open throws for filename containing less-than character', () {
      final dbPath = path.join(tempDir.path, 'bad<name.sqlite');

      expect(
        () => connection.open(dbPath),
        throwsException,
      );
    });

    test('open throws for filename containing greater-than character', () {
      final dbPath = path.join(tempDir.path, 'bad>name.sqlite');

      expect(
        () => connection.open(dbPath),
        throwsException,
      );
    });

    test('open throws for filename containing colon character', () {
      final dbPath = path.join(tempDir.path, 'bad:name.sqlite');

      expect(
        () => connection.open(dbPath),
        throwsException,
      );
    });

    test('open throws for filename containing quote character', () {
      final dbPath = path.join(tempDir.path, 'bad"name.sqlite');

      expect(
        () => connection.open(dbPath),
        throwsException,
      );
    });

    test('open throws for filename containing pipe character', () {
      final dbPath = path.join(tempDir.path, 'bad|name.sqlite');

      expect(
        () => connection.open(dbPath),
        throwsException,
      );
    });

    test('open throws for filename containing question mark character', () {
      final dbPath = path.join(tempDir.path, 'bad?name.sqlite');

      expect(
        () => connection.open(dbPath),
        throwsException,
      );
    });

    test('open throws for filename containing asterisk character', () {
      final dbPath = path.join(tempDir.path, 'bad*name.sqlite');

      expect(
        () => connection.open(dbPath),
        throwsException,
      );
    });

    test('open accepts normal filename with underscores', () {
      final dbPath = createTempDbFile(
        fileName: 'valid_database_name.sqlite',
      );

      final db = connection.open(dbPath);

      try {
        expect(db.select('SELECT 1 AS value').first['value'], 1);
      } finally {
        db.dispose();
      }
    });

    test('open accepts normal filename with hyphens', () {
      final dbPath = createTempDbFile(
        fileName: 'valid-database-name.sqlite',
      );

      final db = connection.open(dbPath);

      try {
        expect(db.select('SELECT 1 AS value').first['value'], 1);
      } finally {
        db.dispose();
      }
    });

    test('open accepts normal filename with numbers', () {
      final dbPath = createTempDbFile(
        fileName: 'database_2026.sqlite',
      );

      final db = connection.open(dbPath);

      try {
        expect(db.select('SELECT 1 AS value').first['value'], 1);
      } finally {
        db.dispose();
      }
    });

    test('open accepts filename with spaces', () {
      final dbPath = createTempDbFile(
        fileName: 'database with spaces.sqlite',
      );

      final db = connection.open(dbPath);

      try {
        expect(db.select('SELECT 1 AS value').first['value'], 1);
      } finally {
        db.dispose();
      }
    });

    test('open accepts .db extension', () {
      final dbPath = createTempDbFile(
        fileName: 'test.db',
      );

      final db = connection.open(dbPath);

      try {
        expect(db.select('SELECT 1 AS value').first['value'], 1);
      } finally {
        db.dispose();
      }
    });

    test('open accepts .sqlite3 extension', () {
      final dbPath = createTempDbFile(
        fileName: 'test.sqlite3',
      );

      final db = connection.open(dbPath);

      try {
        expect(db.select('SELECT 1 AS value').first['value'], 1);
      } finally {
        db.dispose();
      }
    });

    test('open accepts file with no extension if it exists and is sqlite', () {
      final dbPath = createTempDbFile(
        fileName: 'database_file',
      );

      final db = connection.open(dbPath);

      try {
        expect(db.select('SELECT 1 AS value').first['value'], 1);
      } finally {
        db.dispose();
      }
    });

    test('open can read existing table from sqlite file', () {
      final dbPath = createTempDbFile();

      final db = connection.open(dbPath);

      try {
        final tables = db.select('''
          SELECT name
          FROM sqlite_master
          WHERE type = 'table'
          ORDER BY name;
        ''');

        final tableNames = tables.map((row) => row['name'] as String).toList();

        expect(tableNames, ['Child', 'Parent']);
      } finally {
        db.dispose();
      }
    });

    test('open can be called multiple times on same path when previous database is disposed', () {
      final dbPath = createTempDbFile();

      final firstDb = connection.open(dbPath);
      firstDb.dispose();

      final secondDb = connection.open(dbPath);

      try {
        expect(secondDb.select('SELECT 1 AS value').first['value'], 1);
      } finally {
        secondDb.dispose();
      }
    });

    test('open returns independent database handles for same path', () {
      final dbPath = createTempDbFile();

      final firstDb = connection.open(dbPath);
      final secondDb = connection.open(dbPath);

      try {
        firstDb.execute('INSERT INTO Parent (id) VALUES (1);');

        final rows = secondDb.select('SELECT COUNT(*) AS count FROM Parent;');

        expect(rows.first['count'], 1);
      } finally {
        firstDb.dispose();
        secondDb.dispose();
      }
    });

    test('open throws when existing file is not a sqlite database', () {
      final badFilePath = path.join(tempDir.path, 'not_a_database.sqlite');

      File(badFilePath).writeAsStringSync('this is not sqlite data');

      expect(
        () {
          final db = connection.open(badFilePath);

          try {
            db.select('SELECT name FROM sqlite_master;');
          } finally {
            db.dispose();
          }
        },
        throwsA(isA<SqliteException>()),
      );
    });

    test('open wraps validation errors with path retrieval message', () {
      final dbPath = path.join(tempDir.path, 'missing.sqlite');

      expect(
        () => connection.open(dbPath),
        throwsA(
          predicate(
            (error) =>
                error is Exception &&
                error.toString().contains(
                      'Error occurred retrieving database path',
                    ),
          ),
        ),
      );
    });

    test('open does not create missing database file', () {
      final dbPath = path.join(tempDir.path, 'missing.sqlite');

      expect(
        () => connection.open(dbPath),
        throwsException,
      );

      expect(File(dbPath).existsSync(), isFalse);
    });
  });
}