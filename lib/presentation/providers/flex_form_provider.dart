import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:ui_prototype/presentation/models/attribute.dart';
import 'package:ui_prototype/presentation/models/project_db.dart';
import 'package:ui_prototype/presentation/services/flex_engine/flex_db_mapper.dart';

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
final _currentFlexProjectProvider =
    AsyncNotifierProvider<CurrentFlexProjectNotifier, ProjectDb?>(
      CurrentFlexProjectNotifier.new,
    );

// Only expose the notifier so we can use the loadProject function
// Data only accessible via attributeFormFieldProvider (viewModel)
final flexProjectControllerProvider = Provider((ref) {
  return ref.watch(_currentFlexProjectProvider.notifier);
});

// final _flexTableControllersProvider = Provider.autoDispose
//     .family<Map<String, TextEditingController>, String>((ref, tableName) {
//       final flexProject = ref.watch(_currentFlexProjectProvider).value;

//       if (flexProject == null) {
//         throw Exception("flexProject is null [flexTableControllersProvider]");
//       }

//       final table = flexProject.tables[tableName];

//       if (table == null) {
//         throw Exception(
//           "table $tableName is null [flexTableControllersProvider]",
//         );
//       }

//       final attributes = table.attributes;
//       final Map<String, TextEditingController> controllers = {};

//       for (final attribute in attributes) {
//         controllers[attribute.name] = TextEditingController(
//           text: attribute.defaultValue?.toString() ?? '',
//         );
//       }
//       ;

//       ref.onDispose(() {
//         for (final controller in controllers.values) {
//           controller.dispose();
//         }
//       });

//       return controllers;
//     });


// DTO
class AttributeInput {
  final Attribute fields;
  String? value;

  AttributeInput({required this.fields, this.value});
}

// UI State
class AttributeFormField {
  final AttributeInput input;
  final TextEditingController controller;

  AttributeFormField({required this.input})
      : controller = TextEditingController() {
    // Listen to changes in the text field
    controller.addListener(() {
      input.value = controller.text; // sync UI -> model
    });
  }
}


class ProjectInput {
  final String name;
  final ProjectDb project;
  final Map<String, TableInput> _tables = {};

  Map<String, TableInput> get tables => Map.unmodifiable(_tables);

  ProjectInput({required this.name, required this.project}) {


    // Iterate through keys
    for (final key in project.tables.keys) {

      // Get table
      final table = project.tables[key];

      if (table == null) {
        continue;
      }

      // Create empty attributes map
      final Map<String, AttributeFormField> attributeInputs = {};


      // Iterate through attributes
      for (final attribute in table.attributes) {

        // Create textEditingController, save attribute
        attributeInputs[attribute.name] = AttributeFormField(input: AttributeInput(fields: attribute));
        

      }

      // Create tableInput
      final tableInput = TableInput(name: table.name, attributes: attributeInputs);
      _tables[tableInput.name] = tableInput;

    }
  }
}

class TableInput {
  final String name;
  final Map<String, AttributeFormField> attributes;

  TableInput({required this.name, required this.attributes});
}

final projectViewModelProvider =
    Provider.autoDispose<AsyncValue<ProjectInput>>((ref) {
      // Get the project from the project provider
      final projectAsync = ref.watch(_currentFlexProjectProvider);

      return projectAsync.when(
        error: (error, stack) => AsyncError(error, stack),
        loading: () => AsyncLoading(),
        data: (project) {

          // If flexProject is null, return empty project map
          if (project == null) throw Exception("ProjectDB is empty: $project");

          final projectMap = ProjectInput(name: "project", project: project);

          return AsyncData(projectMap);
        },
      );
    });
