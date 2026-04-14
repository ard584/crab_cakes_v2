import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:ui_prototype/infrastructure/project/sqlite/sql_insert_generator.dart';
import 'package:ui_prototype/infrastructure/project/sqlite/sqlite_active_project_repository.dart';
import 'package:ui_prototype/infrastructure/project/sqlite/sqlite_update_generator.dart';

void main() {
  late Database db;
  late SqliteActiveProjectRepository repo;

  setUp(() {
    db = sqlite3.openInMemory();
    repo = SqliteActiveProjectRepository(
      db: db,
      insert: SQLInsertGenerator(),
      update: SqliteUpdateGenerator(),
    );

    // Make fake table
    db.execute('''
    CREATE TABLE trip (
      id INTEGER PRIMARY KEY,
      workers TEXT NOT NULL,
      type TEXT NOT NULL,
      river_mile REAL
    );
    ''');
  });

  tearDown(() {
    db.dispose();
  });

  group('SqliteActiveProjectRepository', () {
    test('Can successfully retrieve table schema', () {
      // Get schema
      final schema = repo.getTableSchema("trip");

      expect(schema.columnCount, 4);
      expect(schema.columnByName("id"), isNotNull);
      expect(schema.columnByName("workers").nullable, false);
    });

    test('InsertRow can successfully insert into the database', () {
      // Define a value map
      final val1 = {
        "id": 1,
        "workers": "maria, dave, benjamin",
        "type": "electrofishing",
        "river_mile": 0,
      };

      repo.insertRow(tableName: "trip", values: val1);

      final result = db.select("SELECT * FROM trip WHERE id = ?", [val1["id"]]);
      expect(result.rows.length, 1);
      expect(result.rows.first[2], "electrofishing");
    });

    test('getAllRows should return all records', () {
      db.execute('''INSERT INTO trip (workers, type) VALUES 
      ('maria', 'electrofishing'),
      ('dave', 'hoop netting');
      ''');

      final rows = repo.getAllRows("trip");

      expect(rows.length, 2);
      expect(rows[0].values["workers"], "maria");
    });

    test('getRows limit works', () {
      db.execute('''INSERT INTO trip (workers, type) VALUES 
      ('maria', 'electrofishing'),
      ('dave', 'hoop netting'),
      ('ben', 'hoop netting'),
      ('maria', 'hoop netting'),
      ('pilar', 'electrofishing');
      ''');

      final rows = repo.getRows("trip", 2, 0);
      expect(rows.length, 2);
      expect(rows[1].values["id"], 2);
    });

    test('getRows limit and offset works', () {
      db.execute('''INSERT INTO trip (workers, type) VALUES 
      ('maria', 'electrofishing'),
      ('dave', 'hoop netting'),
      ('ben', 'hoop netting'),
      ('maria', 'hoop netting'),
      ('pilar', 'electrofishing');
      ''');

      final rows = repo.getRows("trip", 2, 3);
      expect(rows.length, 2);
      expect(rows[1].values["id"], 5);
    });

    test('insertRow should fail if bad data entered (missing field)', () {
      // Define a value map
      final val1 = {
        "id": 1,
        "workers": "maria, dave, benjamin",
        "river_mile": 0,
      };

      expect(
        () => repo.insertRow(tableName: "trip", values: val1),
        throwsException,
      );
    });

    test('Should return all records if limit exceeds number of records', () {
      db.execute('''INSERT INTO trip (workers, type) VALUES 
      ('maria', 'electrofishing'),
      ('dave', 'hoop netting'),
      ('ben', 'hoop netting'),
      ('maria', 'hoop netting'),
      ('pilar', 'electrofishing');
      ''');

      final rows = repo.getRows("trip", 10, 0);
      expect(rows.length, 5);
      expect(rows[1].values["id"], 2);
    });

    test('dbTable columnAt successfully retrieves a column in range', () {
      final table = repo.getTableSchema("trip");
      final col = table.columnAt(1);

      expect(col.name, "workers");
    });

    test('dbTable columnAt throws error when column out of range (above)', () {
      final table = repo.getTableSchema("trip");
      expect(() => table.columnAt(5), throwsRangeError);
    });

    test('dbTable columnAt throws error when column out of range (below)', () {
      final table = repo.getTableSchema("trip");
      expect(() => table.columnAt(-1), throwsRangeError);
    });

    test('Can successfully get column by name from table', () {
      final table = repo.getTableSchema("trip");
      final col = table.columnByName("workers");

      expect(col.name, "workers");
    });

    test('Throws error when getting column nonexistent by name from table', () {
      final table = repo.getTableSchema("trip");

      expect(() {
        table.columnByName("doesntexist");
      }, throwsException);
    });

    test('Table returns correct index for column by name', () {
      final table = repo.getTableSchema("trip");
      final index = table.columnIndexByName("workers");

      expect(index, 1);
    });

    test(
      'Table throws exception for getting index for nonexistent column by name',
      () {
        final table = repo.getTableSchema("trip");

        expect(() {
          table.columnIndexByName("doesntexist");
        }, throwsRangeError);
      },
    );
  });
}
