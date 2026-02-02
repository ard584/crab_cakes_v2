import 'package:flutter_test/flutter_test.dart';
import 'package:ui_prototype/presentation/models/attribute.dart';
import 'package:ui_prototype/presentation/models/project_db.dart';
import 'package:ui_prototype/presentation/models/table.dart';
import 'package:ui_prototype/presentation/providers/flex_form_provider.dart';
import 'package:ui_prototype/presentation/providers/form_save_provider.dart';



void main() {

  // Make a fake project
var userAttributes = <Attribute>[];
final att1 = Attribute(columnID: 1, name: 'ID', dataType: 'INT', isNotNullable: true, isPrimaryKey: true);
final att2 = Attribute(columnID: 2, name: 'Species', dataType: 'TEXT', isNotNullable: false, isPrimaryKey: false);
userAttributes.add(att1);
userAttributes.add(att2);
final specimenTable = TableModel(name: "Specimen", attributeList: userAttributes);
Map<String, TableModel> tableMap = {};
tableMap["Specimen"] = specimenTable;

final project = ProjectDb(tables: tableMap);
final projectInput = ProjectInput(name: "name2", project: project);

// Make a generator
final generator = SQLInsertGenerator(project: projectInput, tableName: "Specimen");


  test('Form provider can generate a table name', () async {

    final String statement = generator.generateInsertIntoTable();
    expect(statement, "INSERT INTO Specimen ( ID, Species ) VALUES ( ?, ? )");
    
  });
}