import 'dart:nativewrappers/_internal/vm/lib/math_patch.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:ui_prototype/infrastructure/project/sqlite/sqlite_update_generator.dart';

void main() {
  group('Test', () {
    final generator = SqliteUpdateGenerator();

    final table = "specimen";
    final data = <String, dynamic>{"id": 1, "species": "bass"};
    final identifier = "rowid";
    final key = 1;

    test('Correctly generates an update statement', () {
      final response = generator.generate(table, data, identifier, key);
      final statement = response.sql.trim().replaceAll(r'\s+', ' ');

      final String expected = """
        UPDATE specimen SET id = ?, SET species = ? WHERE rowid = 1;
      """;

      expect(statement, equalsIgnoringWhitespace(expected));
    });

    test("Doesn't end with trailing commas", () {
      final response = generator.generate(table, data, identifier, key);
      final statement = response.sql.trim();

      expect(statement, isNot(contains("?, WHERE")));
    });

    test("Throws exception with empty ValueMap", () {
      expect(() {
        generator.generate(table, <String, dynamic>{}, identifier, key);
      }, throwsException);
    });
  });
}
