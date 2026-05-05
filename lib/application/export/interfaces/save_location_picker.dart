import 'package:crab_cakes/domain/value_objects/save_file_type.dart';

abstract class SaveLocationPicker {
  Future<String?> getLocation({
    required String suggestedName,
    required SaveFileType type,
  });
}