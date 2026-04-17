class FieldConfig {
  final bool useDropdown;
  final bool allowCustomValues;
  final bool isRequired;
  final bool showInCatchHistory;
  final List<String> options; //these are the values added by the user to be selected from in the field
  final num? minValue;
  final num? maxValue;
  final String? helpText;

  FieldConfig({
    required this.useDropdown,
    required this.allowCustomValues,
    required this.isRequired,
    this.showInCatchHistory = false,
    List<String>? options,
    required this.minValue,
    required this.maxValue,
    required this.helpText,
    }) : options = options ?? [];

  Map<String, dynamic> toJson() => {

    'useDropdown':useDropdown,
    'allowCustomValues':allowCustomValues,
    'isRequired':isRequired,
    'showInCatchHistory':showInCatchHistory,
    'options':options,
    'minValue':minValue,
    'maxValue':maxValue,
    'helpText':helpText,
    
  };

  //defining how the config class reads the json and creates an instance of itself
  factory FieldConfig.fromJson(Map<String, dynamic> json) {
    return FieldConfig(
      useDropdown: json['useDropdown'] ?? false,
      allowCustomValues: json['allowCustomValues'] ?? true,
      isRequired: json['isRequired'] ?? false,
      showInCatchHistory: json['showInCatchHistory'] as bool? ?? false,
      options: List<String>.from(json['options'] ?? []),
      minValue: json['minValue'],
      maxValue: json['maxValue'],
      helpText: json['helpText'],
    );
  }

  //copywith helper to allow caller to create a new instance changing only the specified attributes
  FieldConfig copyWith({
     bool? useDropdown,
     bool? allowCustomValues,
     bool? isRequired,
     bool? showInCatchHistory,
    List<String>? options,
    num? minValue,
    num? maxValue,
    String? helpText,

    bool clearOptions = false,
    bool clearMinMax = false,
    bool clearHelpText = false,
  }) {
    return FieldConfig(
      useDropdown: useDropdown ?? this.useDropdown,
      allowCustomValues: allowCustomValues ?? this.allowCustomValues,
      isRequired: isRequired ?? this.isRequired,
      showInCatchHistory: showInCatchHistory ?? this.showInCatchHistory,
      options: clearOptions ? null : (options ?? this.options),
      minValue: clearMinMax ? null : (minValue ?? this.minValue),
      maxValue: clearMinMax ? null : (maxValue ?? this.maxValue),
      helpText: clearHelpText ? null : (helpText ?? this.helpText),
    );
  }

  //creating a single default preset used whenever default presets are needed
  static final FieldConfig _defaultInstance = FieldConfig(
    useDropdown: false,
    allowCustomValues: true,
    isRequired: false,
    showInCatchHistory: false,
    options: const [],
    minValue: null,
    maxValue: null,
    helpText: null,    
  );

  factory FieldConfig.defaultInstance() {
    return _defaultInstance;
  }
}