import 'package:ui_prototype/domain/value_objects/save_file_type.dart';

abstract class SaveLocationPicker {
  Future<String?> getLocation({
    required String suggestedName,
    required SaveFileType type,
  });
}