import 'package:crab_cakes/presentation/components/pit_history_inline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:crab_cakes/domain/value_objects/parse_result.dart';

import 'package:crab_cakes/domain/entities/scan_event.dart';
import 'package:crab_cakes/domain/entities/settings/field_config.dart';

import 'package:crab_cakes/infrastructure/providers/flex_form_provider.dart';
import 'package:crab_cakes/infrastructure/providers/form_save_notifier.dart';
import 'package:crab_cakes/infrastructure/providers/pit_readers_providers.dart';
import 'package:crab_cakes/infrastructure/providers/project_database_provider.dart';
import 'package:crab_cakes/infrastructure/providers/field_config_providers.dart';
import 'package:crab_cakes/infrastructure/providers/data_entry_title_project_provider.dart';

import 'package:crab_cakes/presentation/screens/check_database_screen.dart';
import 'package:crab_cakes/presentation/screens/qaqc_screen.dart';
import 'package:crab_cakes/presentation/screens/export_screen.dart';
import 'package:crab_cakes/presentation/screens/field_config_screen.dart';

import 'package:crab_cakes/presentation/screens/project_selection.dart';
import 'package:crab_cakes/presentation/services/flex_field/flex_field_factory.dart';
import 'package:crab_cakes/presentation/view_models/project_input.dart';
import 'package:crab_cakes/presentation/components/catch_table_widget.dart';
import 'package:crab_cakes/presentation/shortcuts/data_entry_shortcuts.dart';
import 'package:crab_cakes/presentation/components/status_panel.dart';
import 'package:crab_cakes/presentation/components/table_switcher.dart';

import 'package:crab_cakes/infrastructure/providers/external_backup_provider.dart';
import 'package:crab_cakes/infrastructure/providers/settings_provider.dart';
import 'package:crab_cakes/infrastructure/providers/column_filter_provider.dart';

import 'package:crab_cakes/infrastructure/providers/sound_provider.dart';
import 'package:crab_cakes/domain/enums/app_sound.dart';

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
    scrollController.animateTo(
      0,
      duration: Duration(milliseconds: 150),
      curve: Curves.fastOutSlowIn,
    );
  }

  /// Method to centralize the save flow and allow it to be called from anywhere
  /// regardless of if its via the button or a short cut.
  Future<void> _saveRecordAndRunBackups() async {
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

    final activeTableName = ref.read(activeTableProvider);

    if (activeTableName == null) return;

    final table = projectMap.tables[activeTableName];
    if (table == null) return;

    // 1) Save record (this is where INSERT happens, inside saveTable)
    jumpToTop();

    //mark as user initiated save
    _saveTriggeredByUser = true;
    await ref.read(formSaveProvider.notifier).saveTable(table);

    // 2) Immediately run backup to selected drives
    // Force settings to reload so backup uses the latest saved export settings.
    ref.invalidate(projectSettingsProvider);

    final settings = await ref.read(projectSettingsProvider.future);

    final exportBaseTable = settings.export.baseTable;
    final exportDelimiter = settings.export.delimiter ?? '\t';

    await ref
        .read(backupActionsProvider.notifier)
        .backupCurrentProject(
          includeTextExport: exportBaseTable != null,
          baseTable: exportBaseTable,
          exportDelimiter: exportDelimiter,
        );

    scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 150),
      curve: Curves.fastOutSlowIn,
    );
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
            if (scannedId.isNotEmpty) {
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
        data: (_) {
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
      onSave: _saveRecordAndRunBackups,
      onTableSwitch: (index) {
        final projectMap = ref.read(projectViewModelProvider).value;
        if (projectMap == null) return;

        final tableNames = projectMap.tables.keys.toList();
        if (index < tableNames.length) {
          ref
              .read(activeTableProvider.notifier)
              .setActiveTable(tableNames[index]);
        }
      },
      child: FocusableActionDetector(
        autofocus: true,
        child: Scaffold(
          appBar: AppBar(
            title: Builder(
              builder: (context) {
                final projectName = ref.watch(currentProjectTitleProvider);
                final tableName = activeTableName ?? '';

                return Text(
                  tableName.isNotEmpty
                      ? '$projectName - $tableName'
                      : projectName,
                );
              },
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

                    ExpansionTile(
                      title: const Text(
                        'Scanner Status, Backups, and Catch History',
                      ),
                      initiallyExpanded: false,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Flexible(
                              flex: 1,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minWidth: 320,
                                  maxWidth: 520,
                                ),
                                child: const StatusPanel(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: Align(
                                alignment: Alignment.topRight,
                                child: CatchHistorySection(
                                  tableName: activeTableName,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Table switching
                    TableSwitcher(
                      tables: project.tables,
                      activeTableName: activeTableName,
                      showFKeyBadges: true,
                    ),
                    const SizedBox(height: 12),

                    Expanded(
                      child: Form(
                        key: _formKey,
                        child: TableFormSection(controller: scrollController),
                      ),
                    ),
                  ],
                );
              },

              // Handle error and loading states
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
          ),

          bottomNavigationBar: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FilledButton.icon(
                    onPressed: _saveRecordAndRunBackups,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save Record (F12)'),
                  ),
                ],
              ),
            ),
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
      return Center(child: CircularProgressIndicator());
    }

    final table = project?.tables[tableName];

    if (table == null) {
      return Center(child: Text("Table is null"));
    }

    // Get filter setting from provider
    final hideDoubleUnderscore = ref.watch(hideDoubleUnderscoreColumnsProvider);

    // Apply filter based on provider setting

    // Get the fields that should appear on the form.

    // Get the fields that should appear on the form.
    final fields = table.attributes.values.where((attribute) {
      final name = attribute.fields.name;

      // Hide internal database fields.
      if (hideDoubleUnderscore && name.startsWith(kColumnPrefixToHide)) {
        return false;
      }

      // Hide automatically generated record IDs.
      if (name == 'ID' &&
          attribute.fields.isPrimaryKey &&
          attribute.fields.dataType.toUpperCase() == 'INTEGER') {
        return false;
      }

      return true;
    }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Show more columns on larger screens.
        int columnCount = 1;

        if (constraints.maxWidth >= 1600) {
          columnCount = 5;
        } else if (constraints.maxWidth >= 1250) {
          columnCount = 4;
        } else if (constraints.maxWidth >= 900) {
          columnCount = 3;
        } else if (constraints.maxWidth >= 600) {
          columnCount = 2;
        }

        const spacing = 10.0;

        final fieldWidth =
            (constraints.maxWidth - spacing * (columnCount - 1)) / columnCount;

        // Track which fields have already been displayed.
        final usedFields = <String>{};

        // Get fields in the requested order.
        List<AttributeFormField> getFields(List<String> names) {
          final selected = <AttributeFormField>[];

          for (final name in names) {
            for (final field in fields) {
              if (field.fields.name == name && !usedFields.contains(name)) {
                selected.add(field);
                usedFields.add(name);
              }
            }
          }

          return selected;
        }

        // Build one section of the form.
        Widget buildSection(
          String title,
          List<AttributeFormField> sectionFields,
        ) {
          if (sectionFields.isEmpty) {
            return const SizedBox.shrink();
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),

                const SizedBox(height: 8),

                Wrap(
                  spacing: spacing,
                  runSpacing: 8,
                  children: sectionFields.map((attribute) {
                    return SizedBox(
                      width: fieldWidth,
                      child: DynamicFlexField(
                        tableName: tableName,
                        attribute: attribute,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        }

        final sections = <Widget>[];

        if (tableName == 'SPECIMEN') {
          // Fish information comes first during fieldwork.
          sections.add(
            buildSection(
              'Fish Information',
              getFields([
                'PIT_TAG',
                'SPECIES',
                'LENGTH_MM',
                'FORK_LENGTH_MM',
                'WEIGHT_G',
              ]),
            ),
          );

          // Display test history directly in the specimen form.
          final pitTagField = table.attributes['PIT_TAG'];

          if (pitTagField != null) {
            sections.add(
              PitHistoryInline(
                tagController: pitTagField.controller,
              ),
            );
          }

          // Information connecting the fish to its survey.
          sections.add(
            buildSection(
              'Survey Information',
              getFields(['SAMPLE_ID', 'SURVEY_DATE', 'LOCATION', 'GEAR_TYPE']),
            ),
          );
        } else if (tableName == 'SAMPLE') {
          // Main information recorded for each sample.
          sections.add(
            buildSection(
              'Sample Information',
              getFields([
                'TRIP_ID',
                'SAMPLE_TYPE',
                'SURVEY_DATE',
                'LOCATION',
                'GEAR_TYPE',
                'SITE_ID',
                'RIVER_MILE',
                'START_TIME',
                'END_TIME',
              ]),
            ),
          );
        }

        // Keep all remaining fields available.
        final remainingFields = fields.where((field) {
          return !usedFields.contains(field.fields.name);
        }).toList();

        sections.add(
          buildSection(
            tableName == 'SPECIMEN'
                ? 'Additional Fish Information'
                : 'Additional Sample Information',
            remainingFields,
          ),
        );

        return SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: sections,
          ),
        );
      },
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
    final fieldConfigAsync = ref.watch(
      effectiveFieldConfigProvider(
        FieldConfigKey(tableName: tableName, colName: attribute.fields.name),
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
    if (fkInfo != null) {
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

    // Give common survey fields readable labels.
    const fieldLabels = {
      'SAMPLE_ID': 'Sample ID',
      'TRIP_ID': 'Trip ID',
      'SITE_ID': 'Site ID',
      'PIT_TAG': 'PIT Tag',
      'SPECIES': 'Species',
      'LENGTH_MM': 'Total Length (mm)',
      'FORK_LENGTH_MM': 'Fork Length (mm)',
      'WEIGHT_G': 'Weight (g)',
      'SURVEY_DATE': 'Survey Date',
      'LOCATION': 'Location',
      'GEAR_TYPE': 'Gear Type',
      'SAMPLE_TYPE': 'Sample Type',
      'RIVER_MILE': 'River Mile',
      'START_TIME': 'Start Time',
      'END_TIME': 'End Time',
    };

    final fieldName = attribute.fields.name;

    // Format any other field names automatically.
    final readableName =
        fieldLabels[fieldName] ??
        fieldName
            .toLowerCase()
            .split('_')
            .map((word) {
              if (word.isEmpty) return '';
              return word[0].toUpperCase() + word.substring(1);
            })
            .join(' ');

    final config = FlexFieldConfig(
      label: readableName,
      dataType: attribute.fields.dataType,
      settings: fieldConfig,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
      child: FlexFieldFactory.createField(
        config: config,
        controller: attribute.controller,
        baseDecoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 10,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
    );
  }
}

class DrawerSubmenu extends StatelessWidget {
  const DrawerSubmenu({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        ListTile(
          leading: Icon(Icons.home, color: colorScheme.primary),
          title: Text(
            "Switch Project",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: colorScheme.primary,
            ),
          ),
          subtitle: const Text("Return to project selection"),
          tileColor: colorScheme.primaryContainer.withValues(alpha: 0.35),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProjectSelection()),
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
              MaterialPageRoute(builder: (context) => CheckDatabaseScreen()),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.bar_chart),
          title: const Text("QA/QC Graphs"),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const QaqcScreen()),
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
          leading: const Icon(Icons.build),
          title: const Text("Field Config"),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => FieldConfigScreen()),
            );
          },
        ),
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
