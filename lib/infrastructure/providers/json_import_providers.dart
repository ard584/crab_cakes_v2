import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ui_prototype/application/project/interfaces/schema/project_settings_importer.dart';
import 'package:ui_prototype/application/project/use_cases/import_project.dart';
import 'package:ui_prototype/infrastructure/project/sqlite/sql_security_validator.dart';

import 'package:ui_prototype/infrastructure/project/sqlite/sql_settings_importer.dart';
import 'package:ui_prototype/infrastructure/project/sqlite/sqlite_project_database_builder.dart';


//wiring infra providers
final projectSettingsImporterProvider = Provider<ProjectSettingsImporter>((ref) {
  return SqlSettingsImporter();
});

//wiring app-level providers
final importProjectUseCaseProvider = Provider<ImportProject>((ref) {
  final validator = SqlSecurityValidator();
  final dbBuilder = SqliteProjectDatabaseBuilder();
  final importer = ref.watch(projectSettingsImporterProvider);

  return ImportProject(validator, dbBuilder, importer);
});


