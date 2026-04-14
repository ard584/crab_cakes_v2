import 'package:ui_prototype/application/export/interfaces/save_location_picker.dart';
import 'package:file_selector/file_selector.dart';

class NativeSaveLocationPicker implements SaveLocationPicker {
  @override
  Future<String?> getLocation() async {
    final location = await getSaveLocation(
    suggestedName: 'data',
    acceptedTypeGroups: [
      XTypeGroup(
        label: 'Text File',
        extensions: ['txt'],
      )
    ],
  );

  if(location == null) return null;

  return location.path;
  }
}