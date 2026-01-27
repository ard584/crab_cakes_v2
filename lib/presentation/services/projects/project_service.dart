import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_prototype/presentation/services/flex_engine/flex_file_factory.dart';
import 'package:ui_prototype/presentation/providers/flex_form_provider.dart';
import 'package:ui_prototype/presentation/utils/logger.dart';
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
      await addProjectToAppDatabase(ref, title: request.title, dbPath: path);

      // Open project
      await openProject(path);
    } catch (e) {
      log.e("ERROR: $e");
    }
  }

  Future<void> openProject(String dbPath) async {

    await ref.read(flexProjectControllerProvider).loadProject(dbPath);

  }
}