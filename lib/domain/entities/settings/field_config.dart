class FieldConfig {
  final bool enableDropdown;
  final bool allowCustomValues;
  final bool isRequired;
  final List<String> options;
  final double? minValue;
  final double? maxValue;
  final String? helpText;

  FieldConfig({
    required this.enableDropdown,
    required this.allowCustomValues,
    required this.isRequired,
    required this.options,
    required this.minValue,
    required this.maxValue,
    required this.helpText,
    });
}