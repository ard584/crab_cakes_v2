import 'package:flutter/material.dart';

class FlexFieldFactory {
  static Widget createField({
    required FlexFieldConfig config,
    required TextEditingController controller,
    InputDecoration? baseDecoration,
  }) {
    // Figure out correct keyboard type
    TextInputType keyboardType = TextInputType.text;
    if (config.dataType == 'INTEGER' || config.dataType == 'REAL') {
      keyboardType = TextInputType.number;
    }

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: (baseDecoration ?? InputDecoration()).copyWith(
        labelText: config.label,
        hintText: config.defaultValue,
      )
    );
  }
}

// Basic type for figuring out correct field config
// TODO: Determine if this is redundant compared to Attribute model
class FlexFieldConfig {
  final String label;

  final String dataType;
  final bool isRequired;
  final String? defaultValue;

  FlexFieldConfig({
    required this.label,
    required this.dataType,
    required this.isRequired,
    this.defaultValue,
  });
}
