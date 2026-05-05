// This use case rebuilds a project, including every field's field config, from
// a given json file.
// NOTE:
//      THIS DOES NOT PRESERVE THE ACTUAL DATA OF THE ORIGINAL PROJECT
import 'dart:convert';

import 'package:crab_cakes/application/project/interfaces/schema/project_database_builder.dart';
import 'package:crab_cakes/application/project/interfaces/schema/schema_validator.dart';
import 'package:crab_cakes/application/project/interfaces/schema/project_settings_importer.dart';
import 'package:crab_cakes/application/project/use_cases/create_project.dart';
import 'package:crab_cakes/infrastructure/project/project_json_integrity_service.dart';

class ImportProject {
  final SchemaValidator validator;
  final ProjectDatabaseBuilder dbBuilder;
  final ProjectSettingsImporter importer;
  final ProjectJsonIntegrityService integrityService;

  ImportProject(
    this.validator,
    this.dbBuilder,
    this.importer,
    this.integrityService,
  );

  Future<ProjectFilePath> execute(String jsonString) async {
    // parse the json into a map
    final root = jsonDecode(jsonString) as Map<String, dynamic>;

    // verify tamper-detection wrapper and extract the actual project payload
    final payload = integrityService.extractVerifiedPayload(root);

    final rawStatements = payload['schemaSql'];
    final rawSettings = payload['settings'];

    // ensuring correct json format for the sql schema
    if (rawStatements is! List) {
      throw UnsafeSchemaException('schemaSql must be a list');
    }

    final statements = rawStatements.cast<String>();

    if (rawSettings is! Map) {
      throw UnsafeSchemaException('Settings must be a Map!');
    }

    // validate schema
    if (statements.isEmpty || !validator.isSafe(statements)) {
      throw UnsafeSchemaException();
    }

    // create the project with the schema
    final dbPath = await dbBuilder.buildFromSchema(statements);

    // override settings with the verified payload only,
    // NOT the outer { payload, integrity } wrapper
    await importer.replaceSettingsJson(
      dbPath: dbPath,
      settingsJson: jsonEncode(payload),
    );

    // return the Project Filepath
    return dbPath;
  }
}