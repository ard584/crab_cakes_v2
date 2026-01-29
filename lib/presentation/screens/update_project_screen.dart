import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_prototype/presentation/models/project.dart';
import 'package:ui_prototype/presentation/utils/logger.dart';

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
    _projectDescriptionController = TextEditingController(text: widget.project.description);
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
                    onPressed: () {
                      log.d("PROJECT NAME: ${_projectNameController.text}");
                      log.d("PROJECT DESCRIPTION: ${_projectDescriptionController.text}");
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
