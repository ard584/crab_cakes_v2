import 'package:flutter/material.dart';
import 'package:ui_prototype/presentation/models/attribute.dart';
import 'package:ui_prototype/presentation/models/project_db.dart';

class AttributeInput {
  final Attribute fields;
  String? value;

  AttributeInput({required this.fields, this.value});
}

// UI State
class AttributeFormField {
  final AttributeInput input;
  final TextEditingController controller;

  AttributeFormField({required this.input})
      : controller = TextEditingController() {
    // Listen to changes in the text field
    controller.addListener(() {
      input.value = controller.text; // sync UI -> model
    });
  }
}


class ProjectInput {
  final String name;
  final ProjectDb project;
  final Map<String, TableInput> _tables = {};

  Map<String, TableInput> get tables => Map.unmodifiable(_tables);

  ProjectInput({required this.name, required this.project}) {


    // Iterate through keys
    for (final key in project.tables.keys) {

      // Get table
      final table = project.tables[key];

      if (table == null) {
        continue;
      }

      // Create empty attributes map
      final Map<String, AttributeFormField> attributeInputs = {};


      // Iterate through attributes
      for (final attribute in table.attributes) {

        // Create textEditingController, save attribute
        attributeInputs[attribute.name] = AttributeFormField(input: AttributeInput(fields: attribute));
        

      }

      // Create tableInput
      final tableInput = TableInput(name: table.name, attributes: attributeInputs);
      _tables[tableInput.name] = tableInput;

    }
  }
}

class TableInput {
  final String name;
  final Map<String, AttributeFormField> attributes;

  TableInput({required this.name, required this.attributes});
}