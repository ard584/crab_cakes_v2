import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:crab_cakes/application/device_storage/device_id_use_case.dart';
import 'package:crab_cakes/application/project/use_cases/create_project.dart';
import 'package:crab_cakes/infrastructure/project/sqlite/sql_security_validator.dart';
import 'package:crab_cakes/infrastructure/project/sqlite/sql_statement_parser.dart';
import 'package:crab_cakes/infrastructure/project/sqlite/sqlite_project_database_builder.dart';
import 'package:crab_cakes/infrastructure/project/sqlite/sqlite_schema_structure_validator.dart';
import 'package:crab_cakes/infrastructure/providers/active_database_connection_provider.dart';
import 'package:crab_cakes/domain/models/project.dart';
import 'package:crab_cakes/infrastructure/providers/device_id_use_case_provider.dart';
import 'package:crab_cakes/infrastructure/providers/device_storage_provider.dart';
import 'package:crab_cakes/infrastructure/providers/generate_uuid_provider.dart';
import 'package:crab_cakes/presentation/services/projects/database/projects_database.dart';
import 'package:crab_cakes/presentation/services/projects/projects_repository.dart';
import 'package:crab_cakes/presentation/services/projects/project_service.dart';
import 'package:crab_cakes/application/uuid/generate_uuid.dart';

import 'package:crab_cakes/infrastructure/providers/json_import_providers.dart';



final _deviceIdProvider = FutureProvider<Uint8List>((ref) async {
  // Get the UUID function
  final uuidFunc = ref.watch(generateUuidProvider);
  final storage = ref.watch(deviceStorageProvider);
  final DeviceIDUseCase deviceIDUseCase = ref.watch(deviceIDUseCaseProvider);
  return await deviceIDUseCase.getOrCreateDeviceID(uuidGen: uuidFunc, storage: storage);
});

// App database provider (holds all the projects)
final _appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase(openConnection());

  // Close db when app is closed
  ref.onDispose(() => db.close());

  return db;
});

final _projectsRepositoryProvider = Provider<ProjectsRepository?>((ref) {
  final deviceIdAsync = ref.watch(_deviceIdProvider);
  final db = ref.watch(_appDatabaseProvider);
  final GenerateUuid uuidGen = ref.watch(generateUuidProvider);

  return deviceIdAsync.maybeWhen(
    data: (id) => ProjectsRepository(db: db, deviceId: id, generateUuid: uuidGen),
    orElse: () => null,
  );
});

final _createProjectUseCaseProvider = Provider<CreateProjectUseCase>((ref) {

  final parser = SqlSchemaParser();
  final statementValidator = SqlSecurityValidator();
  final dbBuilder = SqliteProjectDatabaseBuilder();
  final structureValidator = SqliteSchemaStructureValidator();

  return CreateProjectUseCase(
    statementValidator: statementValidator, 
    structureValidator: structureValidator,
    dbBuilder: dbBuilder, 
    parser: parser);
  
},);

final projectListProvider =
    AsyncNotifierProvider<ProjectsListNotifier, List<ProjectModel>>(() {
      return ProjectsListNotifier();
    });


/// Holds the currently selected app-level project.
///
/// This is different from [activeDatabaseConnectionProvider].
///
/// - [activeProjectProvider] stores metadata such as project ID, title, and dbPath.
/// - [activeDatabaseConnectionProvider] stores the open SQLite connection.
/// - [activeDatabasePathProvider] stores the path to the active project DB.
final activeProjectProvider = StateProvider<ProjectModel?>((ref) => null);

// Notifiers control state as well as provide data
class ProjectsListNotifier extends AsyncNotifier<List<ProjectModel>> {
  @override
  Future<List<ProjectModel>> build() async {
    final repository = ref.watch(_projectsRepositoryProvider);
    if (repository == null) return [];
    return await repository.getAllProjects();
  }

  // Create
  Future<void> createProject({
    required String title,
    String? description,
    required String sql,
  }) async {
    // Get repo
    final repo = ref.read(_projectsRepositoryProvider);
    if (repo == null) return;

    // Create projectService
    final service = ref.read(_createProjectUseCaseProvider);

    final request = ProjectCreateRequest(
      title: title,
      description: description,
      sql: sql,
    );

    try {
      final path = await service.execute(request.sql);

      // Call repo
      await repo.createProject(
        title: title,
        dbPath: path,
        description: description,
      );

      // Invalidate self to update the UI
      ref.invalidateSelf();
    } catch (error) {
      rethrow;
    }
  }

  //importing a project from json
  Future<void> importProject({
    required String title,
    String? description,
    required String jsonString,
  }) async {
    final repo = ref.read(_projectsRepositoryProvider);
    if(repo == null) return;

    final service = ref.read(importProjectUseCaseProvider);

    try {
      final path = await service.execute(jsonString);

      await repo.createProject(
        title: title,
        dbPath: path,
        description: description,
      );

      ref.invalidateSelf();
    } catch (error) {
      rethrow;
    }
  }

  // Read
  Future<void> selectProject({required ProjectModel project}) async {
    ref
        .read(activeDatabaseConnectionProvider.notifier)
        .setActiveProjectDatabase(project.dbPath);

    ref.read(activeProjectProvider.notifier).state = project;
  }

  // Update
  Future<void> updateProject({required ProjectModel project}) async {
    final repository = ref.read(_projectsRepositoryProvider);
    if (repository == null) return;

    // Call update function
    repository.updateProject(project);

    // Invalidate self to force update
    ref.invalidateSelf();
  }

  // Delete
  Future<void> deleteProject({required Uint8List projectId}) async {
    final repository = ref.read(_projectsRepositoryProvider);
    if (repository == null) return;

    await repository.deleteProjectById(projectId);

    state = state.maybeWhen(
      data: (projects) {
        return AsyncData(
          projects.where((project) => project.id != projectId).toList(),
        );
      },
      orElse: () => state,
    );
  }
}
