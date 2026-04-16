import 'package:ui_prototype/domain/entities/settings/scanner_settings.dart';
import 'package:ui_prototype/domain/entities/settings/field_config_settings.dart';

class ProjectSettings {
  final ScannerSettings scanner;
  final FieldConfigSettings fieldConfig;

  const ProjectSettings({
    required this.scanner,
    required this.fieldConfig,
  });

  Map<String, dynamic> toJson() => {
    'scanner': scanner.toJson(),
    'fieldConfig': fieldConfig.toJson(),
  };

  factory ProjectSettings.fromJson(Map<String, dynamic> json) {

    final scannerJson = json["scanner"] ?? {};
    final fieldConfigJson = json["fieldConfig"] ?? {};

    return ProjectSettings(
      scanner: ScannerSettings.fromJson(
        scannerJson is Map ? Map<String, dynamic>.from(scannerJson) : {},
      ),
      fieldConfig: FieldConfigSettings.fromJson(
        fieldConfigJson is Map ? Map<String, dynamic>.from(fieldConfigJson) : {},
      )
    );
  }

  ProjectSettings copyWith({ 
    ScannerSettings? scanner,
    FieldConfigSettings? fieldConfig,

    bool clearScannerSettings = false,
    bool clearFieldConfigSettings = false,
    }) {
    return ProjectSettings(
      scanner: clearScannerSettings ? ScannerSettings.empty() : (scanner ?? this.scanner),
      fieldConfig: clearFieldConfigSettings ? FieldConfigSettings.empty() : (fieldConfig ?? this.fieldConfig),
    );
  }

  factory ProjectSettings.empty() {
    return ProjectSettings(
      scanner: ScannerSettings.empty(),
      fieldConfig: FieldConfigSettings.empty(),
    );
  }
}
