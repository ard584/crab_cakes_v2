import 'package:crab_cakes/domain/entities/settings/scanner_settings.dart';
import 'package:crab_cakes/domain/entities/settings/field_config_settings.dart';
import 'package:crab_cakes/domain/entities/settings/export_settings.dart';

class ProjectSettings {
  final ScannerSettings scanner;
  final FieldConfigSettings fieldConfig;
  final Map<String, List<String>> columnOrder;
  final ExportSettings export;


  const ProjectSettings({
    required this.scanner,
    required this.fieldConfig,
    this.columnOrder = const {},
    required this.export,
  });

  Map<String, dynamic> toJson() => {
    'scanner': scanner.toJson(),
    'fieldConfig': fieldConfig.toJson(),
    'columnOrder': columnOrder,
    'export':export.toJson(),
  };

  factory ProjectSettings.fromJson(Map<String, dynamic> json) {

    final scannerJson = json["scanner"] ?? {};
    final fieldConfigJson = json["fieldConfig"] ?? {};
    final columnOrderJson = json["columnOrder"] ?? {};
    final exportJson = json['export'] ?? {};

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
      export: ExportSettings.fromJson(
        exportJson is Map ? Map<String, dynamic>.from(exportJson) : {},
      ),
    );
  }

  ProjectSettings copyWith({ 
    ScannerSettings? scanner,
    FieldConfigSettings? fieldConfig,
    Map<String, List<String>>? columnOrder,
    ExportSettings? export,

    bool clearScannerSettings = false,
    bool clearFieldConfigSettings = false,
    bool clearColumnOrder = false,
    bool clearExportSettings = false,
    }) {
    return ProjectSettings(
      scanner: clearScannerSettings ? ScannerSettings.empty() : (scanner ?? this.scanner),
      fieldConfig: clearFieldConfigSettings ? FieldConfigSettings.empty() : (fieldConfig ?? this.fieldConfig),
      columnOrder: clearColumnOrder ? {} : (columnOrder ?? this.columnOrder),
      export: clearExportSettings ? ExportSettings.empty() : (export ?? this.export),
    );
  }

  factory ProjectSettings.empty() {
    return ProjectSettings(
      scanner: ScannerSettings.empty(),
      fieldConfig: FieldConfigSettings.empty(),
      columnOrder: {},
      export: ExportSettings.empty(),
    );
  }
}
