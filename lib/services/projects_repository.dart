// projects_repository.dart

import 'app_database.dart';
import 'package:drift/drift.dart';
import '../models/project.dart';

import 'uuid_helpers.dart';

/// Returns current UTC time in ISO-8601 format
String _nowIsoUtc() => DateTime.now().toUtc().toIso8601String();

class ProjectsRepository {
  final AppDatabase db;
  final Uint8List deviceId;

  ProjectsRepository(this.db, this.deviceId);

  // Create project
  Future<void> createProject({
    required String title,
    String? description,
    required String dbPath,
  }) async {
    final now = _nowIsoUtc();

    //
    await db
        .into(db.projects)
        .insert(
          ProjectsCompanion(
            // Since this is project creation, both createdBy and updatedBy will have the same ID
            createdByDevice: Value(deviceId),
            updatedByDevice: Value(deviceId),

            // Same thing with this
            createdAt: Value(now),
            updatedAt: Value(now),

            // Generate a UUID for the pk
            id: Value(newUuidV7()),

            // And pass the user-generated values in
            title: Value(title),
            description: Value(description),
            dbPath: Value(dbPath),
          ),
        );
  }

  Future<List<ProjectModel>> getAllProjects() async {

    final res = await db.select(db.projects).get();

    final projects = res.map((item) => {

      ProjectModel(
        id: item.id,
        title: item.title,
        description: item.description,
        dbPath: item.dbPath,
        createdAt: DateTime.parse(item.createdAt),
        updatedAt: DateTime.parse(item.updatedAt),
      )

    });

    final List<ProjectModel> projectsList = projects.expand((setOfProjects) => setOfProjects).toList();

    return projectsList;
  }
}
