import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crab_cakes/domain/models/project.dart';
import 'package:crab_cakes/infrastructure/providers/app_db_provider.dart';
import 'package:crab_cakes/presentation/utils/logger.dart';

class UpdateProjectScreen extends ConsumerStatefulWidget {
  final ProjectModel project;
  const UpdateProjectScreen({super.key, required this.project});

  @override
  ConsumerState<UpdateProjectScreen> createState() =>
      _ProjectCreationScreenState();
}

class _ProjectCreationScreenState extends ConsumerState<UpdateProjectScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _projectNameController;
  late TextEditingController _projectDescriptionController;

  bool isSubmitting = false;
  FilePickerResult? schemaFile;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    _projectNameController = TextEditingController(text: widget.project.title);
    _projectDescriptionController = TextEditingController(
      text: widget.project.description,
    );
  }

  @override
  void dispose() {
    _projectNameController.dispose();
    _projectDescriptionController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Update a Project')),
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
                  FloatingActionButton.extended(
                    onPressed: () async {
                      log.d("PROJECT NAME: ${_projectNameController.text}");
                      log.d(
                        "PROJECT DESCRIPTION: ${_projectDescriptionController.text}",
                      );

                      final result = await confirmUpdate(context);

                      if (result == true) {
                        var updatedProject = widget.project.copyWith(
                          title: _projectNameController.text,
                          description: _projectDescriptionController.text,
                        );

                        ref
                            .watch(projectListProvider.notifier)
                            .updateProject(project: updatedProject);

                        log.d("PROJECT UPDATED");
                      }
                      log.d("RESULT: $result");

                      if (!context.mounted) return;

                      Navigator.pop(context);
                    },
                    label: Text('Update Project'),
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

Future<bool> confirmUpdate(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text("Confirm Changes"),
        content: Text("Are you sure you want to edit this project?"),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context, true);
                      },
                      child: const Text("Update"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    },
  );

  return result ?? false;
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
