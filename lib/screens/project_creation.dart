import 'package:flutter/material.dart';

class ProjectCreationScreen extends StatefulWidget {
  @override
  State<ProjectCreationScreen> createState() => _ProjectCreationScreenState();
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

class _ProjectCreationScreenState extends State<ProjectCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final String projectName = '';
  final String? projectDescription = '';
  final String? dbPath = '';
  bool isSubmitting = false;
  Schema selectedSchema = Schema.text;

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
                      decoration: getInputDecoration(labelText: 'Project Name'),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(bottom: 16.0),
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    decoration: reusableBoxDecoration,
                    child: TextFormField(
                      decoration: getInputDecoration(labelText: 'Description'),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: SchemaInputSelection(
                      selected: selectedSchema,
                      onChanged: (Schema newValue) {
                        setState(() {
                          selectedSchema = newValue;
                          print('SELECTED SCHEMA: $selectedSchema');
                        });
                      },
                    ),
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
