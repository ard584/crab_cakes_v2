import 'package:crab_cakes/application/settings/interfaces/project_settings_repo.dart';
import 'package:crab_cakes/domain/entities/settings/field_config.dart';

class UpdateFieldConfig {
  final ProjectSettingsRepo repo;

  UpdateFieldConfig(this.repo);
  
  Future<void> execute({
    required String table, 
    required String column, 
    required FieldConfig config
    }) async {
    
    //get the current settings and extract FieldConfigSettings
    final currentSettings = await repo.getSettings();
    final currentConfigSettings = currentSettings.fieldConfig;

    //make a new instance of the config settings with the changes
    final newConfigSettings = currentConfigSettings.setConfig(table: table, col: column, config: config);

    //Make a new settings object and use this to change the settings via repo
    await repo.updateSettings(
      currentSettings.copyWith(fieldConfig: newConfigSettings)
    );
  }
}