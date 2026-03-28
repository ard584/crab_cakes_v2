import 'package:ui_prototype/application/export/interfaces/save_location_picker.dart';
import 'package:file_selector/file_selector.dart';

class NativeSaveLocationPicker implements SaveLocationPicker {
  @override
  Future<String?> getLocation() async {
    final location = await getSaveLocation(
    suggestedName: 'data.csv',
    acceptedTypeGroups: [
      XTypeGroup(
        label: 'CSV Files',
        extensions: ['csv'],
      )
    ],
  );

  if(location == null) return null;

  return location.path;
  }
}