import 'app_database.dart';
import 'package:drift/drift.dart';

import 'uuid_helpers.dart';
import 'device_uuid_helper.dart';

/// Returns current UTC time in ISO-8601 format
String _nowIsoUtc() => DateTime.now().toUtc().toIso8601String();


class ProjectsRepository {
  final AppDatabase db;
  final Uint8List deviceId;

  ProjectsRepository(this.db, this.deviceId);

  Future<void> createProject(String title, String? description, String dbPath) async {

    //
    ProjectsCompanion(

      // Since this is project creation, both createdBy and updatedBy will have the same ID
      createdByDevice: Value(await getOrCreateDeviceID()),
      updatedByDevice: Value(await getOrCreateDeviceID()),

      // Same thing with this
      createdAt: Value(_nowIsoUtc()),
      updatedAt: Value(_nowIsoUtc()),

      // Generate a UUID for the pk
      id: Value(newUuidV7()),

      // And pass the user-generated values in
      title: Value(title),
      description: Value(description),
      dbPath: Value(dbPath)
    );

  }
}