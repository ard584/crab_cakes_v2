import 'package:crab_cakes/infrastructure/project/sqlite/sql_statement_parser.dart';
import 'package:flutter_test/flutter_test.dart';

var parser = SqlSchemaParser();

void main() {
  group('SqlSchemaParser', () {
    test('Verify 2 statements are properly split and formatted', () {
      String sql1 = '''
        CREATE TABLE trip (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        notes TEXT,
        workers TEXT
        );''';

      String sql2 = '''
        CREATE TABLE specimen (
        id INTEGER PRIMARY KEY,
        species TEXT,
        length REAL,
        fork_length REAL,
        trip_id INTEGER REFERENCES trip(id)
        );
      ''';

      String sql = sql1 + sql2;

      final statements = parser.getStatements(sql);
      expect(
        statements[0],
        sql1
            .trim()
            .toUpperCase()
            .replaceAll("\n", "")
            .replaceAll(";", "")
            .replaceAll(RegExp(r'\s+'), ' '),
      );

      expect(
        statements[1],
        sql2
            .trim()
            .toUpperCase()
            .replaceAll("\n", "")
            .replaceAll(";", "")
            .replaceAll(RegExp(r'\s+'), ' '),
      );
    });

    test('4 statement test', () {
      String sql1 = '''
        CREATE TABLE trip (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        notes TEXT,
        workers TEXT
        );''';

      String sql2 = '''
        CREATE TABLE specimen (
        id INTEGER PRIMARY KEY,
        species TEXT,
        length REAL,
        fork_length REAL,
        trip_id INTEGER REFERENCES trip(id)
        );
      ''';

      String sql3 = '''
        CREATE TABLE batch (
        id INTEGER PRIMARY KEY,
        river_mile REAL,
        batch_type TEXT,
        trip_id INTEGER REFERENCES trip(id)
        );
      ''';

      String sql4 = '''
        CREATE TABLE electrofishing (
        id INTEGER PRIMARY KEY,
        voltage REAL,
        time_electrified REAL,
        trip_id INTEGER REFERENCES trip(id)
        );
      ''';

      String sql = sql1 + sql2 + sql3 + sql4;

      final statements = parser.getStatements(sql);
      expect(statements.length, 4);
    });

    test("Shouldn't split on quotes inside of string", () {
      final sql1 =
          "INSERT INTO tags (name) VALUES ('semicolon; inside string');";
      final sql2 = 'CREATE TABLE "quoted;table" (id INT);';

      final sql = sql1 + sql2;

      final statements = parser.getStatements(sql);
      expect(statements.length, 2);
      expect(statements[0], contains("semicolon; inside string".toUpperCase()));
      expect(statements[1], contains('"quoted;table"'.toUpperCase()));
    });

    test('Should strip comments but preserve string content', () {
      final sql = '''
    -- This is a top-level comment
    CREATE TABLE test (
      id INT, -- inline comment
      msg TEXT -- 'this looks like a string'
    );
    /* Block 
       comment */
    INSERT INTO test (msg) VALUES ('Keep -- this');
  ''';

      final statements = parser.getStatements(sql);

      expect(statements.length, 2);
      expect(statements[0], "CREATE TABLE TEST ( ID INT, MSG TEXT )");
      expect(statements[1], "INSERT INTO TEST (MSG) VALUES ('KEEP -- THIS')");
    });

    test('Should normalize varied whitespace and casing', () {
      final sql = "  create   table\n\ntest\t(id INT)  ;  ";

      final statements = parser.getStatements(sql);

      expect(statements[0], "CREATE TABLE TEST (ID INT)");
    });

    test('Should handle empty input or multiple semicolons', () {
      expect(parser.getStatements(""), isEmpty);
      expect(parser.getStatements(";;;"), isEmpty);
      expect(parser.getStatements("  \n  "), isEmpty);
    });

    test('Handle escaped single quotes inside strings', () {
      // A single statement where a string contains an escaped quote and a semicolon
      final sql =
          "INSERT INTO logs (msg) VALUES ('It''s a semicolon; right here');";

      final statements = parser.getStatements(sql);

      expect(statements.length, 1);
      expect(
        statements[0],
        contains("VALUES ('IT''S A SEMICOLON; RIGHT HERE')"),
      );
    });

    test('Handle escaped double quotes inside strings', () {
      // A single statement where a string contains an escaped quote and a semicolon
      final sql =
          'INSERT INTO logs (msg) VALUES ("It""s a semicolon; right here");';

      final statements = parser.getStatements(sql);

      expect(statements.length, 1);
      expect(
        statements[0],
        contains('VALUES ("IT\"\"S A SEMICOLON; RIGHT HERE")'),
      );
    });

    test('Handle multiple escaped single and double quotes inside strings', () {
      // A single statement where a string contains an escaped quote and a semicolon
      final sql =
          'INSERT INTO logs (msg) VALUES ("It""s a sem""ico\'\'lon; r""ight here");';

      final statements = parser.getStatements(sql);

      expect(statements.length, 1);
      expect(
        statements[0],
        contains(
          'VALUES ("It""s a sem""ico\'\'lon; r""ight here")'.toUpperCase(),
        ),
      );
    });

    test(
      'Should handle SQLite specific identifiers like brackets and backticks',
      () {
        final sql =
            "CREATE TABLE [Table;1] (id INT); CREATE TABLE `Table;2` (id INT);";

        final statements = parser.getStatements(sql);

        expect(statements.length, 2);
        expect(statements[0], contains("[TABLE;1]"));
        expect(statements[1], contains("`TABLE;2`"));
      },
    );

    test("Should allow for single-line comment syntax inside of backtick-defined identifier", () {

      final sql = "CREATE TABLE `-- This is a single line comment being used as a table name` (id INT);";
      final statements = parser.getStatements(sql);

      expect(statements.length, 1);
      expect(statements[0], contains("-- This is a single line comment".toUpperCase()));

    });

    test("Should allow for single-line comment syntax inside of bracket-defined identifier", () {

      final sql = "CREATE TABLE [-- This is a single line comment being used as a table name] (id INT);";
      final statements = parser.getStatements(sql);

      expect(statements.length, 1);
      expect(statements[0], contains("-- This is a single line comment".toUpperCase()));

    });
  });
}
