import 'package:flutter/material.dart';
import 'package:ui_prototype/domain/models/attribute.dart';
import 'package:ui_prototype/domain/models/project_db.dart';

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
      final tableInput = TableInput(
        name: table.name,
        attributes: attributeInputs,
      );
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

  Map<String, dynamic> toValueMap() {
    final map = <String, dynamic>{};

    for (final entry in attributes.entries) {
      map[entry.key] = entry.value.controller.text;
    }

    return map;
  }

  bool allFieldsEmpty() {
    final fields = fieldCounts();

    if (fields.filled == 0) return true;
    return false;
  }

  ({int empty, int filled}) fieldCounts() {
    int emptyFieldCount = 0;
    int filledFieldCount = 0;

    // Iterate through attributes
    for (final attribute in attributes.entries) {
      // Get text of each controller, add counts to respective variables
      if (attribute.value.controller.text.trim().isEmpty) {
        emptyFieldCount += 1;
      } else {
        filledFieldCount += 1;
      }
    }

    // Format into record
    ({int empty, int filled}) record = (
      empty: emptyFieldCount,
      filled: filledFieldCount,
    );

    return record;
  }

  TableInput({required this.name, required this.attributes});
}
