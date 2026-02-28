import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:ui_prototype/infrastructure/providers/active_database_connection_provider.dart';
import 'package:ui_prototype/presentation/services/flex_engine/flex_db_mapper.dart';
import 'package:ui_prototype/presentation/view_models/project_input.dart';

// DTO
final projectViewModelProvider =
    AsyncNotifierProvider<ProjectViewModelNotifier, ProjectInput>(
      ProjectViewModelNotifier.new,
    );

class ProjectViewModelNotifier extends AsyncNotifier<ProjectInput> {
  @override
  FutureOr<ProjectInput> build() async {
    // Get active database connection
    final db = ref.watch(activeDatabaseConnectionProvider);

    if (db == null) {
      throw Exception("Database connection is not active");
    }

    // Map database
    final mapper = FlexDbMapper(db: db);
    final project = mapper.mapFromDatabase();

    final projectInput = ProjectInput(name: "project", project: project);

    ref.onDispose(() {
      projectInput.disposeControllers();
    });

    return projectInput;
  }
}

// Active table provider as StateNotifier
final activeTableProvider = StateNotifierProvider<ActiveTableNotifier, String?>(
  (ref) => ActiveTableNotifier(ref),
);

class ActiveTableNotifier extends StateNotifier<String?> {
  final Ref ref;

  ActiveTableNotifier(this.ref) : super(null) {
    // Listen to project changes
    ref.listen<AsyncValue<ProjectInput>>(projectViewModelProvider, (
      previous,
      next,
    ) {
      next.whenData((projectInput) {
        final tables = projectInput.project.tables;
        if (tables.isEmpty) {
          state = null;
          return;
        }

        // Reset to first table if current selection is invalid
        if (state == null || !tables.containsKey(state)) {
          state = tables.keys.first;
        }
      });
    });
  }

  // Optional: user can manually set the active table
  void setActiveTable(String tableName) {
    state = tableName;
  }
}
