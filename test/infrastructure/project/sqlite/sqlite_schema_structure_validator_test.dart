import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:ui_prototype/infrastructure/project/sqlite/sqlite_schema_structure_validator.dart';

void main() {
  group('SqliteSchemaStructureValidator', () {
    late SqliteSchemaStructureValidator validator;

    setUp(() {
      validator = SqliteSchemaStructureValidator();
    });

    test('returns false for empty statement list', () async {
      final result = await validator.isValid([]);

      expect(result, isFalse);
    });

    test('returns true for single table with no relationships', () async {
      final result = await validator.isValid([
        '''
        CREATE TABLE Trip (
          id INTEGER PRIMARY KEY,
          name TEXT
        );
        ''',
      ]);

      expect(result, isTrue);
    });

    test('returns true for two table linear schema', () async {
      final result = await validator.isValid([
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

      expect(result, isTrue);
    });

    test('returns true for three table linear schema', () async {
      final result = await validator.isValid([
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
          FOREIGN KEY (sample_id) REFERENCES Sample(id)
        );
        ''',
      ]);

      expect(result, isTrue);
    });

    test('returns true for four table linear schema', () async {
      final result = await validator.isValid([
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
          FOREIGN KEY (sample_id) REFERENCES Sample(id)
        );
        ''',
        '''
        CREATE TABLE Measurement (
          id INTEGER PRIMARY KEY,
          specimen_id INTEGER,
          FOREIGN KEY (specimen_id) REFERENCES Specimen(id)
        );
        ''',
      ]);

      expect(result, isTrue);
    });

    test('returns false for two disconnected tables', () async {
      final result = await validator.isValid([
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

      expect(result, isFalse);
    });

    test('returns false for three disconnected tables', () async {
      final result = await validator.isValid([
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
        '''
        CREATE TABLE Specimen (
          id INTEGER PRIMARY KEY
        );
        ''',
      ]);

      expect(result, isFalse);
    });

    test('returns false when one root has two children', () async {
      final result = await validator.isValid([
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
        CREATE TABLE Site (
          id INTEGER PRIMARY KEY,
          trip_id INTEGER,
          FOREIGN KEY (trip_id) REFERENCES Trip(id)
        );
        ''',
      ]);

      expect(result, isFalse);
    });

    test('returns false when one table has two parents', () async {
      final result = await validator.isValid([
        '''
        CREATE TABLE Trip (
          id INTEGER PRIMARY KEY
        );
        ''',
        '''
        CREATE TABLE Site (
          id INTEGER PRIMARY KEY
        );
        ''',
        '''
        CREATE TABLE Sample (
          id INTEGER PRIMARY KEY,
          trip_id INTEGER,
          site_id INTEGER,
          FOREIGN KEY (trip_id) REFERENCES Trip(id),
          FOREIGN KEY (site_id) REFERENCES Site(id)
        );
        ''',
      ]);

      expect(result, isFalse);
    });

    test('returns false for diamond shaped schema', () async {
      final result = await validator.isValid([
        '''
        CREATE TABLE Root (
          id INTEGER PRIMARY KEY
        );
        ''',
        '''
        CREATE TABLE LeftChild (
          id INTEGER PRIMARY KEY,
          root_id INTEGER,
          FOREIGN KEY (root_id) REFERENCES Root(id)
        );
        ''',
        '''
        CREATE TABLE RightChild (
          id INTEGER PRIMARY KEY,
          root_id INTEGER,
          FOREIGN KEY (root_id) REFERENCES Root(id)
        );
        ''',
        '''
        CREATE TABLE Leaf (
          id INTEGER PRIMARY KEY,
          left_child_id INTEGER,
          right_child_id INTEGER,
          FOREIGN KEY (left_child_id) REFERENCES LeftChild(id),
          FOREIGN KEY (right_child_id) REFERENCES RightChild(id)
        );
        ''',
      ]);

      expect(result, isFalse);
    });

    test('returns false for disconnected valid chains', () async {
      final result = await validator.isValid([
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
        CREATE TABLE Site (
          id INTEGER PRIMARY KEY
        );
        ''',
        '''
        CREATE TABLE Visit (
          id INTEGER PRIMARY KEY,
          site_id INTEGER,
          FOREIGN KEY (site_id) REFERENCES Site(id)
        );
        ''',
      ]);

      expect(result, isFalse);
    });

    test('returns false for one valid chain plus one disconnected table', () async {
      final result = await validator.isValid([
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
        CREATE TABLE Disconnected (
          id INTEGER PRIMARY KEY
        );
        ''',
      ]);

      expect(result, isFalse);
    });

    test('returns false for self-referencing table', () async {
      final result = await validator.isValid([
        '''
        CREATE TABLE Node (
          id INTEGER PRIMARY KEY,
          parent_id INTEGER,
          FOREIGN KEY (parent_id) REFERENCES Node(id)
        );
        ''',
      ]);

      expect(result, isFalse);
    });

    test('returns false for two table cycle', () async {
      final result = await validator.isValid([
        '''
        CREATE TABLE A (
          id INTEGER PRIMARY KEY,
          b_id INTEGER,
          FOREIGN KEY (b_id) REFERENCES B(id)
        );
        ''',
        '''
        CREATE TABLE B (
          id INTEGER PRIMARY KEY,
          a_id INTEGER,
          FOREIGN KEY (a_id) REFERENCES A(id)
        );
        ''',
      ]);

      expect(result, isFalse);
    });

    test('returns false for three table cycle', () async {
      final result = await validator.isValid([
        '''
        CREATE TABLE A (
          id INTEGER PRIMARY KEY,
          c_id INTEGER,
          FOREIGN KEY (c_id) REFERENCES C(id)
        );
        ''',
        '''
        CREATE TABLE B (
          id INTEGER PRIMARY KEY,
          a_id INTEGER,
          FOREIGN KEY (a_id) REFERENCES A(id)
        );
        ''',
        '''
        CREATE TABLE C (
          id INTEGER PRIMARY KEY,
          b_id INTEGER,
          FOREIGN KEY (b_id) REFERENCES B(id)
        );
        ''',
      ]);

      expect(result, isFalse);
    });

    test('returns true for linear schema declared from leaf to root', () async {
      final result = await validator.isValid([
        '''
        CREATE TABLE Specimen (
          id INTEGER PRIMARY KEY,
          sample_id INTEGER,
          FOREIGN KEY (sample_id) REFERENCES Sample(id)
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
        CREATE TABLE Trip (
          id INTEGER PRIMARY KEY
        );
        ''',
      ]);

      expect(result, isTrue);
    });

    test('returns true for linear schema with custom primary key names', () async {
      final result = await validator.isValid([
        '''
        CREATE TABLE Trip (
          trip_code TEXT PRIMARY KEY
        );
        ''',
        '''
        CREATE TABLE Sample (
          sample_code TEXT PRIMARY KEY,
          trip_code TEXT,
          FOREIGN KEY (trip_code) REFERENCES Trip(trip_code)
        );
        ''',
        '''
        CREATE TABLE Specimen (
          specimen_code TEXT PRIMARY KEY,
          sample_code TEXT,
          FOREIGN KEY (sample_code) REFERENCES Sample(sample_code)
        );
        ''',
      ]);

      expect(result, isTrue);
    });

    test('returns true for linear schema with composite primary key referenced by one foreign key entry per column', () async {
      final result = await validator.isValid([
        '''
        CREATE TABLE Trip (
          trip_id INTEGER,
          site_id INTEGER,
          PRIMARY KEY (trip_id, site_id)
        );
        ''',
        '''
        CREATE TABLE Sample (
          id INTEGER PRIMARY KEY,
          trip_id INTEGER,
          site_id INTEGER,
          FOREIGN KEY (trip_id, site_id) REFERENCES Trip(trip_id, site_id)
        );
        ''',
      ]);

      expect(result, isTrue);
    });

    test('returns false for tree with composite foreign keys to same parent and another child', () async {
      final result = await validator.isValid([
        '''
        CREATE TABLE Trip (
          trip_id INTEGER,
          site_id INTEGER,
          PRIMARY KEY (trip_id, site_id)
        );
        ''',
        '''
        CREATE TABLE Sample (
          id INTEGER PRIMARY KEY,
          trip_id INTEGER,
          site_id INTEGER,
          FOREIGN KEY (trip_id, site_id) REFERENCES Trip(trip_id, site_id)
        );
        ''',
        '''
        CREATE TABLE Visit (
          id INTEGER PRIMARY KEY,
          trip_id INTEGER,
          site_id INTEGER,
          FOREIGN KEY (trip_id, site_id) REFERENCES Trip(trip_id, site_id)
        );
        ''',
      ]);

      expect(result, isFalse);
    });

    test('ignores __project_settings table when validating graph', () async {
      final result = await validator.isValid([
        '''
        CREATE TABLE Trip (
          id INTEGER PRIMARY KEY
        );
        ''',
        '''
        CREATE TABLE __project_settings (
          id INTEGER PRIMARY KEY,
          settings_json TEXT NOT NULL
        );
        ''',
      ]);

      expect(result, isTrue);
    });

    test('ignores sqlite internal autoincrement table when validating graph', () async {
      final result = await validator.isValid([
        '''
        CREATE TABLE Trip (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT
        );
        ''',
      ]);

      expect(result, isTrue);
    });

    test('returns true for linear schema with quoted table names containing spaces', () async {
      final result = await validator.isValid([
        '''
        CREATE TABLE "Trip Data" (
          id INTEGER PRIMARY KEY
        );
        ''',
        '''
        CREATE TABLE "Sample Data" (
          id INTEGER PRIMARY KEY,
          trip_id INTEGER,
          FOREIGN KEY (trip_id) REFERENCES "Trip Data"(id)
        );
        ''',
      ]);

      expect(result, isTrue);
    });

    test('returns true for linear schema with quoted column names containing spaces', () async {
      final result = await validator.isValid([
        '''
        CREATE TABLE Trip (
          "trip id" INTEGER PRIMARY KEY
        );
        ''',
        '''
        CREATE TABLE Sample (
          "sample id" INTEGER PRIMARY KEY,
          "trip id" INTEGER,
          FOREIGN KEY ("trip id") REFERENCES Trip("trip id")
        );
        ''',
      ]);

      expect(result, isTrue);
    });

    test('throws SqliteException for invalid SQL statement', () async {
      await expectLater(
        () => validator.isValid([
          '''
          CREATE TABLE Trip (
            id INTEGER PRIMARY KEY
          );
          ''',
          'THIS IS NOT VALID SQL;',
        ]),
        throwsA(isA<SqliteException>()),
      );
    });

    test('throws SqliteException for duplicate table names', () async {
      await expectLater(
        () => validator.isValid([
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

    test('returns false for schema containing only __project_settings table', () async {
      final result = await validator.isValid([
        '''
        CREATE TABLE __project_settings (
          id INTEGER PRIMARY KEY,
          settings_json TEXT NOT NULL
        );
        ''',
      ]);

      expect(result, isFalse);
    });

    test('returns false for schema containing only sqlite sequence side effect with no user tables', () async {
      final result = await validator.isValid([
        '''
        CREATE TABLE __project_settings (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          settings_json TEXT NOT NULL
        );
        ''',
      ]);

      expect(result, isFalse);
    });
  });
}