import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_prototype/infrastructure/providers/app_db_provider.dart';
import 'package:ui_prototype/presentation/utils/logger.dart';
import 'package:ui_prototype/presentation/services/projects/project_service.dart';

class ProjectCreationScreen extends ConsumerStatefulWidget {
  const ProjectCreationScreen({super.key});

  @override
  ConsumerState<ProjectCreationScreen> createState() =>
      _ProjectCreationScreenState();
}

class SchemaInputSelection extends StatefulWidget {
  final Schema selected;
  final ValueChanged<Schema> onChanged;

  const SchemaInputSelection({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  State<StatefulWidget> createState() => _SchemaInputSelectionState();
}

enum Schema { file, text }

class _SchemaInputSelectionState extends State<SchemaInputSelection> {
  Schema schemaInputType = Schema.text;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<Schema>(
      segments: <ButtonSegment<Schema>>[
        ButtonSegment<Schema>(value: Schema.file, label: Text('File')),
        ButtonSegment<Schema>(value: Schema.text, label: Text('Text')),
      ],
      selected: {widget.selected},
      onSelectionChanged: (Set<Schema> newSelection) {
        widget.onChanged(newSelection.first);
      },
    );
  }
}

class _ProjectCreationScreenState extends ConsumerState<ProjectCreationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _projectNameController = TextEditingController();
  final _projectDescriptionController = TextEditingController();

  // Need to get this to accept file input
  final _dbCreateSchema = TextEditingController();

  bool isSubmitting = false;
  Schema selectedSchema = Schema.text;
  FilePickerResult? schemaFile;

  void insertIntoDb() async {
    final title = _projectNameController.text;
    String sql = '';

    // Check file picker
    if (selectedSchema == Schema.text) {
      sql = _dbCreateSchema.text;
    } else {
      if (schemaFile == null || schemaFile!.files.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select a schema file")),
        );
        return;
      }
    }

    final file = schemaFile!.files.first;

    if (file.bytes != null) {
      sql = utf8.decode(file.bytes!);
    } else if (file.path != null) {
      final ioFile = io.File(file.path!);
      sql = await ioFile.readAsString();
    }

    log.d("SCHEMA: $sql");

    if (sql.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Schema cannot be empty")));
      }
      return;
    }

    final request = ProjectCreateRequest(title: title, sql: sql);

    log.d("NAME: ${_projectNameController.text}");
    log.d("DESCRIPTION: ${_projectDescriptionController.text}");
    log.d("SCHEMA: $sql");

    ref
        .read(projectListProvider.notifier)
        .createProject(
          title: request.title,
          description: request.description,
          sql: request.sql,
        );
  }

  @override
  void dispose() {
    _projectNameController.dispose();
    _projectDescriptionController.dispose();
    _dbCreateSchema.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create a Project')),
      body: Padding(
        padding: EdgeInsets.all(40.0),
        child: ListView(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 16.0),
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    decoration: reusableBoxDecoration,
                    child: TextFormField(
                      controller: _projectNameController,
                      decoration: getInputDecoration(labelText: 'Project Name'),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(bottom: 16.0),
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    decoration: reusableBoxDecoration,
                    child: TextFormField(
                      controller: _projectDescriptionController,
                      decoration: getInputDecoration(labelText: 'Description'),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(bottom: 16.0),
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: SchemaInputSelection(
                        selected: selectedSchema,
                        onChanged: (Schema newValue) {
                          setState(() {
                            selectedSchema = newValue;
                            log.d('SELECTED SCHEMA: $selectedSchema');
                          });
                        },
                      ),
                    ),
                  ),
                  Container(
                    child: switch (selectedSchema) {
                      Schema.text => Container(
                        margin: const EdgeInsets.only(bottom: 16.0),
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        decoration: reusableBoxDecoration,
                        child: TextFormField(
                          controller: _dbCreateSchema,
                          minLines: 3,
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          decoration: getInputDecoration(
                            labelText: 'SQLite Schema',
                          ),
                          style: TextStyle(fontFamily: 'JetBrains Mono'),
                        ),
                      ),
                      Schema.file => FloatingActionButton.extended(
                        onPressed: () async {
                          FilePickerResult? result = await FilePicker.platform
                              .pickFiles(
                                type: FileType.custom,
                                allowedExtensions: ['txt', 'sql'],
                                withData: true,
                              );

                          if (result != null) {
                            setState(() {
                              schemaFile = result;
                            });
                          }
                        },
                        label: Text('Upload File'),
                      ),
                    },
                  ),
                  FloatingActionButton.extended(
                    onPressed: insertIntoDb,
                    label: Text('Create Project'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final reusableBoxDecoration = BoxDecoration(
  color: Colors.grey.shade100, // Light background color
  borderRadius: BorderRadius.circular(10.0),
  border: Border.all(color: Colors.grey.shade300),
);

InputDecoration getInputDecoration({required String labelText}) {
  return InputDecoration(
    labelText: labelText,
    border: InputBorder.none,
    contentPadding: EdgeInsets.symmetric(vertical: 14.0),
  );
}
