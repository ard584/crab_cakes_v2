import 'package:ui_prototype/application/project/use_cases/create_project.dart';
import 'package:ui_prototype/application/project_creation/project_service.dart';
import 'package:ui_prototype/infrastructure/project_creation/dtos/sqlite_project_create_request.dart';
import 'package:ui_prototype/presentation/utils/logger.dart';

class SqliteCreateProjectService implements CreateProjectService<SqliteProjectCreateRequest> {
  final CreateProjectUseCase createProject;

  SqliteCreateProjectService(this.createProject);

  @override
  Future<String> create(SqliteProjectCreateRequest request) async {
    ProjectFilePath path;

    try {
      path = await createProject.execute(request.sql);

      return path;
    } catch (e) {
      log.e("ERROR: $e");
      throw Exception('Failed to create project: $e');
    }
  }
}