import 'package:flutter/material.dart';
import 'package:ui_prototype/presentation/models/attribute.dart';
import 'package:ui_prototype/presentation/models/project_db.dart';

// UI State
class AttributeFormField {
  final Attribute fields;
  final TextEditingController controller;

  AttributeFormField({required this.fields})
      : controller = TextEditingController();
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
        attributeInputs[attribute.name] = AttributeFormField(fields: attribute);
        

      }

      // Create tableInput
      final tableInput = TableInput(name: table.name, attributes: attributeInputs);
      _tables[tableInput.name] = tableInput;

    }
  }

  void disposeControllers() {
    for (final table in _tables.values) {
      for (final attribute in table.attributes.values) {
        attribute.controller.dispose();
      }
    }
  }
}

class TableInput {
  final String name;
  final Map<String, AttributeFormField> attributes;

  TableInput({required this.name, required this.attributes});
}