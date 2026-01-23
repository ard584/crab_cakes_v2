import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:ui_prototype/models/attribute.dart';
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
  final Attribute attribute;
  final TextEditingController controller;

  AttributeFormField({required this.attribute, required this.controller});
}

class TableForm {
  final String name;
  final Map<String, AttributeFormField> attributes;

  TableForm({required this.name, required this.attributes});
}

final projectViewModelProvider = Provider.autoDispose<Map<String, TableForm>>((
  ref,
) {
  // Get the project from the project provider
  final flexProject = ref.watch(_currentFlexProjectProvider).value;

  // If flexProject is null, return
  if (flexProject == null) return {};

  final projectMap = <String, TableForm>{};

  // Iterate through tableNames
  for (final tableName in flexProject.tables.keys) {
    // Watch controller for specific table
    // Not sure I need to keep this as a family anymore but we move
    final controllers = ref.watch(_flexTableControllersProvider(tableName));

    // Get the table from the project
    // Exclamation mark means will throw exception if there's no entry w this key
    // TODO: Is this okay?
    final tableData = flexProject.tables[tableName]!;

    // Now, iterate through the fields and map everything together
    final attributes = <String, AttributeFormField>{
      for (final attribute in tableData.attributes)
        attribute.name: AttributeFormField(
          attribute: attribute,
          controller: controllers[attribute.name]!,
        ),
    };

    projectMap[tableName] = TableForm(name: tableName, attributes: attributes);
  }

  return projectMap;
});

// <Map<String, Map<String, AttributeFormField>>>

final attributeFormFieldProvider = Provider.autoDispose
    .family<Map<String, AttributeFormField>, String>((ref, tableName) {
      final flexProject = ref.watch(_currentFlexProjectProvider).value;
      final table = flexProject?.tables[tableName];

      if (table == null) return {};
      final controllers = ref.watch(_flexTableControllersProvider(tableName));
      final formMap = <String, AttributeFormField>{};

      for (final attr in table.attributes) {
        formMap[attr.name] = AttributeFormField(
          attribute: attr,
          controller: controllers[attr.name]!,
        );
      }

      return formMap;
    });
