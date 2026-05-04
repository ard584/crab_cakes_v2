import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqlite3/sqlite3.dart';

import 'package:ui_prototype/infrastructure/export/sqlite_data_exporter.dart';
import 'package:ui_prototype/infrastructure/providers/column_filter_provider.dart';

void main() {
  group('SqliteDataExporter', () {
    late Directory tempDir;
    late Database db;
    late SqliteDataExporter exporter;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync(
        'sqlite_data_exporter_test_',
      );

      db = sqlite3.openInMemory();
      db.execute('PRAGMA foreign_keys = ON;');

      exporter = SqliteDataExporter(db);
    });

    tearDown(() {
      db.dispose();

      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    String outputPath(String fileName) {
      return path.join(tempDir.path, fileName);
    }

    List<String> readLines(String filePath) {
      return File(filePath).readAsLinesSync();
    }

    String readText(String filePath) {
      return File(filePath).readAsStringSync();
    }

    void createSingleTableSchema() {
      db.execute('''
        CREATE TABLE Trip (
          id INTEGER PRIMARY KEY,
          name TEXT,
          notes TEXT
        );
      ''');
    }

    void createTripSampleSpecimenSchema() {
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
    }

    void insertTripSampleSpecimenRows() {
      db.execute('''
        INSERT INTO Trip (id, trip_name)
        VALUES (1, 'Trip A');
      ''');

      db.execute('''
        INSERT INTO Sample (id, trip_id, sample_name)
        VALUES (10, 1, 'Sample A');
      ''');

      db.execute('''
        INSERT INTO Specimen (id, sample_id, tag_id, length_mm)
        VALUES (100, 10, 'TAG001', 123.45);
      ''');
    }

    test('getTables returns empty list when there are no tables', () async {
      final tables = await exporter.getTables();

      expect(tables, isEmpty);
    });

    test('getTables excludes empty user table', () async {
      createSingleTableSchema();

      final tables = await exporter.getTables();

      expect(tables, isEmpty);
    });

    test('getTables includes table with at least one row', () async {
      createSingleTableSchema();

      db.execute("INSERT INTO Trip (id, name, notes) VALUES (1, 'Trip A', 'Note');");

      final tables = await exporter.getTables();

      expect(tables, ['Trip']);
    });

    test('getTables excludes __project_settings even when it has rows', () async {
      createSingleTableSchema();

      db.execute('''
        CREATE TABLE __project_settings (
          id INTEGER PRIMARY KEY,
          settings_json TEXT NOT NULL
        );
      ''');

      db.execute('''
        INSERT INTO __project_settings (id, settings_json)
        VALUES (1, '{}');
      ''');

      db.execute("INSERT INTO Trip (id, name, notes) VALUES (1, 'Trip A', 'Note');");

      final tables = await exporter.getTables();

      expect(tables, ['Trip']);
      expect(tables.contains('__project_settings'), isFalse);
    });

    test('getTables includes only tables with rows in chain schema', () async {
      createTripSampleSpecimenSchema();

      db.execute("INSERT INTO Trip (id, trip_name) VALUES (1, 'Trip A');");

      final tables = await exporter.getTables();

      expect(tables, ['Trip']);
    });

    test('exports single table header only when table has no rows', () async {
      createSingleTableSchema();

      final filePath = outputPath('single_empty.csv');

      await exporter.export('Trip', filePath, ',');

      final lines = readLines(filePath);

      expect(lines, ['Trip_id,Trip_name,Trip_notes']);
    });

    test('exports single table with one row', () async {
      createSingleTableSchema();

      db.execute("INSERT INTO Trip (id, name, notes) VALUES (1, 'Trip A', 'Note A');");

      final filePath = outputPath('single_one_row.csv');

      await exporter.export('Trip', filePath, ',');

      final lines = readLines(filePath);

      expect(lines, [
        'Trip_id,Trip_name,Trip_notes',
        '1,Trip A,Note A',
      ]);
    });

    test('exports single table with multiple rows', () async {
      createSingleTableSchema();

      db.execute("INSERT INTO Trip (id, name, notes) VALUES (1, 'Trip A', 'Note A');");
      db.execute("INSERT INTO Trip (id, name, notes) VALUES (2, 'Trip B', 'Note B');");

      final filePath = outputPath('single_multiple_rows.csv');

      await exporter.export('Trip', filePath, ',');

      final lines = readLines(filePath);

      expect(lines, [
        'Trip_id,Trip_name,Trip_notes',
        '1,Trip A,Note A',
        '2,Trip B,Note B',
      ]);
    });

    test('exports null values as empty fields', () async {
      createSingleTableSchema();

      db.execute("INSERT INTO Trip (id, name, notes) VALUES (1, 'Trip A', NULL);");

      final filePath = outputPath('null_values.csv');

      await exporter.export('Trip', filePath, ',');

      final lines = readLines(filePath);

      expect(lines, [
        'Trip_id,Trip_name,Trip_notes',
        '1,Trip A,',
      ]);
    });

    test('exports comma-containing values with quotes when delimiter is comma', () async {
      createSingleTableSchema();

      db.execute(
        "INSERT INTO Trip (id, name, notes) VALUES (1, 'Trip A', 'hello, world');",
      );

      final filePath = outputPath('comma_escape.csv');

      await exporter.export('Trip', filePath, ',');

      final lines = readLines(filePath);

      expect(lines, [
        'Trip_id,Trip_name,Trip_notes',
        '1,Trip A,"hello, world"',
      ]);
    });

    test('exports quote-containing values with escaped quotes', () async {
      createSingleTableSchema();

      db.execute(
        "INSERT INTO Trip (id, name, notes) VALUES (1, 'Trip A', 'He said \"hello\"');",
      );

      final filePath = outputPath('quote_escape.csv');

      await exporter.export('Trip', filePath, ',');

      final lines = readLines(filePath);

      expect(lines, [
        'Trip_id,Trip_name,Trip_notes',
        '1,Trip A,"He said ""hello"""',
      ]);
    });

    test('exports newline-containing values with quotes', () async {
      createSingleTableSchema();

      db.execute(
        '''
        INSERT INTO Trip (id, name, notes)
        VALUES (1, 'Trip A', 'Line one
Line two');
        ''',
      );

      final filePath = outputPath('newline_escape.csv');

      await exporter.export('Trip', filePath, ',');

      final text = readText(filePath);

      expect(text, contains('"Line one\nLine two"'));
    });

    test('uses tab delimiter when requested', () async {
      createSingleTableSchema();

      db.execute("INSERT INTO Trip (id, name, notes) VALUES (1, 'Trip A', 'Note A');");

      final filePath = outputPath('tab_export.txt');

      await exporter.export('Trip', filePath, '\t');

      final lines = readLines(filePath);

      expect(lines, [
        'Trip_id\tTrip_name\tTrip_notes',
        '1\tTrip A\tNote A',
      ]);
    });

    test('escapes tab-containing value when delimiter is tab', () async {
      createSingleTableSchema();

      db.execute(
        "INSERT INTO Trip (id, name, notes) VALUES (1, 'Trip A', 'hello\tworld');",
      );

      final filePath = outputPath('tab_escape.txt');

      await exporter.export('Trip', filePath, '\t');

      final lines = readLines(filePath);

      expect(lines, [
        'Trip_id\tTrip_name\tTrip_notes',
        '1\tTrip A\t"hello\tworld"',
      ]);
    });

    test('does not quote comma-containing value when delimiter is tab', () async {
      createSingleTableSchema();

      db.execute(
        "INSERT INTO Trip (id, name, notes) VALUES (1, 'Trip A', 'hello, world');",
      );

      final filePath = outputPath('tab_no_comma_escape.txt');

      await exporter.export('Trip', filePath, '\t');

      final lines = readLines(filePath);

      expect(lines, [
        'Trip_id\tTrip_name\tTrip_notes',
        '1\tTrip A\thello, world',
      ]);
    });

    test('filters hidden/internal columns from export header and rows', () async {
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

      final filePath = outputPath('filtered_columns.csv');

      await exporter.export('Trip', filePath, ',');

      final lines = readLines(filePath);

      expect(lines, [
        'Trip_id,Trip_name',
        '1,Trip A',
      ]);
    });

    test('exports chain from leaf table with ancestors joined', () async {
      createTripSampleSpecimenSchema();
      insertTripSampleSpecimenRows();

      final filePath = outputPath('leaf_export.csv');

      await exporter.export('Specimen', filePath, ',');

      final lines = readLines(filePath);

      expect(lines, [
        'Trip_id,Trip_trip_name,Sample_id,Sample_sample_name,Specimen_id,Specimen_tag_id,Specimen_length_mm',
        '1,Trip A,10,Sample A,100,TAG001,123.45',
      ]);
    });

    test('excludes redundant foreign key columns in chain export', () async {
      createTripSampleSpecimenSchema();
      insertTripSampleSpecimenRows();

      final filePath = outputPath('no_fk_redundancy.csv');

      await exporter.export('Specimen', filePath, ',');

      final header = readLines(filePath).first;

      expect(header.contains('Sample_trip_id'), isFalse);
      expect(header.contains('Specimen_sample_id'), isFalse);
    });

    test('exports chain when selected table is middle table', () async {
      createTripSampleSpecimenSchema();
      insertTripSampleSpecimenRows();

      final filePath = outputPath('middle_export.csv');

      await exporter.export('Sample', filePath, ',');

      final lines = readLines(filePath);

      expect(lines, [
        'Trip_id,Trip_trip_name,Sample_id,Sample_sample_name,Specimen_id,Specimen_tag_id,Specimen_length_mm',
        '1,Trip A,10,Sample A,100,TAG001,123.45',
      ]);
    });

    test('exports chain when selected table is root table', () async {
      createTripSampleSpecimenSchema();
      insertTripSampleSpecimenRows();

      final filePath = outputPath('root_export.csv');

      await exporter.export('Trip', filePath, ',');

      final lines = readLines(filePath);

      expect(lines, [
        'Trip_id,Trip_trip_name,Sample_id,Sample_sample_name,Specimen_id,Specimen_tag_id,Specimen_length_mm',
        '1,Trip A,10,Sample A,100,TAG001,123.45',
      ]);
    });

    test('root export keeps parent row even when descendant is missing', () async {
      createTripSampleSpecimenSchema();

      db.execute("INSERT INTO Trip (id, trip_name) VALUES (1, 'Trip A');");

      final filePath = outputPath('root_missing_descendant.csv');

      await exporter.export('Trip', filePath, ',');

      final lines = readLines(filePath);

      expect(lines, [
        'Trip_id,Trip_trip_name,Sample_id,Sample_sample_name,Specimen_id,Specimen_tag_id,Specimen_length_mm',
        '1,Trip A,,,,,',
      ]);
    });

    test('middle export keeps middle row even when leaf is missing', () async {
      createTripSampleSpecimenSchema();

      db.execute("INSERT INTO Trip (id, trip_name) VALUES (1, 'Trip A');");
      db.execute("INSERT INTO Sample (id, trip_id, sample_name) VALUES (10, 1, 'Sample A');");

      final filePath = outputPath('middle_missing_leaf.csv');

      await exporter.export('Sample', filePath, ',');

      final lines = readLines(filePath);

      expect(lines, [
        'Trip_id,Trip_trip_name,Sample_id,Sample_sample_name,Specimen_id,Specimen_tag_id,Specimen_length_mm',
        '1,Trip A,10,Sample A,,,',
      ]);
    });

    test('leaf export returns only leaf rows with matching ancestors', () async {
      createTripSampleSpecimenSchema();

      db.execute("INSERT INTO Trip (id, trip_name) VALUES (1, 'Trip A');");
      db.execute("INSERT INTO Sample (id, trip_id, sample_name) VALUES (10, 1, 'Sample A');");
      db.execute("INSERT INTO Specimen (id, sample_id, tag_id, length_mm) VALUES (100, 10, 'TAG001', 123.45);");
      db.execute("INSERT INTO Sample (id, trip_id, sample_name) VALUES (20, 1, 'Sample B');");

      final filePath = outputPath('leaf_only_rows.csv');

      await exporter.export('Specimen', filePath, ',');

      final lines = readLines(filePath);

      expect(lines, [
        'Trip_id,Trip_trip_name,Sample_id,Sample_sample_name,Specimen_id,Specimen_tag_id,Specimen_length_mm',
        '1,Trip A,10,Sample A,100,TAG001,123.45',
      ]);
    });

    test('exports multiple leaf rows under same parent chain', () async {
      createTripSampleSpecimenSchema();

      db.execute("INSERT INTO Trip (id, trip_name) VALUES (1, 'Trip A');");
      db.execute("INSERT INTO Sample (id, trip_id, sample_name) VALUES (10, 1, 'Sample A');");
      db.execute("INSERT INTO Specimen (id, sample_id, tag_id, length_mm) VALUES (100, 10, 'TAG001', 123.45);");
      db.execute("INSERT INTO Specimen (id, sample_id, tag_id, length_mm) VALUES (101, 10, 'TAG002', 222.0);");

      final filePath = outputPath('multiple_leaf_rows.csv');

      await exporter.export('Specimen', filePath, ',');

      final lines = readLines(filePath);

      expect(lines, [
        'Trip_id,Trip_trip_name,Sample_id,Sample_sample_name,Specimen_id,Specimen_tag_id,Specimen_length_mm',
        '1,Trip A,10,Sample A,100,TAG001,123.45',
        '1,Trip A,10,Sample A,101,TAG002,222.0',
      ]);
    });

    test('export overwrites existing file contents', () async {
      createSingleTableSchema();

      db.execute("INSERT INTO Trip (id, name, notes) VALUES (1, 'Trip A', 'Note A');");

      final filePath = outputPath('overwrite.csv');

      File(filePath).writeAsStringSync('old contents');

      await exporter.export('Trip', filePath, ',');

      final text = readText(filePath);

      expect(text, isNot('old contents'));
      expect(text, contains('Trip_id,Trip_name,Trip_notes'));
    });

    test('export creates file when path does not exist', () async {
      createSingleTableSchema();

      final filePath = outputPath('new_file.csv');

      await exporter.export('Trip', filePath, ',');

      expect(File(filePath).existsSync(), isTrue);
    });

    test('export throws when table does not exist', () async {
      createSingleTableSchema();

      final filePath = outputPath('missing_table.csv');

      expect(
        () => exporter.export('MissingTable', filePath, ','),
        throwsException,
      );
    });

    test('export throws FileSystemException when parent directory does not exist', () async {
      createSingleTableSchema();

      final filePath = path.join(tempDir.path, 'missing_dir', 'export.csv');

      expect(
        () => exporter.export('Trip', filePath, ','),
        throwsA(isA<FileSystemException>()),
      );
    });
  });
}