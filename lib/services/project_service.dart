import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_prototype/services/project_file_factory.dart';
import 'package:ui_prototype/utils/logger.dart';
import 'package:sqlite3/sqlite3.dart';

final projectServiceProvider = Provider((ref) => ProjectService(ref));

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
  final Ref ref;
  final ProjectFileFactory _fileFactory;

  ProjectService(this.ref) : _fileFactory = ProjectFileFactory();

  Future<void> create(ProjectCreateRequest request) async {
    String path;

    // Attempt to initialize the project
    try {
      log.d("INITIALIZE PROJECT CALLED");
      path = await _fileFactory.initializeProject(request.sql, opener: sqlite3.open);

      // Attempt to insert into database
      log.d("CALLING ADD PROJECT TO APP DATABASE");
      addProjectToAppDatabase(ref, title: request.title, dbPath: path);
    } catch (e) {
      log.e("ERROR: $e");
    }
  }
}