import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqlite3/sqlite3.dart';

import 'package:ui_prototype/infrastructure/backup/sqlite_backup_exporter.dart';
import 'package:ui_prototype/infrastructure/providers/column_filter_provider.dart';

void main() {
  group('SqliteBackupExporter', () {
    late Directory tempDir;
    late SqliteBackupExporter exporter;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync(
        'sqlite_backup_exporter_test_',
      );

      exporter = SqliteBackupExporter();
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    String dbPath(String fileName) {
      return path.join(tempDir.path, fileName);
    }

    String outputPath(String fileName) {
      return path.join(tempDir.path, fileName);
    }

    String createSingleTableDb({
      bool insertRows = true,
      String fileName = 'single_table.sqlite',
    }) {
      final sourcePath = dbPath(fileName);
      final db = sqlite3.open(sourcePath);

      try {
        db.execute('''
          CREATE TABLE Trip (
            id INTEGER PRIMARY KEY,
            name TEXT,
            notes TEXT
          );
        ''');

        if (insertRows) {
          db.execute(
            "INSERT INTO Trip (id, name, notes) VALUES (1, 'Trip A', 'Note A');",
          );

          db.execute(
            "INSERT INTO Trip (id, name, notes) VALUES (2, 'Trip B', 'Note B');",
          );
        }
      } finally {
        db.dispose();
      }

      return sourcePath;
    }

    String createChainDb({
      bool insertRows = true,
      String fileName = 'chain.sqlite',
    }) {
      final sourcePath = dbPath(fileName);
      final db = sqlite3.open(sourcePath);

      try {
        db.execute('PRAGMA foreign_keys = ON;');

        db.execute('''
          CREATE TABLE Trip (
            id INTEGER PRIMARY KEY,
            trip_name TEXT
          );
        ''');

        db.execute('''
          CREATE TABLE Sample (
            id INTEGER PRIMARY KEY,
            trip_id INTEGER,
            sample_name TEXT,
            FOREIGN KEY (trip_id) REFERENCES Trip(id)
          );
        ''');

        db.execute('''
          CREATE TABLE Specimen (
            id INTEGER PRIMARY KEY,
            sample_id INTEGER,
            tag_id TEXT,
            length_mm REAL,
            FOREIGN KEY (sample_id) REFERENCES Sample(id)
          );
        ''');

        if (insertRows) {
          db.execute("INSERT INTO Trip (id, trip_name) VALUES (1, 'Trip A');");
          db.execute(
            "INSERT INTO Sample (id, trip_id, sample_name) VALUES (10, 1, 'Sample A');",
          );
          db.execute(
            "INSERT INTO Specimen (id, sample_id, tag_id, length_mm) VALUES (100, 10, 'TAG001', 123.45);",
          );
        }
      } finally {
        db.dispose();
      }

      return sourcePath;
    }

    List<String> readLines(String filePath) {
      return File(filePath).readAsLinesSync();
    }

    String readText(String filePath) {
      return File(filePath).readAsStringSync();
    }

    test('exports single table data to destination file', () async {
      final sourceDbPath = createSingleTableDb();
      final destPath = outputPath('export.csv');

      await exporter.export(
        dbPath: sourceDbPath,
        destPath: destPath,
        baseTable: 'Trip',
        delim: ',',
      );

      expect(File(destPath).existsSync(), isTrue);

      expect(readLines(destPath), [
        'Trip_id,Trip_name,Trip_notes',
        '1,Trip A,Note A',
        '2,Trip B,Note B',
      ]);
    });

    test('exports header only when base table has no rows', () async {
      final sourceDbPath = createSingleTableDb(insertRows: false);
      final destPath = outputPath('empty_export.csv');

      await exporter.export(
        dbPath: sourceDbPath,
        destPath: destPath,
        baseTable: 'Trip',
        delim: ',',
      );

      expect(readLines(destPath), [
        'Trip_id,Trip_name,Trip_notes',
      ]);
    });

    test('exports using tab delimiter', () async {
      final sourceDbPath = createSingleTableDb();
      final destPath = outputPath('export.txt');

      await exporter.export(
        dbPath: sourceDbPath,
        destPath: destPath,
        baseTable: 'Trip',
        delim: '\t',
      );

      expect(readLines(destPath), [
        'Trip_id\tTrip_name\tTrip_notes',
        '1\tTrip A\tNote A',
        '2\tTrip B\tNote B',
      ]);
    });

    test('exports chain data from leaf base table', () async {
      final sourceDbPath = createChainDb();
      final destPath = outputPath('chain_leaf.csv');

      await exporter.export(
        dbPath: sourceDbPath,
        destPath: destPath,
        baseTable: 'Specimen',
        delim: ',',
      );

      expect(readLines(destPath), [
        'Trip_id,Trip_trip_name,Sample_id,Sample_sample_name,Specimen_id,Specimen_tag_id,Specimen_length_mm',
        '1,Trip A,10,Sample A,100,TAG001,123.45',
      ]);
    });

    test('exports chain data from middle base table', () async {
      final sourceDbPath = createChainDb();
      final destPath = outputPath('chain_middle.csv');

      await exporter.export(
        dbPath: sourceDbPath,
        destPath: destPath,
        baseTable: 'Sample',
        delim: ',',
      );

      expect(readLines(destPath), [
        'Trip_id,Trip_trip_name,Sample_id,Sample_sample_name,Specimen_id,Specimen_tag_id,Specimen_length_mm',
        '1,Trip A,10,Sample A,100,TAG001,123.45',
      ]);
    });

    test('exports chain data from root base table', () async {
      final sourceDbPath = createChainDb();
      final destPath = outputPath('chain_root.csv');

      await exporter.export(
        dbPath: sourceDbPath,
        destPath: destPath,
        baseTable: 'Trip',
        delim: ',',
      );

      expect(readLines(destPath), [
        'Trip_id,Trip_trip_name,Sample_id,Sample_sample_name,Specimen_id,Specimen_tag_id,Specimen_length_mm',
        '1,Trip A,10,Sample A,100,TAG001,123.45',
      ]);
    });

    test('filters internal columns from backup export', () async {
      final sourcePath = dbPath('internal_columns.sqlite');
      final db = sqlite3.open(sourcePath);

      try {
        db.execute('''
          CREATE TABLE Trip (
            id INTEGER PRIMARY KEY,
            name TEXT,
            ${kColumnPrefixToHide}row_guid TEXT,
            ${kColumnPrefixToHide}created_at TEXT
          );
        ''');

        db.execute('''
          INSERT INTO Trip (
            id,
            name,
            ${kColumnPrefixToHide}row_guid,
            ${kColumnPrefixToHide}created_at
          )
          VALUES (1, 'Trip A', 'guid-1', '2026-05-03');
        ''');
      } finally {
        db.dispose();
      }

      final destPath = outputPath('filtered.csv');

      await exporter.export(
        dbPath: sourcePath,
        destPath: destPath,
        baseTable: 'Trip',
        delim: ',',
      );

      expect(readLines(destPath), [
        'Trip_id,Trip_name',
        '1,Trip A',
      ]);
    });

    test('escapes comma-containing values when delimiter is comma', () async {
      final sourcePath = dbPath('comma_escape.sqlite');
      final db = sqlite3.open(sourcePath);

      try {
        db.execute('''
          CREATE TABLE Trip (
            id INTEGER PRIMARY KEY,
            notes TEXT
          );
        ''');

        db.execute(
          "INSERT INTO Trip (id, notes) VALUES (1, 'hello, world');",
        );
      } finally {
        db.dispose();
      }

      final destPath = outputPath('comma_escape.csv');

      await exporter.export(
        dbPath: sourcePath,
        destPath: destPath,
        baseTable: 'Trip',
        delim: ',',
      );

      expect(readLines(destPath), [
        'Trip_id,Trip_notes',
        '1,"hello, world"',
      ]);
    });

    test('escapes quote-containing values', () async {
      final sourcePath = dbPath('quote_escape.sqlite');
      final db = sqlite3.open(sourcePath);

      try {
        db.execute('''
          CREATE TABLE Trip (
            id INTEGER PRIMARY KEY,
            notes TEXT
          );
        ''');

        db.execute(
          "INSERT INTO Trip (id, notes) VALUES (1, 'He said \"hello\"');",
        );
      } finally {
        db.dispose();
      }

      final destPath = outputPath('quote_escape.csv');

      await exporter.export(
        dbPath: sourcePath,
        destPath: destPath,
        baseTable: 'Trip',
        delim: ',',
      );

      expect(readLines(destPath), [
        'Trip_id,Trip_notes',
        '1,"He said ""hello"""',
      ]);
    });

    test('escapes newline-containing values', () async {
      final sourcePath = dbPath('newline_escape.sqlite');
      final db = sqlite3.open(sourcePath);

      try {
        db.execute('''
          CREATE TABLE Trip (
            id INTEGER PRIMARY KEY,
            notes TEXT
          );
        ''');

        db.execute('''
          INSERT INTO Trip (id, notes)
          VALUES (1, 'Line one
Line two');
        ''');
      } finally {
        db.dispose();
      }

      final destPath = outputPath('newline_escape.csv');

      await exporter.export(
        dbPath: sourcePath,
        destPath: destPath,
        baseTable: 'Trip',
        delim: ',',
      );

      expect(readText(destPath), contains('"Line one\nLine two"'));
    });

    test('does not quote comma value when delimiter is tab', () async {
      final sourcePath = dbPath('tab_delimiter.sqlite');
      final db = sqlite3.open(sourcePath);

      try {
        db.execute('''
          CREATE TABLE Trip (
            id INTEGER PRIMARY KEY,
            notes TEXT
          );
        ''');

        db.execute(
          "INSERT INTO Trip (id, notes) VALUES (1, 'hello, world');",
        );
      } finally {
        db.dispose();
      }

      final destPath = outputPath('tab_delimiter.txt');

      await exporter.export(
        dbPath: sourcePath,
        destPath: destPath,
        baseTable: 'Trip',
        delim: '\t',
      );

      expect(readLines(destPath), [
        'Trip_id\tTrip_notes',
        '1\thello, world',
      ]);
    });

    test('overwrites existing destination file', () async {
      final sourceDbPath = createSingleTableDb();
      final destPath = outputPath('overwrite.csv');

      File(destPath).writeAsStringSync('old contents');

      await exporter.export(
        dbPath: sourceDbPath,
        destPath: destPath,
        baseTable: 'Trip',
        delim: ',',
      );

      final text = readText(destPath);

      expect(text, isNot('old contents'));
      expect(text, contains('Trip_id,Trip_name,Trip_notes'));
    });

    test('creates destination file when it does not exist', () async {
      final sourceDbPath = createSingleTableDb();
      final destPath = outputPath('new_export.csv');

      await exporter.export(
        dbPath: sourceDbPath,
        destPath: destPath,
        baseTable: 'Trip',
        delim: ',',
      );

      expect(File(destPath).existsSync(), isTrue);
    });

    test('throws when source database path does not exist', () async {
      final sourceDbPath = dbPath('missing.sqlite');
      final destPath = outputPath('should_not_export.csv');

      expect(
        () => exporter.export(
          dbPath: sourceDbPath,
          destPath: destPath,
          baseTable: 'Trip',
          delim: ',',
        ),
        throwsA(isA<FileSystemException>()),
      );
    });

    test('throws when source file is not a sqlite database', () async {
      final sourceDbPath = dbPath('not_sqlite.sqlite');
      final destPath = outputPath('not_sqlite_export.csv');

      File(sourceDbPath).writeAsStringSync('not sqlite data');

      expect(
        () => exporter.export(
          dbPath: sourceDbPath,
          destPath: destPath,
          baseTable: 'Trip',
          delim: ',',
        ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('throws when base table does not exist', () async {
      final sourceDbPath = createSingleTableDb();
      final destPath = outputPath('missing_table.csv');

      expect(
        () => exporter.export(
          dbPath: sourceDbPath,
          destPath: destPath,
          baseTable: 'MissingTable',
          delim: ',',
        ),
        throwsException,
      );
    });

    test('throws when destination parent directory does not exist', () async {
      final sourceDbPath = createSingleTableDb();
      final destPath = path.join(tempDir.path, 'missing_dir', 'export.csv');

      expect(
        () => exporter.export(
          dbPath: sourceDbPath,
          destPath: destPath,
          baseTable: 'Trip',
          delim: ',',
        ),
        throwsA(isA<FileSystemException>()),
      );
    });

    test('source database can be reopened after successful export', () async {
      final sourceDbPath = createSingleTableDb();
      final destPath = outputPath('reopen_after_success.csv');

      await exporter.export(
        dbPath: sourceDbPath,
        destPath: destPath,
        baseTable: 'Trip',
        delim: ',',
      );

      final db = sqlite3.open(sourceDbPath);
      try {
        final count = db.select('SELECT COUNT(*) AS count FROM Trip;').first['count'];
        expect(count, 2);
      } finally {
        db.dispose();
      }
    });

    test('source database can be reopened after failed export', () async {
      final sourceDbPath = createSingleTableDb();
      final destPath = path.join(tempDir.path, 'missing_dir', 'export.csv');

      try {
        await exporter.export(
          dbPath: sourceDbPath,
          destPath: destPath,
          baseTable: 'Trip',
          delim: ',',
        );
      } catch (_) {
        // Expected.
      }

      final db = sqlite3.open(sourceDbPath);
      try {
        final count = db.select('SELECT COUNT(*) AS count FROM Trip;').first['count'];
        expect(count, 2);
      } finally {
        db.dispose();
      }
    });

    test('export does not mutate source database rows', () async {
      final sourceDbPath = createSingleTableDb();
      final destPath = outputPath('no_mutation.csv');

      await exporter.export(
        dbPath: sourceDbPath,
        destPath: destPath,
        baseTable: 'Trip',
        delim: ',',
      );

      final db = sqlite3.open(sourceDbPath);
      try {
        final rows = db.select('SELECT id, name, notes FROM Trip ORDER BY id;');

        expect(rows.length, 2);
        expect(rows[0]['name'], 'Trip A');
        expect(rows[1]['name'], 'Trip B');
      } finally {
        db.dispose();
      }
    });

    test('export works repeatedly to different destination files', () async {
      final sourceDbPath = createSingleTableDb();

      final firstDest = outputPath('first.csv');
      final secondDest = outputPath('second.csv');

      await exporter.export(
        dbPath: sourceDbPath,
        destPath: firstDest,
        baseTable: 'Trip',
        delim: ',',
      );

      await exporter.export(
        dbPath: sourceDbPath,
        destPath: secondDest,
        baseTable: 'Trip',
        delim: '\t',
      );

      expect(File(firstDest).existsSync(), isTrue);
      expect(File(secondDest).existsSync(), isTrue);

      expect(readLines(firstDest).first, 'Trip_id,Trip_name,Trip_notes');
      expect(readLines(secondDest).first, 'Trip_id\tTrip_name\tTrip_notes');
    });
  });
}