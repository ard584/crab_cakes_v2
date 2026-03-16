import 'package:ui_prototype/domain/entities/settings/scanner_settings.dart';

class ProjectSettings {
  final ScannerSettings scanner;

  const ProjectSettings({
    required this.scanner,
  });

  Map<String, dynamic> toJson() => {
    'scanner': scanner.toJson(),
  };

  factory ProjectSettings.fromJson(Map<String, dynamic> json) {
    return ProjectSettings(
      scanner: ScannerSettings.fromJson(
        (json['scanner'] as Map<String, dynamic>?) ?? {},
      ),
    );
  }

  ProjectSettings copyWith({ ScannerSettings? scanner}) {
    return ProjectSettings(scanner: scanner ?? this.scanner);
  }
}
