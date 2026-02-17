import 'package:ui_prototype/application/use_cases/project/create_project.dart';
import 'package:ui_prototype/presentation/utils/logger.dart';

class ProjectCreateRequest {
  final String title;
  final String? description;
  final String sql;

  ProjectCreateRequest({
    required this.title,
    this.description,
    required this.sql,
  });
}

class ProjectService {
  final CreateProjectUseCase _createProject;

  ProjectService(this._createProject);

  Future<String> create(ProjectCreateRequest request) async {
    ProjectFilePath path;

    // Attempt to initialize the project

    try {
      path = await _createProject.execute(request.sql);

      return path;
    } catch (e) {
      log.e("ERROR: $e");
      throw Exception('Failed to create project: $e');
    }
  }
}
