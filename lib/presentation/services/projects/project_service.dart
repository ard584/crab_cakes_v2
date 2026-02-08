import 'package:ui_prototype/presentation/services/flex_engine/flex_file_factory.dart';
import 'package:ui_prototype/presentation/utils/logger.dart';
import 'package:sqlite3/sqlite3.dart';

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
  final ProjectFileFactory _fileFactory;

  ProjectService() : _fileFactory = ProjectFileFactory();

  Future<String> create(ProjectCreateRequest request) async {
    String path;

    // Attempt to initialize the project
    try {
      log.d("INITIALIZE PROJECT CALLED");
      path = await _fileFactory.initializeProject(
        request.sql,
        opener: sqlite3.open,
      );

      return path;

    } catch (e) {
      log.e("ERROR: $e");
      throw Exception('Failed to create project: $e');
    }
  }
}
