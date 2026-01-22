import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_prototype/models/attribute.dart';
import 'package:ui_prototype/providers/flex_form_provider.dart';
import 'package:ui_prototype/screens/export_screen.dart';
import 'package:ui_prototype/screens/project_selection.dart';
import 'package:ui_prototype/services/flex_field/flex_field_factory.dart';
import 'package:ui_prototype/services/projects/flex_project_provider.dart';
import 'package:ui_prototype/utils/logger.dart';

import 'settings_screen.dart';

class DataEntryScreen extends ConsumerWidget {
  const DataEntryScreen({super.key});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectAsync = ref.watch(currentFlexProjectProvider);

    final project = projectAsync.value;
    final activeTableName = project?.tables.keys.firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: projectAsync.when(
          data: (project) => Text('Data Entry'),
          error: (_, __) => const Text("Error"),
          loading: () => const Text('Loading...'),
        ),
      ),
      drawer: ProjectDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(28.0),
        child: projectAsync.when(
          error: (err, stack) => Center(child: Text("Error: $err")),
          data: (project) {
            if (project == null) {
              return Center(child: Text("No project selected"));
            }

            // Check if table exists
            if (activeTableName != null) {
              // Extract attributes
              return TableFormSection(tableName: activeTableName);
            }
            // If table is null, tell user
            else {
              return Center(child: Text('Table is null'));
            }
          },

          // Handle error and loading states
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          //TODO: make the save button actually do something
          final controllers = ref.watch(flexTableControllersProvider(activeTableName!));
          for (final controller in controllers.values) {
            log.d(controller.text);
          }
        },
        label: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text("Save Record"),
        ),
      ),
    );
  }
}

class TableFormSection extends ConsumerWidget {
  final String tableName;
  const TableFormSection({super.key, required this.tableName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(currentFlexProjectProvider).value;
    final table = project?.tables[tableName];

    if (table == null) {
      return Center(child: Text("Table is null"));
    }

    final controllers = ref.watch(flexTableControllersProvider(tableName));

    if (controllers.isEmpty || controllers.length < table.attributes.length) {
      log.w(
        "Mismatch in TableFormSection build: controllers don't match table",
      );
      log.w("Controllers isEmpty: ${controllers.isEmpty}");
      log.w("Controllers length: ${controllers.length}");
      log.w("Table $tableName attributes length: ${table.attributes.length}");
      return Center(child: CircularProgressIndicator());
    }

    final attrbutes = table.attributes;

    return ListView.builder(
      itemCount: attrbutes.length,
      itemBuilder: (context, index) {
        final attribute = table.attributes.elementAt(index);

        return DynamicFlexField(tableName: tableName, attribute: attribute);
      },
    );
  }
}

class DynamicFlexField extends ConsumerWidget {
  final String tableName;
  final Attribute attribute;

  const DynamicFlexField({
    super.key,
    required this.tableName,
    required this.attribute,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controllers = ref.watch(flexTableControllersProvider(tableName));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      margin: const EdgeInsets.only(bottom: 16.0, top: 4.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade100, // Light background color
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: Colors.grey.shade300),
      ),

      child: FlexFieldFactory.createField(
        config: FlexFieldConfig(
          label: attribute.name,
          dataType: attribute.dataType,
          isRequired: attribute.isNotNullable,
        ),

        // Placeholder for now, doesn't do anything
        controller: controllers[attribute.name]!,

        baseDecoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(vertical: 14.0),
        ),
      ),
    );
  }
}

class DrawerSubmenu extends StatelessWidget {
  const DrawerSubmenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.settings),
          title: const Text("Settings"),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.file_open),
          title: const Text("Switch Project"),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProjectSelection()),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.file_download),
          title: const Text("Export Data"),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ExportScreen()),
            );
          },
        ),
      ],
    );
  }
}

class ProjectDrawer extends ConsumerWidget {
  const ProjectDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectAsync = ref.watch(currentFlexProjectProvider);

    // return projectAsync.when(
    //   loading: () => Center(child: CircularProgressIndicator()),
    //   error: (error, stackTrace) => Center(child: Text("Drawer Error: $error")),
    //   data: (project) {
    //     if (project == null) {
    //       return Drawer(child: Center(child: Text("Project is NULL")));
    //     }

    //     final tableNames = project.tables.keys.toList();

    return Drawer(
      child: Column(
        children: [
          SizedBox(
            height: 80,
            child: const DrawerHeader(
              child: Center(child: Text('Project Menu')),
            ),
          ),

          Expanded(
            child: projectAsync.when(
              error: (error, stackTrace) =>
                  Center(child: Text("Drawer Error: $error")),
              loading: () => Center(child: CircularProgressIndicator()),
              data: (project) {
                if (project == null) {
                  return Drawer(child: Center(child: Text("Project is NULL")));
                }

                final tableNames = project.tables.keys.toList();
                return ListView.builder(
                  itemCount: tableNames.length,
                  itemBuilder: (context, index) {
                    final tableName = tableNames[index];
                    final tableData = project.tables[tableName];

                    return ListTile(
                      leading: const Icon(Icons.table_chart_outlined),
                      title: Text(tableName),
                      subtitle: Text(
                        "${tableData?.attributes.length ?? 0} attributes",
                      ),
                    );
                  },
                );
              },
            ),
          ),

          const Divider(height: 1),

          DrawerSubmenu(),

          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
