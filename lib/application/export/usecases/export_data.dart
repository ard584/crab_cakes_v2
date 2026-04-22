import 'package:ui_prototype/application/export/interfaces/data_exporter.dart';
import 'package:ui_prototype/application/export/interfaces/save_location_picker.dart';
import 'package:ui_prototype/domain/value_objects/save_file_type.dart';

class ExportData {
  final DataExporter exporter;
  final SaveLocationPicker picker;

  ExportData(this.picker, this.exporter);

  
  Future<void> execute(String tableName, String delimiter) async {
    final filePath = await picker.getLocation(
      suggestedName: "data",
      type: SaveFileType.txt,
    );

    if(filePath == null) return;

    await exporter.export(tableName, filePath, delimiter);
  }
}