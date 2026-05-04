import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqlite3/sqlite3.dart';

import 'package:crab_cakes/infrastructure/backup/sqlite_db_backup_writer.dart';

void main() {
  group('SqliteDbBackupWriter', () {
    late Directory tempDir;
    late SqliteDbBackupWriter writer;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync(
        'sqlite_db_backup_writer_test_',
      );

      writer = SqliteDbBackupWriter();
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    String sourcePath([String fileName = 'source.sqlite']) {
      return path.join(tempDir.path, fileName);
    }

    String destinationPath([String fileName = 'backup.sqlite']) {
      return path.join(tempDir.path, 'backups', fileName);
    }

    String createSourceDb({
      String fileName = 'source.sqlite',
      bool insertRows = true,
    }) {
      final dbPath = sourcePath(fileName);
      final db = sqlite3.open(dbPath);

      try {
        db.execute('PRAGMA foreign_keys = ON;');

        db.execute('''
          CREATE TABLE Trip (
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL
          );
        ''');

        db.execute('''
          CREATE TABLE Sample (
            id INTEGER PRIMARY KEY,
            trip_id INTEGER NOT NULL,
            sample_name TEXT,
            FOREIGN KEY (trip_id) REFERENCES Trip(id)
          );
        ''');

        if (insertRows) {
          db.execute("INSERT INTO Trip (id, name) VALUES (1, 'Trip A');");
          db.execute("INSERT INTO Trip (id, name) VALUES (2, 'Trip B');");

          db.execute(
            "INSERT INTO Sample (id, trip_id, sample_name) VALUES (10, 1, 'Sample A');",
          );
        }
      } finally {
        db.dispose();
      }

      return dbPath;
    }

    List<String> tableNames(String dbPath) {
      final db = sqlite3.open(dbPath);

      try {
        final rows = db.select('''
          SELECT name
          FROM sqlite_master
          WHERE type = 'table'
          ORDER BY name;
        ''');

        return rows.map((row) => row['name'] as String).toList();
      } finally {
        db.dispose();
      }
    }

    int countRows(String dbPath, String tableName) {
      final db = sqlite3.open(dbPath);

      try {
        final rows = db.select('SELECT COUNT(*) AS count FROM $tableName;');
        return rows.first['count'] as int;
      } finally {
        db.dispose();
      }
    }

    String integrityCheck(String dbPath) {
      final db = sqlite3.open(dbPath);

      try {
        final result = db.select('PRAGMA integrity_check;');
        return result.first.values.first.toString();
      } finally {
        db.dispose();
      }
    }

    test('creates destination backup database file', () async {
      final src = createSourceDb();
      final dest = destinationPath();

      await writer.writeDatabaseBackup(
        sourceDbPath: src,
        destinationDbPath: dest,
      );

      expect(File(dest).existsSync(), isTrue);
    });

    test('creates destination parent directory when missing', () async {
      final src = createSourceDb();
      final dest = destinationPath('nested/backup.sqlite');

      expect(Directory(path.dirname(dest)).existsSync(), isFalse);

      await writer.writeDatabaseBackup(
        sourceDbPath: src,
        destinationDbPath: dest,
      );

      expect(Directory(path.dirname(dest)).existsSync(), isTrue);
      expect(File(dest).existsSync(), isTrue);
    });

    test('backup file is non-empty', () async {
      final src = createSourceDb();
      final dest = destinationPath();

      await writer.writeDatabaseBackup(
        sourceDbPath: src,
        destinationDbPath: dest,
      );

      expect(File(dest).lengthSync(), greaterThan(0));
    });

    test('backup passes sqlite integrity check', () async {
      final src = createSourceDb();
      final dest = destinationPath();

      await writer.writeDatabaseBackup(
        sourceDbPath: src,
        destinationDbPath: dest,
      );

      expect(integrityCheck(dest).toLowerCase(), 'ok');
    });

    test('backup contains same user tables as source', () async {
      final src = createSourceDb();
      final dest = destinationPath();

      await writer.writeDatabaseBackup(
        sourceDbPath: src,
        destinationDbPath: dest,
      );

      expect(tableNames(dest), tableNames(src));
    });

    test('backup preserves Trip row count', () async {
      final src = createSourceDb();
      final dest = destinationPath();

      await writer.writeDatabaseBackup(
        sourceDbPath: src,
        destinationDbPath: dest,
      );

      expect(countRows(dest, 'Trip'), 2);
    });

    test('backup preserves Sample row count', () async {
      final src = createSourceDb();
      final dest = destinationPath();

      await writer.writeDatabaseBackup(
        sourceDbPath: src,
        destinationDbPath: dest,
      );

      expect(countRows(dest, 'Sample'), 1);
    });

    test('backup preserves row values', () async {
      final src = createSourceDb();
      final dest = destinationPath();

      await writer.writeDatabaseBackup(
        sourceDbPath: src,
        destinationDbPath: dest,
      );

      final db = sqlite3.open(dest);
      try {
        final rows = db.select('SELECT id, name FROM Trip ORDER BY id;');

        expect(rows.length, 2);
        expect(rows[0]['id'], 1);
        expect(rows[0]['name'], 'Trip A');
        expect(rows[1]['id'], 2);
        expect(rows[1]['name'], 'Trip B');
      } finally {
        db.dispose();
      }
    });

    test('throws when source database does not exist', () async {
      final src = sourcePath('missing.sqlite');
      final dest = destinationPath();

      await expectLater(
        () => writer.writeDatabaseBackup(
          sourceDbPath: src,
          destinationDbPath: dest,
        ),
        throwsException,
      );

      expect(File(dest).existsSync(), isFalse);
    });

    test('throws when source path is a directory', () async {
      final srcDir = Directory(sourcePath('source_directory'));
      srcDir.createSync(recursive: true);

      final dest = destinationPath();

      await expectLater(
        () => writer.writeDatabaseBackup(
          sourceDbPath: srcDir.path,
          destinationDbPath: dest,
        ),
        throwsException,
      );

      expect(File(dest).existsSync(), isFalse);
    });

    test('throws when source file is not a sqlite database', () async {
      final src = sourcePath('not_sqlite.sqlite');
      File(src).writeAsStringSync('not sqlite data');

      final dest = destinationPath();

      await expectLater(
        () => writer.writeDatabaseBackup(
          sourceDbPath: src,
          destinationDbPath: dest,
        ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('overwrites existing destination database', () async {
      final firstSource = createSourceDb(fileName: 'source_one.sqlite');

      final secondSource = sourcePath('source_two.sqlite');
      final db = sqlite3.open(secondSource);
      try {
        db.execute('''
          CREATE TABLE DifferentTable (
            id INTEGER PRIMARY KEY,
            value TEXT
          );
        ''');

        db.execute("INSERT INTO DifferentTable (id, value) VALUES (1, 'new');");
      } finally {
        db.dispose();
      }

      final dest = destinationPath();

      await writer.writeDatabaseBackup(
        sourceDbPath: firstSource,
        destinationDbPath: dest,
      );

      expect(tableNames(dest), contains('Trip'));

      await writer.writeDatabaseBackup(
        sourceDbPath: secondSource,
        destinationDbPath: dest,
      );

      expect(tableNames(dest), contains('DifferentTable'));
      expect(tableNames(dest).contains('Trip'), isFalse);
    });

    test('removes stale temp file before writing backup', () async {
      final src = createSourceDb();
      final dest = destinationPath();
      final tempPath = '$dest.tmp';

      Directory(path.dirname(dest)).createSync(recursive: true);
      File(tempPath).writeAsStringSync('stale temp data');

      await writer.writeDatabaseBackup(
        sourceDbPath: src,
        destinationDbPath: dest,
      );

      expect(File(dest).existsSync(), isTrue);
      expect(File(tempPath).existsSync(), isFalse);
      expect(integrityCheck(dest).toLowerCase(), 'ok');
    });

    test('does not leave temp file after successful backup', () async {
      final src = createSourceDb();
      final dest = destinationPath();

      await writer.writeDatabaseBackup(
        sourceDbPath: src,
        destinationDbPath: dest,
      );

      expect(File('$dest.tmp').existsSync(), isFalse);
    });

    test('source database remains usable after backup', () async {
      final src = createSourceDb();
      final dest = destinationPath();

      await writer.writeDatabaseBackup(
        sourceDbPath: src,
        destinationDbPath: dest,
      );

      final db = sqlite3.open(src);
      try {
        db.execute("INSERT INTO Trip (id, name) VALUES (3, 'Trip C');");

        final rows = db.select('SELECT COUNT(*) AS count FROM Trip;');

        expect(rows.first['count'], 3);
      } finally {
        db.dispose();
      }
    });

    test('backup is independent from source after creation', () async {
      final src = createSourceDb();
      final dest = destinationPath();

      await writer.writeDatabaseBackup(
        sourceDbPath: src,
        destinationDbPath: dest,
      );

      final sourceDb = sqlite3.open(src);
      try {
        sourceDb.execute("INSERT INTO Trip (id, name) VALUES (3, 'Trip C');");
      } finally {
        sourceDb.dispose();
      }

      expect(countRows(src, 'Trip'), 3);
      expect(countRows(dest, 'Trip'), 2);
    });

    test('can backup empty database with one table and no rows', () async {
      final src = createSourceDb(insertRows: false);
      final dest = destinationPath();

      await writer.writeDatabaseBackup(
        sourceDbPath: src,
        destinationDbPath: dest,
      );

      expect(File(dest).existsSync(), isTrue);
      expect(tableNames(dest), ['Sample', 'Trip']);
      expect(countRows(dest, 'Trip'), 0);
      expect(countRows(dest, 'Sample'), 0);
    });

    test('can backup database with indexes', () async {
      final src = createSourceDb();
      final db = sqlite3.open(src);

      try {
        db.execute('CREATE INDEX idx_trip_name ON Trip(name);');
      } finally {
        db.dispose();
      }

      final dest = destinationPath();

      await writer.writeDatabaseBackup(
        sourceDbPath: src,
        destinationDbPath: dest,
      );

      final backupDb = sqlite3.open(dest);
      try {
        final rows = backupDb.select('''
          SELECT name
          FROM sqlite_master
          WHERE type = 'index'
          ORDER BY name;
        ''');

        final indexes = rows.map((row) => row['name'] as String).toList();

        expect(indexes, contains('idx_trip_name'));
      } finally {
        backupDb.dispose();
      }
    });

    test('can backup database with triggers', () async {
      final src = createSourceDb();
      final db = sqlite3.open(src);

      try {
        db.execute('''
          CREATE TABLE AuditLog (
            id INTEGER PRIMARY KEY,
            message TEXT
          );
        ''');

        db.execute('''
          CREATE TRIGGER trip_insert_audit
          AFTER INSERT ON Trip
          BEGIN
            INSERT INTO AuditLog (message) VALUES ('trip inserted');
          END;
        ''');
      } finally {
        db.dispose();
      }

      final dest = destinationPath();

      await writer.writeDatabaseBackup(
        sourceDbPath: src,
        destinationDbPath: dest,
      );

      final backupDb = sqlite3.open(dest);
      try {
        final rows = backupDb.select('''
          SELECT name
          FROM sqlite_master
          WHERE type = 'trigger';
        ''');

        expect(rows.map((row) => row['name'] as String), contains('trip_insert_audit'));
      } finally {
        backupDb.dispose();
      }
    });

    test('can backup database with views', () async {
      final src = createSourceDb();
      final db = sqlite3.open(src);

      try {
        db.execute('''
          CREATE VIEW TripNames AS
          SELECT name FROM Trip;
        ''');
      } finally {
        db.dispose();
      }

      final dest = destinationPath();

      await writer.writeDatabaseBackup(
        sourceDbPath: src,
        destinationDbPath: dest,
      );

      final backupDb = sqlite3.open(dest);
      try {
        final rows = backupDb.select('''
          SELECT name
          FROM sqlite_master
          WHERE type = 'view';
        ''');

        expect(rows.map((row) => row['name'] as String), contains('TripNames'));
      } finally {
        backupDb.dispose();
      }
    });

    test('supports destination path with spaces', () async {
      final src = createSourceDb();
      final dest = destinationPath('backup with spaces.sqlite');

      await writer.writeDatabaseBackup(
        sourceDbPath: src,
        destinationDbPath: dest,
      );

      expect(File(dest).existsSync(), isTrue);
      expect(integrityCheck(dest).toLowerCase(), 'ok');
    });

    test('supports destination path containing single quote', () async {
      final src = createSourceDb();
      final dest = destinationPath("backup's copy.sqlite");

      await writer.writeDatabaseBackup(
        sourceDbPath: src,
        destinationDbPath: dest,
      );

      expect(File(dest).existsSync(), isTrue);
      expect(integrityCheck(dest).toLowerCase(), 'ok');
    });

    test('supports source path containing single quote', () async {
      final src = createSourceDb(fileName: "source's db.sqlite");
      final dest = destinationPath('backup.sqlite');

      await writer.writeDatabaseBackup(
        sourceDbPath: src,
        destinationDbPath: dest,
      );

      expect(File(dest).existsSync(), isTrue);
      expect(integrityCheck(dest).toLowerCase(), 'ok');
    });

    test('can run backup multiple times to same destination', () async {
      final src = createSourceDb();
      final dest = destinationPath();

      await writer.writeDatabaseBackup(
        sourceDbPath: src,
        destinationDbPath: dest,
      );

      await writer.writeDatabaseBackup(
        sourceDbPath: src,
        destinationDbPath: dest,
      );

      expect(File(dest).existsSync(), isTrue);
      expect(integrityCheck(dest).toLowerCase(), 'ok');
      expect(countRows(dest, 'Trip'), 2);
    });

    test('can run backup multiple times to different destinations', () async {
      final src = createSourceDb();
      final firstDest = destinationPath('first.sqlite');
      final secondDest = destinationPath('second.sqlite');

      await writer.writeDatabaseBackup(
        sourceDbPath: src,
        destinationDbPath: firstDest,
      );

      await writer.writeDatabaseBackup(
        sourceDbPath: src,
        destinationDbPath: secondDest,
      );

      expect(File(firstDest).existsSync(), isTrue);
      expect(File(secondDest).existsSync(), isTrue);
      expect(integrityCheck(firstDest).toLowerCase(), 'ok');
      expect(integrityCheck(secondDest).toLowerCase(), 'ok');
    });

    test('backup preserves sqlite user_version pragma', () async {
      final src = createSourceDb();
      final db = sqlite3.open(src);

      try {
        db.execute('PRAGMA user_version = 42;');
      } finally {
        db.dispose();
      }

      final dest = destinationPath();

      await writer.writeDatabaseBackup(
        sourceDbPath: src,
        destinationDbPath: dest,
      );

      final backupDb = sqlite3.open(dest);
      try {
        final result = backupDb.select('PRAGMA user_version;');
        expect(result.first.values.first, 42);
      } finally {
        backupDb.dispose();
      }
    });
  });
}