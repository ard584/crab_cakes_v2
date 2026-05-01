import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ui_prototype/domain/value_objects/parse_result.dart';

import 'package:ui_prototype/domain/entities/scan_event.dart';
import 'package:ui_prototype/domain/entities/settings/field_config.dart';

import 'package:ui_prototype/infrastructure/providers/flex_form_provider.dart';
import 'package:ui_prototype/infrastructure/providers/form_save_notifier.dart';
import 'package:ui_prototype/infrastructure/providers/pit_readers_providers.dart';
import 'package:ui_prototype/infrastructure/providers/project_database_provider.dart';
import 'package:ui_prototype/infrastructure/providers/field_config_providers.dart';

import 'package:ui_prototype/presentation/screens/check_database_screen.dart';
import 'package:ui_prototype/presentation/screens/export_screen.dart';
import 'package:ui_prototype/presentation/screens/field_config_screen.dart';

import 'package:ui_prototype/presentation/screens/project_selection.dart';
import 'package:ui_prototype/presentation/services/flex_field/flex_field_factory.dart';
import 'package:ui_prototype/presentation/view_models/project_input.dart';
import 'package:ui_prototype/presentation/components/catch_table_widget.dart';
import 'package:ui_prototype/presentation/shortcuts/data_entry_shortcuts.dart';
import 'package:ui_prototype/presentation/components/status_panel.dart';

import 'package:ui_prototype/infrastructure/providers/external_backup_provider.dart';
import 'package:ui_prototype/infrastructure/providers/active_database_connection_provider.dart';
import 'package:ui_prototype/infrastructure/providers/settings_provider.dart';
import 'package:ui_prototype/infrastructure/providers/column_filter_provider.dart';

import 'package:ui_prototype/infrastructure/providers/sound_provider.dart';
import 'package:ui_prototype/domain/enums/app_sound.dart';

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
  final ScrollController scrollController = ScrollController();
  final _formKey = GlobalKey<FormState>();
  //used to track if save was used by the user
  //needed this because the sound would trigger due to existing provider state
  bool _saveTriggeredByUser = false;

  void jumpToTop() {
    scrollController.animateTo(0, duration: Duration(milliseconds: 150), curve: Curves.fastOutSlowIn);
  }

  @override
  Widget build(BuildContext context) {
    final projectAsync = ref.watch(projectViewModelProvider);
    final project = ref.watch(projectViewModelProvider).value;

    final activeTableName = ref.watch(activeTableProvider);
    final activeTable = project?.tables[activeTableName];
    final fieldList = activeTable?.attributes.values.toList();

    
    //setting up the stream subscription for scan detection
    ref.listen(scanEventProvider, (prev, next) {
      next.whenData((parseResult) {
        if (parseResult is! ParseOk<ScanEvent>) return;

        final scan = parseResult.value;

        final settings = ref.read(projectSettingsProvider).value;
        final targetTable = settings?.scanner.targetTable;
        final targetCol = settings?.scanner.targetColumn;

        if (targetTable == null || targetCol == null) return;
        if (targetTable != activeTableName) return;
        if (fieldList == null) return;

        for (final field in fieldList) {
          if (field.fields.name == targetCol) {
            //local variable to hold pit tag
            final scannedId = scan.id ?? "";
            field.controller.text = scan.id ?? ""; 
               
            //if there is a valid scan play the tag accepted sound
            //Needs to be tested with pit tag reader
            if (scannedId.isNotEmpty) 
            {
              ref.read(soundServiceProvider).play(AppSound.tagAccepted);
            }

            break;
          }
        }
      });
    });

    // Set activeProject state
    projectAsync.whenData((project) {});

    // Snack bar updates
    ref.listen<AsyncValue<void>>(formSaveProvider, (previous, next) {
      //ignore events not triggered b user
      if (!_saveTriggeredByUser) return;

      next.whenOrNull(
        data: (_){
          //reset flag
          _saveTriggeredByUser = false;
          //success alert
          ref.read(soundServiceProvider).play(AppSound.recordSavedOk);
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text("Recorded")));
          }
        },
        error: (e, st) {
          //reset flag
          _saveTriggeredByUser = false;
          //failure alert
          ref.read(soundServiceProvider).play(AppSound.recordSaveFailed);
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

      //validate: ensure no required or incorrect fields are present
      final isValid = _formKey.currentState?.validate() ?? false;
      if (!isValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please correct the highlighted fields before saving.'),
          ),
        );
        return;
      }

      //mark the save as user initiated
      _saveTriggeredByUser = true;
      await ref.read(formSaveProvider.notifier).saveTable(table);
      jumpToTop();
    },
    child: Scaffold(
      appBar: AppBar(
        title: projectAsync.when(
          data: (project) => Text(activeTableName ?? 'Data Entry'),
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
                //made it a row to show status on the left followed by table on the
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const StatusPanel(),
                    const SizedBox(width: 12),
                    // push table to right
                    const Spacer(), 
                    CatchHistorySection(tableName: activeTableName),

                  ]
                ),
                const SizedBox(height: 16),
                
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: TableFormSection(controller: scrollController,),
                  ),
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

          //validating the form before submission. Invalid should already be 
          //marked in read 
          final isValid = _formKey.currentState?.validate() ?? false;
          if (!isValid) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please correct the highlighted fields before saving.'),
              ),
            );
            return;
          }

          final projectMap = ref.read(projectViewModelProvider).value;

          if (projectMap == null) return;
          if (activeTableName == null) return;

          final table = projectMap.tables[activeTableName];
          if (table == null) return;

          // 1) Save record (this is where INSERT happens, inside saveTable)
          jumpToTop();
          //mark as user initiated save
          _saveTriggeredByUser = true;
          await ref.read(formSaveProvider.notifier).saveTable(table);

          // 2) Immediately run backup to selected drives
          final settings = await ref.read(projectSettingsProvider.future);

          final exportBaseTable = settings.export.baseTable;
          final exportDelimiter = settings.export.delimiter ?? '\t';

          await ref.read(backupActionsProvider.notifier).backupCurrentProject(
            includeTextExport: exportBaseTable != null,
            baseTable: exportBaseTable,
            exportDelimiter: exportDelimiter,
          );

          scrollController.animateTo(
              0,
              duration: Duration(milliseconds: 150),
              curve: Curves.fastOutSlowIn,
            );
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

class _TableFormSectionState extends ConsumerState<TableFormSection> {
  late final ScrollController? _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller;
  }

  @override
  Widget build(BuildContext context) {
    final project = ref.watch(projectViewModelProvider).value;
    final tableName = ref.watch(activeTableProvider);

    if (tableName == null) {
      return Center(child: CircularProgressIndicator(),);
    }

    final table = project?.tables[tableName];

    if (table == null) {
      return Center(child: Text("Table is null"));
    }

    // Get filter setting from provider
    final hideDoubleUnderscore = ref.watch(hideDoubleUnderscoreColumnsProvider);

    // Apply filter based on provider setting
    final attrbutes = hideDoubleUnderscore
        ? table.attributes.values.where((a) => !a.fields.name.startsWith(kColumnPrefixToHide)).toList()
        : table.attributes.values.toList();

    return ListView.builder(
      itemCount: attrbutes.length,
      itemBuilder: (context, index) {
        final attribute = attrbutes[index];

        return DynamicFlexField(tableName: tableName, attribute: attribute);
      },
      controller: _scrollController,
    );
  }
}

class TableFormSection extends ConsumerStatefulWidget {
  final ScrollController? controller;
  const TableFormSection({super.key, this.controller});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _TableFormSectionState();
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


    //Fetch the domain-level configuration for this specific field
    final fieldConfigAsync =  ref.watch(
      effectiveFieldConfigProvider(
        FieldConfigKey(
          tableName: tableName,
          colName: attribute.fields.name,
        ),
      ),
    );

    var fieldConfig = fieldConfigAsync.when(
      data: (config) => config,
      loading: () => FieldConfig.defaultInstance(),
      error: (_, __) => FieldConfig.defaultInstance(),
    );

    //checking if this field is meant to be hidden
    if (fieldConfig.isHidden) {
      return const SizedBox.shrink();
    }

    //gathering reference table options only if the specific field is a Foreign Key (FK)
    final fkInfo = attribute.fields.fkInfo;
    if(fkInfo != null) {
      final repo = ref.watch(projectDatabaseProvider);
      final rows = repo.getAllRows(fkInfo.referencedTable);

      final options = rows
      .map((row) => row.values[fkInfo.referencedColumn])
      .where((value) => value != null)
      .map((value) => value.toString())
      .toSet() // removes duplicates
      .toList();

      //copying the field config created earlier, but with the parent drop down options
      fieldConfig = fieldConfig.copyWith(
        options: options, 
        useDropdown: true,
        allowCustomValues: true,
        isSticky: true,
      );
    }

    //defining the FlexFieldConfig object with the domain-level config added 
    final config = FlexFieldConfig(
      label: attribute.fields.name,
      dataType: attribute.fields.dataType,
      settings: fieldConfig,
    );

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
        config: config,

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
                builder: (context) => CheckDatabaseScreen(),
              ),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.build),
          title: const Text("Field Config"),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FieldConfigScreen(),
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
