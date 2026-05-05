import 'package:flutter_test/flutter_test.dart';
import 'package:crab_cakes/infrastructure/project/sqlite/sql_insert_generator.dart';
import 'package:crab_cakes/domain/models/attribute.dart';
import 'package:crab_cakes/domain/models/project_db.dart';
import 'package:crab_cakes/domain/models/table.dart';
import 'package:crab_cakes/presentation/view_models/project_input.dart';

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

    // Populate data into tableInput
    table.attributes["ID"]!.controller.text = "1";
    table.attributes["Species"]!.controller.text = "Bass";

    test(
      'Statement should have matching counts of columns and placeholders',
      () {
        final record = generator.generate(table.name, table.toValueMap());
        final statement = record.sql;

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
      print(table.toValueMap());

      final record = generator.generate(table.name, table.toValueMap());
      final statement = record.sql;

      expect(statement, isNot(contains(', )')));
    });
  });

  group('SQL Insert Generator Tests - Mock ValueMaps', () {
    test('Throws exception upon empty ValueMap', () {
      final val = <String, dynamic>{};

      expect(() {
        generator.generate("test", val);
      }, throwsException);
    });
  });
}
