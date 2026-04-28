//This use case rebuilds a project, including every fields field config, from 
//a given json file.
//NOTE: 
//      THIS DOES NOT PRESERVE THE ACTUAL DATA OF THE ORIGINAL PROJECT
import 'dart:convert';

import 'package:ui_prototype/application/project/interfaces/schema/project_database_builder.dart';
import 'package:ui_prototype/application/project/interfaces/schema/schema_validator.dart';
import 'package:ui_prototype/application/project/interfaces/schema/project_settings_importer.dart';
import 'package:ui_prototype/application/project/use_cases/create_project.dart';

class ImportProject {
  
  final SchemaValidator validator;
  final ProjectDatabaseBuilder dbBuilder;
  final ProjectSettingsImporter importer;

  ImportProject(this.validator, this.dbBuilder, this.importer);

  Future<ProjectFilePath> execute(String jsonString) async {
    //parse the json into a map
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    final rawStatements = json['schemaSql'];
    final rawSettings = json['settings'];

    //ensuring correct json format for the sql schema
    if(rawStatements is! List) {
      throw UnsafeSchemaException('schemasql must be a list');
    }
    final statements = rawStatements.cast<String>();

    if(rawSettings is! Map) {
      throw UnsafeSchemaException('Settings must be a Map!');
    }


    //validate schema
    if(statements.isEmpty || !validator.isSafe(statements)) {
      throw UnsafeSchemaException();
    }

    //create the project with the schema
    final dbPath = await dbBuilder.buildFromSchema(statements);

    //override settings with the json settings
    await importer.replaceSettingsJson(dbPath: dbPath, settingsJson: jsonString);

    //return the Project Filepath
    return dbPath;
  }
}