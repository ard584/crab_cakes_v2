import 'package:flutter_test/flutter_test.dart';
import 'package:ui_prototype/infrastructure/project/sqlite/sql_insert_generator.dart';
import 'package:ui_prototype/domain/models/attribute.dart';
import 'package:ui_prototype/domain/models/project_db.dart';
import 'package:ui_prototype/domain/models/table.dart';
import 'package:ui_prototype/presentation/view_models/project_input.dart';

void main() {
  // Make a generator
  final generator = SQLInsertGenerator();

  group('SQL String Syntax Tests - mock TableInput', () {
    // Make a fake project
    var userAttributes = <Attribute>[
      Attribute(
        columnID: 1,
        name: 'ID',
        dataType: 'INT',
        isNotNullable: true,
        isPrimaryKey: true,
      ),
      Attribute(
        columnID: 2,
        name: 'Species',
        dataType: 'TEXT',
        isNotNullable: false,
        isPrimaryKey: false,
      ),
    ];

    Map<String, TableModel> tableMap = {};

    tableMap["Specimen"] = TableModel(
      name: "Specimen",
      attributeList: userAttributes,
    );

    final project = ProjectDb(tables: tableMap);
    final projectInput = ProjectInput(name: "name2", project: project);

    final table = projectInput.tables["Specimen"]!;

    test(
      'Statement should have matching counts of columns and placeholders',
      () {
        final statement = generator.generateInsertStatement(
          tableName: table.name,
          values: table.toValueMap(),
        );

        if (statement == null) {
          return;
        }

        // Use RegEx to find everything between parentheses
        final columnsMatch = RegExp(r"\((.*?)\)").firstMatch(statement);
        final valuesMatch = RegExp(r"VALUES\s*\((.*?)\)").firstMatch(statement);

        final columnCount = columnsMatch?[1]?.split(',').length;
        final placeholderCount = valuesMatch?[1]?.split(',').length;

        expect(
          columnCount,
          placeholderCount,
          reason:
              "The number of columns must match the number of '?' placeholders",
        );
      },
    );

    test('Generated string should not end with a trailing comma', () {
      final statement = generator.generateInsertStatement(
        tableName: table.name,
        values: table.toValueMap(),
      );
      // A common bug is "INSERT INTO Table (col1, col2, ) ..."
      expect(statement, isNot(contains(', )')));
      expect(statement, isNot(contains(', )')));
    });
  });

  group('SQL Insert Generator Tests - Mock ValueMaps', () {
    test('Returns nothing upon empty ValueMap', () {
      final val = <String, dynamic>{};
      final statement = generator.generateInsertStatement(tableName: "test", values: val);

      expect(statement, isNull);
    });
  });
}
