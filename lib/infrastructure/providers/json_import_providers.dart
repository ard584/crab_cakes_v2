import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:crab_cakes/application/project/interfaces/schema/project_settings_importer.dart';
import 'package:crab_cakes/application/project/use_cases/import_project.dart';
import 'package:crab_cakes/infrastructure/project/sqlite/sql_security_validator.dart';

import 'package:crab_cakes/infrastructure/project/sqlite/sql_settings_importer.dart';
import 'package:crab_cakes/infrastructure/project/sqlite/sqlite_project_database_builder.dart';
import 'package:crab_cakes/infrastructure/providers/settings_provider.dart';


//wiring infra providers
final projectSettingsImporterProvider = Provider<ProjectSettingsImporter>((ref) {
  return SqlSettingsImporter();
});

//wiring app-level providers
final importProjectUseCaseProvider = Provider<ImportProject>((ref) {
  final validator = SqlSecurityValidator();
  final dbBuilder = SqliteProjectDatabaseBuilder();
  final importer = ref.watch(projectSettingsImporterProvider);
  final integrityService = ref.watch(jsonIntegrityServiceProvider);

  return ImportProject(validator, dbBuilder, importer, integrityService);
});


