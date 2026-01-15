import 'package:ui_prototype/services/create_project.dart';
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
      final sql = "CREATE TABLE messages (content TEXT DEFAULT 'DROP TABLE users');";
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
  });
}