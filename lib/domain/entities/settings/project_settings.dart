import 'package:ui_prototype/domain/entities/settings/scanner_settings.dart';
import 'package:ui_prototype/domain/entities/settings/field_config_settings.dart';

class ProjectSettings {
  final ScannerSettings scanner;
  final FieldConfigSettings fieldConfig;
  final Map<String, List<String>> columnOrder;

  const ProjectSettings({
    required this.scanner,
    required this.fieldConfig,
    this.columnOrder = const {},
  });

  Map<String, dynamic> toJson() => {
    'scanner': scanner.toJson(),
    'fieldConfig': fieldConfig.toJson(),
    'columnOrder': columnOrder,
  };

  factory ProjectSettings.fromJson(Map<String, dynamic> json) {

    final scannerJson = json["scanner"] ?? {};
    final fieldConfigJson = json["fieldConfig"] ?? {};
    final columnOrderJson = json["columnOrder"] ?? {};

    return ProjectSettings(
      scanner: ScannerSettings.fromJson(
        scannerJson is Map ? Map<String, dynamic>.from(scannerJson) : {},
      ),
      fieldConfig: FieldConfigSettings.fromJson(
        fieldConfigJson is Map ? Map<String, dynamic>.from(fieldConfigJson) : {},
      ),
      columnOrder: columnOrderJson is Map
          ? Map<String, dynamic>.from(columnOrderJson).map((key, value) => MapEntry(
                key,
                value is List ? List<String>.from(value) : <String>[],
              ))
          : {},
    );
  }

  ProjectSettings copyWith({ 
    ScannerSettings? scanner,
    FieldConfigSettings? fieldConfig,
    Map<String, List<String>>? columnOrder,

    bool clearScannerSettings = false,
    bool clearFieldConfigSettings = false,
    }) {
    return ProjectSettings(
      scanner: clearScannerSettings ? ScannerSettings.empty() : (scanner ?? this.scanner),
      fieldConfig: clearFieldConfigSettings ? FieldConfigSettings.empty() : (fieldConfig ?? this.fieldConfig),
      columnOrder: columnOrder ?? this.columnOrder,
    );
  }

  factory ProjectSettings.empty() {
    return ProjectSettings(
      scanner: ScannerSettings.empty(),
      fieldConfig: FieldConfigSettings.empty(),
      columnOrder: {},
    );
  }
}
