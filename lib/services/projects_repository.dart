import 'app_database.dart';
import 'uuid_helpers.dart';
import 'dart:typed_data';

class ProjectsRepository {
  final AppDatabase db;
  final Uint8List deviceId;

  ProjectsRepository(this.db, this.deviceId);

  Future<void> createProject(String title, String? description, String dbPath) async {
    final now = nowMs();
  }
}