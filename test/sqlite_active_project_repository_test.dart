import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:ui_prototype/infrastructure/project/sqlite/sqlite_table_repository.dart';

void main() {
  late Database db;
  late SqliteActiveProjectRepository repo;

  setUp(() {
    db = sqlite3.openInMemory();
    repo = SqliteActiveProjectRepository(db: db);

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
  });
}
