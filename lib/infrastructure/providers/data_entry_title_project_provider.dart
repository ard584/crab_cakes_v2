// Add this provider to your providers file
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crab_cakes/infrastructure/providers/active_database_connection_provider.dart';
import 'package:crab_cakes/infrastructure/providers/app_db_provider.dart';

final currentProjectTitleProvider = Provider<String>((ref) {
  final dbPath = ref.watch(activeDatabasePathProvider);
  final projectList = ref.watch(projectListProvider).value;
  
  if (dbPath == null || projectList == null || projectList.isEmpty) {
    return 'Data Entry';
  }
  
  try {
    final project = projectList.firstWhere((p) => p.dbPath == dbPath);
    return project.title;
  } catch (_) {
    return 'Data Entry';
  }
});