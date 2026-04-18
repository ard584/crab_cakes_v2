import 'package:ui_prototype/application/settings/interfaces/project_settings_exporter.dart';
import 'package:ui_prototype/application/export/interfaces/save_location_picker.dart';
import 'package:ui_prototype/domain/value_objects/save_file_type.dart';

class ExportSettings {

  final ProjectSettingsExporter exporter;
  final SaveLocationPicker saveLocationPicker;

  ExportSettings(this.exporter, this.saveLocationPicker);

  Future<void> execute() async {

    final filePath = await saveLocationPicker.getLocation(
        suggestedName: 'project_settings.json',
        type: SaveFileType.json,
    );

    if(filePath == null) return;

    exporter.export(filePath);
  }
}