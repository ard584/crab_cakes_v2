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

final _flexTableControllersProvider = Provider.autoDispose
    .family<Map<String, TextEditingController>, String>((ref, tableName) {
      final flexProject = ref.watch(_currentFlexProjectProvider).value;

      if (flexProject == null) {
        throw Exception("flexProject is null [flexTableControllersProvider]");
      }

      final table = flexProject.tables[tableName];

      if (table == null) {
        throw Exception(
          "table $tableName is null [flexTableControllersProvider]",
        );
      }

      final attributes = table.attributes;
      final Map<String, TextEditingController> controllers = {};

      for (final attribute in attributes) {
        controllers[attribute.name] = TextEditingController(
          text: attribute.defaultValue?.toString() ?? '',
        );
      }
      ;

      ref.onDispose(() {
        for (final controller in controllers.values) {
          controller.dispose();
        }
      });

      return controllers;
    });

class AttributeFormField {
  final Attribute fields;
  final TextEditingController controller;

  AttributeFormField({required this.fields, required this.controller});
}

class TableForm {
  final String name;
  final Map<String, AttributeFormField> attributes;

  TableForm({required this.name, required this.attributes});
}

final projectViewModelProvider =
    Provider.autoDispose<AsyncValue<Map<String, TableForm>>>((ref) {
      // Get the project from the project provider
      final projectAsync = ref.watch(_currentFlexProjectProvider);

      return projectAsync.when(
        error: (error, stack) => AsyncError(error, stack),
        loading: () => AsyncLoading(),
        data: (project) {
          // If flexProject is null, return
          if (project == null) return AsyncData({});

          final projectMap = <String, TableForm>{};

          // Iterate through tableNames
          for (final tableName in project.tables.keys) {
            // Watch controller for specific table
            // Not sure I need to keep this as a family anymore but we move
            final controllers = ref.watch(
              _flexTableControllersProvider(tableName),
            );

            // Get the table from the project
            // Exclamation mark means will throw exception if there's no entry w this key
            // TODO: Is this okay?
            final tableData = project.tables[tableName];
            if (tableData == null) continue;

            final attributesMap = <String, AttributeFormField>{};

            for (final attribute in tableData.attributes) {
              final controller = controllers[attribute.name];

              if (controller != null) {
                attributesMap[attribute.name] = AttributeFormField(
                  fields: attribute,
                  controller: controller,
                );
              }
            };

            projectMap[tableName] = TableForm(
              name: tableName,
              attributes: attributesMap,
            );
          }

          return AsyncData(projectMap);
        },
      );
    });
