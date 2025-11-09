import 'package:flutter/services.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

typedef ValidatorList = List<String? Function(String?)>;

// Generic implementation of FlexField - extensible field system
abstract class FlexFieldConfig {
  final String label;
  final ValidatorList? inputValidators;
  final List<TextInputFormatter>? inputFormatters;

  const FlexFieldConfig({
    required this.label,
    this.inputValidators,
    this.inputFormatters,
  });
}

// Simple text field
class TextFieldConfig extends FlexFieldConfig {
  const TextFieldConfig({
    required super.label,
    super.inputValidators,
    super.inputFormatters, // Inherited and available
  });
}

// Numeric field
class NumericFieldConfig extends FlexFieldConfig {
  NumericFieldConfig({
    required super.label,
    ValidatorList? extraValidators,
    super.inputFormatters, // Inherited and available
  }) : super(
         inputValidators: [
           FormBuilderValidators.numeric(
             errorText: 'Please enter a valid number.',
           ),
           ...?extraValidators,
         ],
       );
}
