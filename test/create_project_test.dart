import 'package:ui_prototype/infrastructure/project/sqlite/sql_security_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final validator = SqlSecurityValidator();

  group('SqlSecurityValidator - isSafe', () {
    test('should allow standard table creation', () {
      final sql = 'CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT);';
      expect(validator.isSafe(sql), isTrue);
    });

    test('should allow keywords inside quoted identifiers', () {
      // Testing if "SELECT" as a column name is ignored by the scanner
      final sql = 'CREATE TABLE orders ("SELECT" TEXT, "FROM" INTEGER);';
      expect(validator.isSafe(sql), isTrue);
    });

    test('should allow keywords inside string literals', () {
      // Testing if keywords inside data values are ignored
      final sql =
          "CREATE TABLE messages (content TEXT DEFAULT 'DROP TABLE users');";
      expect(validator.isSafe(sql), isTrue);
    });

    test('should block forbidden keywords in plain code', () {
      final sql = 'CREATE TABLE x (id INT); DROP TABLE users;';
      expect(validator.isSafe(sql), isFalse);
    });

    test('should block forbidden keywords disguised by case', () {
      final sql = 'create table x (id int); dRoP tAbLe users;';
      expect(validator.isSafe(sql), isFalse);
    });

    test('should block forbidden keywords disguised by multiline comment', () {
      final sql =
          'create table x (id int); dR/* Comment here */oP tAbLe users;';
      expect(validator.isSafe(sql), isFalse);
    });

    test(
      'should block forbidden keywords disguised by single line comment',
      () {
        final sql = 'create table x (id int); dR--\nop tAbLe users;';
        expect(validator.isSafe(sql), isFalse);
      },
    );

    test('should handle comments safely', () {
      // A keyword in a comment shouldn't trigger a failure
      final sql = '''
        CREATE TABLE settings (id INT); 
        -- This next line is a comment and should be ignored
        -- SELECT * FROM secrets;
      ''';
      expect(validator.isSafe(sql), isTrue);
    });

    test('should block PRAGMA tampering', () {
      final sql = 'CREATE TABLE x (id INT); PRAGMA foreign_keys = OFF;';
      expect(validator.isSafe(sql), isFalse);
    });

    test('should ignore unsafe keywords if in single-line comment', () {
      final sql =
          "CREATE TABLE messages (content TEXT DEFAULT 'TEST');"
          "-- DROP TABLE messages;";
      expect(validator.isSafe(sql), isTrue);
    });

    test('should ignore unsafe keywords if in multi-line comment', () {
      final sql =
          "CREATE TABLE messages (content TEXT DEFAULT 'TEST');"
          "/* DROP TABLE messages; */";
      expect(validator.isSafe(sql), isTrue);
    });

    test(
      'should ignore unsafe keywords if in multi-line comment (with newlines)',
      () {
        final sql =
            "CREATE TABLE messages (content TEXT DEFAULT 'TEST');"
            "/*\nDROP TABLE messages;\n*/";
        expect(validator.isSafe(sql), isTrue);
      },
    );

    test('should ignore unsafe keywords if in single quotes', () {
      final sql =
          "CREATE TABLE messages (content TEXT DEFAULT 'PRAGMA foreign_keys = OFF');";
      expect(validator.isSafe(sql), isTrue);
    });

    test('should ignore unsafe keywords if in single quotes (with spaces)', () {
      final sql =
          "CREATE TABLE messages (content TEXT DEFAULT ' PRAGMA foreign_keys = OFF ');";
      expect(validator.isSafe(sql), isTrue);
    });

    test(
      'should flag unsafe keywords if starts with single quote and ends with double quote',
      () {
        final sql =
            "CREATE TABLE messages (content TEXT DEFAULT 'PRAGMA foreign_keys = OFF \");";
        expect(validator.isSafe(sql), isFalse);
      },
    );

    test(
      'should flag unsafe keywords if starts with double quote and ends with single quote',
      () {
        final sql =
            "CREATE TABLE messages (content TEXT DEFAULT \"PRAGMA foreign_keys = OFF ');";
        expect(validator.isSafe(sql), isFalse);
      },
    );

    test('should block CREATE TABLE AS SELECT statements', () {
      final sql = "CREATE TABLE 'x' AS SELECT * FROM sqlite_master";
      expect(validator.isSafe(sql), isFalse);
    });

    test('should block CREATE VIRTUAL TABLE', () {
      final sql = "CREATE VIRTUAL TABLE y USING fts5(content;)";
      expect(validator.isSafe(sql), isFalse);
    });

    test('should block unterminated single-quote string literal', () {
      final sql = "CREATE TABLE x (name TEXT DEFAULT 'oops);";
      expect(validator.isSafe(sql), isFalse);
    });

    test('should block unterminated double-quote string literal', () {
      final sql = 'CREATE TABLE x (name TEXT DEFAULT "oops);';
      expect(validator.isSafe(sql), isFalse);
    });

    test('should block unterminated block comment', () {
      final sql = 'CREATE TABLE x (id INT); /* DROP TABLE users';
      expect(validator.isSafe(sql), isFalse);
    });

    test('should allow CREATE INDEX with expressions', () {
      final sql = 'CREATE INDEX idx ON users(lower(name));';
      expect(validator.isSafe(sql), isTrue);
    });

    test('should allow CREATE TABLE IF NOT EXISTS', () {
      final sql = 'CREATE TABLE IF NOT EXISTS users (id INT);';
      expect(validator.isSafe(sql), isTrue);
    });

    test('should allow single line comments before valid SQL', () {
      final sql = "-- COMMENT \nCREATE TABLE 'z' (id INT);";
      expect(validator.isSafe(sql), isTrue);
    });

    test('should allow multi line comments before valid SQL', () {
      final sql = "/* COMMENT */ crEaTe taBLe 'z' (id INT);";
      expect(validator.isSafe(sql), isTrue);
    });

    test('should block single-line multi-command with unsafe keywords', () {
      final sql = "/* COMMENT */ CREATE TABLE x (id INT); VACUUM;";
      expect(validator.isSafe(sql), isFalse);
    });

    test('should block create statements followed by any modifiers', () {
      final sql = "CREATE TABLE x (id INT) IF NOT EXISTS;";
      expect(validator.isSafe(sql), isFalse);
    });

    test('should block create statements followed by any modifiers 2', () {
      final sql = "CREATE TABLE x (id INT) WITHOUT ROWID;";
      expect(validator.isSafe(sql), isFalse);
    });

    test('should allow Foreign Key actions (ON DELETE/UPDATE)', () {
      // This fails currently because DELETE and UPDATE are blacklisted
      final sql = '''
    CREATE TABLE orders (
      id INT PRIMARY KEY,
      user_id INT REFERENCES users(id) ON DELETE CASCADE ON UPDATE NO ACTION
    );
  ''';
      expect(validator.isSafe(sql), isTrue);
    });

    test('should allow escaped double quotes in identifiers', () {
      // The column name is literally: my "weird" column
      final sql = 'CREATE TABLE test ("my ""weird"" column" TEXT);';
      expect(validator.isSafe(sql), isTrue);
    });

    test('should allow escaped single quotes in literals', () {
      // The default value is literally: O'Reily
      final sql = "CREATE TABLE customers (name TEXT DEFAULT 'O''Reily');";
      expect(validator.isSafe(sql), isTrue);
    });

    test('should block keywords hidden by symbol boundaries', () {
      // "SELECT" touches ")" so simple space-based splitters fail,
      // but \b regex should catch it.
      final sql = 'CREATE TABLE x (id INT)SELECT * FROM x;';
      expect(validator.isSafe(sql), isFalse);
    });

    test('should allow column names that look like comments', () {
      // If your comment stripper is too aggressive, it might mangle this line
      final sql =
          'CREATE TABLE dangerous ("-- comment" TEXT, "/* comment */" INT);';
      expect(validator.isSafe(sql), isTrue);
    });
  });
}
