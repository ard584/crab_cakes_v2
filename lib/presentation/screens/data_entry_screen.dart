import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_prototype/infrastructure/providers/flex_form_provider.dart';
import 'package:ui_prototype/infrastructure/providers/form_save_notifier.dart';
import 'package:ui_prototype/infrastructure/providers/project_database_provider.dart';
import 'package:ui_prototype/presentation/screens/check_database_screen.dart';
import 'package:ui_prototype/presentation/screens/export_screen.dart';
import 'package:ui_prototype/presentation/screens/project_selection.dart';
import 'package:ui_prototype/presentation/services/flex_field/flex_field_factory.dart';
import 'package:ui_prototype/presentation/view_models/project_input.dart';
import 'package:ui_prototype/presentation/components/catch_table_widget.dart';
import 'package:ui_prototype/presentation/shortcuts/data_entry_shortcuts.dart';

import 'settings_screen.dart';

class DataEntryScreen extends ConsumerStatefulWidget {
  const DataEntryScreen({super.key});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _DataEntryState();
}

class _DataEntryState extends ConsumerState<DataEntryScreen> {

  @override
  Widget build(BuildContext context) {
    final projectAsync = ref.watch(projectViewModelProvider);
    final activeTableName = ref.watch(activeTableProvider);

    // Set activeProject state
    projectAsync.whenData((project) {
      if (activeTableName != null) {
      }
    });

    // Snack bar updates
    ref.listen<AsyncValue<void>>(formSaveProvider, (previous, next) {
      next.whenOrNull(
        data: (_) {
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text("Recorded")));
          }
        },
        error: (e, st) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Error occurred: $e"),
                action: SnackBarAction(
                  label: "Details",
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) {
                        return AlertDialog(
                          title: Text("Error Details"),
                          content: Text(e.toString()),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text("Close"),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            );
          }
        },
      );
    });

  return DataEntryShortcuts(
    onSave: () async {
      final projectMap = ref.read(projectViewModelProvider).value;
      if (projectMap == null) return;
      final table = projectMap.tables[activeTableName];
      if (table == null) return;
      await ref.read(formSaveProvider.notifier).saveTable(table);
    },
    child: Scaffold(
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
            if (project.tables.isEmpty) {
              return Center(child: Text("No project selected"));
            }

            if (activeTableName == null) {
              return Center(child: const CircularProgressIndicator());
            }

            return Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: CatchHistorySection(tableName: activeTableName),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: TableFormSection(tableName: activeTableName),
                ),
              ],
            );
          },

          // Handle error and loading states
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        focusNode: FocusNode(skipTraversal: true),
        onPressed: () async {
          final projectMap = ref.read(projectViewModelProvider).value;

          if (projectMap == null) return;

          final table = projectMap.tables[activeTableName];
          print("ACTIVE TABLE NAME: $activeTableName");

          // Table is returning null for some reason
          if (table == null) {
            print("TABLE IS NULL");
            return;
          }

          print("TABLE SAVED");

          await ref.read(formSaveProvider.notifier).saveTable(table);
        },
        label: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text("Save Record (f12)"),
          ),
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
    final project = ref.watch(projectViewModelProvider).value;
    final table = project?.tables[tableName];

    if (table == null) {
      return Center(child: Text("Table is null"));
    }

    final attrbutes = table.attributes.values.toList();

    return ListView.builder(
      itemCount: attrbutes.length,
      itemBuilder: (context, index) {
        final attribute = attrbutes[index];

        return DynamicFlexField(tableName: tableName, attribute: attribute);
      },
    );
  }
}

class DynamicFlexField extends ConsumerWidget {
  final String tableName;
  final AttributeFormField attribute;

  const DynamicFlexField({
    super.key,
    required this.tableName,
    required this.attribute,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final controllers = ref.watch(flexTableControllersProvider(tableName));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      margin: const EdgeInsets.only(bottom: 16.0, top: 4.0),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest, // Light background color
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: Theme.of(context).colorScheme.onSecondary),
      ),

      child: FlexFieldFactory.createField(
        config: FlexFieldConfig(
          label: attribute.fields.name,
          dataType: attribute.fields.dataType,
          isRequired: attribute.fields.isNotNullable,
        ),

        // Placeholder for now, doesn't do anything
        controller: attribute.controller,

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
        ListTile(
          leading: const Icon(Icons.abc_outlined),
          title: const Text("Check Database"),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CheckDatabaseScreen(),
              ),
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
    final projectAsync = ref.watch(projectViewModelProvider);

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
                if (project.tables.isEmpty) {
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
                      onTap: () {
                        ref
                            .read(activeTableProvider.notifier)
                            .setActiveTable(tableName);
                      },
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

// automatically refreshes when a record is saved
class CatchHistorySection extends ConsumerWidget {
  final String tableName;

  const CatchHistorySection({super.key, required this.tableName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // watching formSaveProvider will force table to refresh with data
    ref.watch(formSaveProvider);

    final projectAsync = ref.watch(projectViewModelProvider);

    return projectAsync.when(
      data: (project) {
        final table = project.tables[tableName];

        // if the table doesnt exist, show nothing
        if (table == null) return const SizedBox.shrink();

        try {
          // get database and build table widget
          final db = ref.read(projectDatabaseProvider);
          return CatchHistoryTable(db: db, table: table);
        } catch (_) {
          // if the database isnt open, show nothing
          return const SizedBox.shrink();
        }
      },

      error: (_, __) => const SizedBox.shrink(),
      loading: () => const SizedBox.shrink(),
    );
  }
}