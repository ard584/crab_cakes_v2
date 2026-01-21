import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_prototype/models/project_db.dart';
import 'package:ui_prototype/services/flex_engine/flex_db_mapper.dart';

class CurrentFlexProjectNotifier extends AsyncNotifier<ProjectDb?> {
  @override
  Future<ProjectDb?> build() async => null;

  Future<void> loadProject(String path) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      // FlexDbMapper opens and maps the database into a dbObject
      final mapper = FlexDbMapper(dbPath: path);
      return await mapper.mapFromDatabase();
    });
  }
}

// The provider (what we access to read current project)
// TODO: Figure out more about how Riverpod works
final currentFlexProjectProvider =
    AsyncNotifierProvider<CurrentFlexProjectNotifier, ProjectDb?>(
      CurrentFlexProjectNotifier.new,
    );
