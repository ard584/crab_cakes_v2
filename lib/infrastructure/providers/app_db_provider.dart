import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_prototype/application/project/use_cases/create_project.dart';
import 'package:ui_prototype/application/uuid/generate_uuid.dart';
import 'package:ui_prototype/infrastructure/project/sqlite/sql_security_validator.dart';
import 'package:ui_prototype/infrastructure/project/sqlite/sql_statement_parser.dart';
import 'package:ui_prototype/infrastructure/project/sqlite/sqlite_project_database_builder.dart';
import 'package:ui_prototype/infrastructure/providers/active_database_connection_provider.dart';
import 'package:ui_prototype/domain/models/project.dart';
import 'package:ui_prototype/infrastructure/providers/generate_uuid_provider.dart';
import 'package:ui_prototype/presentation/services/projects/database/projects_database.dart';
import 'package:ui_prototype/presentation/services/device_uuid_helper.dart';
import 'package:ui_prototype/presentation/services/projects/projects_repository.dart';
import 'package:ui_prototype/presentation/services/projects/project_service.dart';

final _deviceIdProvider = FutureProvider<Uint8List>((ref) async {
  // Get the UUID function
  final uuidFunc = ref.watch(generateUuidProvider);
  return await getOrCreateDeviceID(uuidGen: uuidFunc);
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
    data: (id) =>
        ProjectsRepository(db: db, deviceId: id, generateUuid: uuidGen),
    orElse: () => null,
  );
});

final _createProjectUseCaseProvider = Provider<CreateProjectUseCase>((ref) {
  final parser = SqlSchemaParser();
  final validator = SqlSecurityValidator();
  final dbBuilder = SqliteProjectDatabaseBuilder();

  return CreateProjectUseCase(
    validator: validator,
    dbBuilder: dbBuilder,
    parser: parser,
  );
});

final projectListProvider =
    AsyncNotifierProvider<ProjectsListNotifier, List<ProjectModel>>(() {
      return ProjectsListNotifier();
    });

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

  // Read
  Future<void> selectProject({required String dbPath}) async {
    // await ref.read(currentFlexProjectProvider.notifier).loadProject(dbPath);
    ref
        .read(activeDatabaseConnectionProvider.notifier)
        .setActiveProjectDatabase(dbPath);
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
