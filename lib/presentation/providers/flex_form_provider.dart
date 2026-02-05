import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_prototype/presentation/models/project_db.dart';
import 'package:ui_prototype/presentation/services/flex_engine/flex_db_mapper.dart';
import 'package:ui_prototype/presentation/view_models/project_input.dart';

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

// The provider (only used to load the project!)
// TODO: Figure out more about how Riverpod works
final currentFlexProjectProvider =
    AsyncNotifierProvider<CurrentFlexProjectNotifier, ProjectDb?>(
      CurrentFlexProjectNotifier.new,
    );

// DTO

final projectViewModelProvider =
    Provider.autoDispose<AsyncValue<ProjectInput>>((ref) {
      // Get the project from the project provider
      final projectAsync = ref.watch(currentFlexProjectProvider);

      return projectAsync.when(
        error: (error, stack) => AsyncError(error, stack),
        loading: () => AsyncLoading(),
        data: (project) {

          // If flexProject is null, return empty project map
          if (project == null) throw Exception("ProjectDB is empty: $project");

          final projectMap = ProjectInput(name: "project", project: project);

          ref.onDispose(() {
            projectMap.disposeControllers();
          },);

          return AsyncData(projectMap);
        },
      );
    });
