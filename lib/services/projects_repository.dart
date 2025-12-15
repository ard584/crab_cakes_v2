import 'app_database.dart';
import 'package:drift/drift.dart';

import 'uuid_helpers.dart';

/// Returns current UTC time in ISO-8601 format
String _nowIsoUtc() => DateTime.now().toUtc().toIso8601String();

class ProjectsRepository {
  final AppDatabase db;
  final Uint8List deviceId;

  ProjectsRepository(this.db, this.deviceId);

  Future<void> createProject(
    String title,
    String? description,
    String dbPath,
  ) async {
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
}
