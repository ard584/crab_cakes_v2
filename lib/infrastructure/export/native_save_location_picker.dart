import 'package:ui_prototype/application/export/interfaces/save_location_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:ui_prototype/domain/value_objects/save_file_type.dart';

typedef SaveLocationSelector = Future<FileSaveLocation?> Function({
  required String suggestedName,
  required List<XTypeGroup> acceptedTypeGroups,
});

class NativeSaveLocationPicker implements SaveLocationPicker {
  final SaveLocationSelector _getSaveLocation;

  NativeSaveLocationPicker({
    SaveLocationSelector? getSaveLocationOverride,
  }) : _getSaveLocation = getSaveLocationOverride ?? getSaveLocation;

  @override
  Future<String?> getLocation({
    required String suggestedName,
    required SaveFileType type,
  }) async {
    final typeGroup = _typeGroupFor(type);

    final location = await _getSaveLocation(
      suggestedName: suggestedName,
      acceptedTypeGroups: [
        typeGroup,
      ],
    );

    if (location == null) return null;

    return location.path;
  }

  XTypeGroup _typeGroupFor(SaveFileType type) {
    switch (type) {
      case SaveFileType.csv:
        return XTypeGroup(
          label: 'CSV Files',
          extensions: ['csv'],
          mimeTypes: ['text/csv'],
        );
      case SaveFileType.json:
        return XTypeGroup(
          label: 'JSON Files',
          extensions: ['json'],
          mimeTypes: ['application/json'],
        );
      case SaveFileType.txt:
        return XTypeGroup(
          label: 'Text Files',
          extensions: ['txt'],
          mimeTypes: ['txt'],
        );
    }
  }
}