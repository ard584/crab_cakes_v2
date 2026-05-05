import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crab_cakes/infrastructure/project/project_json_integrity_service.dart';
import 'package:crab_cakes/infrastructure/providers/app_db_provider.dart';
import 'package:crab_cakes/presentation/utils/logger.dart';
import 'package:crab_cakes/presentation/services/projects/project_service.dart';

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

enum Schema { file, text, json }

class _SchemaInputSelectionState extends State<SchemaInputSelection> {
  Schema schemaInputType = Schema.text;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<Schema>(
      segments: <ButtonSegment<Schema>>[
        ButtonSegment<Schema>(value: Schema.file, label: Text('File')),
        ButtonSegment<Schema>(value: Schema.text, label: Text('Text')),
        ButtonSegment<Schema>(
          value: Schema.json,
          label: Text('Import JSON'),
        ),
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
  FilePickerResult? projectJsonFile;

  Future<String> _readPickedFileAsString(FilePickerResult pickedFile) async {
    final file = pickedFile.files.first;

    if (file.bytes != null) {
      return utf8.decode(file.bytes!);
    } else if (file.path != null) {
      final ioFile = io.File(file.path!);
      return await ioFile.readAsString();
    }

    return '';
  }

  Future<bool> insertIntoDb() async {
    final title = _projectNameController.text;
    final description = _projectDescriptionController.text;

    if (title.trim().isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Project name cannot be empty")),
        );
      }
      return false;
    }

    if (selectedSchema == Schema.json) {
      if (projectJsonFile == null || projectJsonFile!.files.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select a project JSON file")),
        );
        return false;
      }

      final jsonString = await _readPickedFileAsString(projectJsonFile!);

      if (jsonString.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Project JSON cannot be empty")),
          );
        }
        return false;
      }

      log.d("NAME: ${_projectNameController.text}");
      log.d("DESCRIPTION: ${_projectDescriptionController.text}");
      log.d("PROJECT JSON: $jsonString");

      await ref
          .read(projectListProvider.notifier)
          .importProject(
            title: title,
            description: description,
            jsonString: jsonString,
          );

      return true;
    }

    String sql = '';

    // Check file picker
    if (selectedSchema == Schema.text) {
      sql = _dbCreateSchema.text;
    } else {
      if (schemaFile == null || schemaFile!.files.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select a schema file")),
        );
        return false;
      }
    }

    if (selectedSchema == Schema.file) {
      sql = await _readPickedFileAsString(schemaFile!);
    }

    log.d("SCHEMA: $sql");

    if (sql.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Schema cannot be empty")),
        );
      }
      return false;
    }

    final request = ProjectCreateRequest(
      title: title,
      description: description,
      sql: sql,
    );

    log.d("NAME: ${_projectNameController.text}");
    log.d("DESCRIPTION: ${_projectDescriptionController.text}");
    log.d("SCHEMA: $sql");

    await ref
        .read(projectListProvider.notifier)
        .createProject(
          title: request.title,
          description: request.description,
          sql: request.sql,
        );

    return true;
  }

  String _getProjectCreationErrorMessage(Object error) {
    if (error is ProjectJsonIntegrityException) {
      return 'Project Settings file failed validation check. '
          'The file may have been modified, corrupted, or exported by an incompatible version of the app.';
    }

    return 'Failed to create project: $error';
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
                      Schema.file => Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Column(
                          children: [
                            FloatingActionButton.extended(
                              onPressed: () async {
                                FilePickerResult? result = await FilePicker
                                    .platform
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
                            if (schemaFile != null &&
                                schemaFile!.files.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  'Selected: ${schemaFile!.files.first.name}',
                                ),
                              ),
                          ],
                        ),
                      ),
                      Schema.json => Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Column(
                          children: [
                            Container(
                              margin: const EdgeInsets.only(bottom: 16.0),
                              padding: const EdgeInsets.all(12.0),
                              decoration: reusableBoxDecoration,
                              child: const Text(
                                'Upload an exported project JSON file to recreate the project schema and settings. '
                                'This does not preserve the original project data.',
                              ),
                            ),
                            FloatingActionButton.extended(
                              onPressed: () async {
                                FilePickerResult? result = await FilePicker
                                    .platform
                                    .pickFiles(
                                      type: FileType.custom,
                                      allowedExtensions: ['json'],
                                      withData: true,
                                    );

                                if (result != null) {
                                  setState(() {
                                    projectJsonFile = result;
                                  });
                                }
                              },
                              label: Text('Upload Project JSON'),
                            ),
                            if (projectJsonFile != null &&
                                projectJsonFile!.files.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  'Selected: ${projectJsonFile!.files.first.name}',
                                ),
                              ),
                          ],
                        ),
                      ),
                    },
                  ),

                  const SizedBox(height: 24.0),

                  FloatingActionButton.extended(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            setState(() {
                              isSubmitting = true;
                            });

                            try {
                              final success = await insertIntoDb();

                              if (success && context.mounted) {
                                Navigator.pop(context);
                              }
                            } catch (error) {
                                log.d("PROJECT CREATION ERROR: $error");

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(_getProjectCreationErrorMessage(error)),
                                    ),
                                  );
                                }
                              } finally {
                                if (context.mounted) {
                                  setState(() {
                                    isSubmitting = false;
                                  });
                                }
                            }
                          },

                    label: Text(isSubmitting ? 'Creating...' : 'Create Project'),
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