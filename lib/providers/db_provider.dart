import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_prototype/services/projects/database/projects_database.dart';
import 'package:ui_prototype/services/device_uuid_helper.dart';
import 'package:ui_prototype/services/projects/projects_repository.dart';

final deviceIdProvider = FutureProvider<Uint8List>((ref) async {
  return await getOrCreateDeviceID();
});

// App database provider (holds all the projects)
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase(openConnection());

  // Close db when app is closed
  ref.onDispose(() => db.close());

  return db;
});

final projectsRepositoryProvider = Provider<ProjectsRepository?>((ref) {
  final deviceIdAsync = ref.watch(deviceIdProvider);
  final db = ref.watch(databaseProvider);

  return deviceIdAsync.maybeWhen(
    data: (id) => ProjectsRepository(db, id),
    orElse: () => null,
  );
});
