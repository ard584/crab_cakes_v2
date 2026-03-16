import 'package:ui_prototype/application/export/interfaces/data_exporter.dart';
import 'package:ui_prototype/application/export/interfaces/save_location_picker.dart';

class ExportData {
  final DataExporter exporter;
  final SaveLocationPicker picker;

  ExportData(this.picker, this.exporter);

  
  Future<void> execute(String tableName) async {
    final filePath = await picker.getLocation();

    if(filePath == null) return;

    await exporter.export(tableName, filePath);
  }
}