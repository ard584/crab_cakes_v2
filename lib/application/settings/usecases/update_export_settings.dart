import 'package:ui_prototype/application/settings/interfaces/project_settings_repo.dart';

class UpdateExportSettings {

  final ProjectSettingsRepo repo;

  UpdateExportSettings(this.repo);

  Future<void> execute({
    required String? baseTable,
    required String? delimiter,
  }) async {
    //get the current settings and extract FieldConfigSettings
    final currentSettings = await repo.getSettings();
    final currentExportSettings = currentSettings.export;

    //copy the export settings with the new values
    final newExportSettings = currentExportSettings.copyWith(
      baseTable: baseTable,
      delimiter: delimiter,
    );

    //make a new settings object with the new Export Settings
    final newSettings = currentSettings.copyWith(export: newExportSettings);

    //updating the json to reflect this.
    await repo.updateSettings(newSettings);
  }
}