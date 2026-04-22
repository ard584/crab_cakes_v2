import 'package:ui_prototype/application/settings/interfaces/project_settings_repo.dart';
import 'package:ui_prototype/domain/entities/settings/field_config.dart';


class GetFieldConfig {
  final ProjectSettingsRepo repo;

  GetFieldConfig(this.repo);

  Future<FieldConfig> execute(String table, String column) async {
    //get the current settings, and extract field config settings
    final currentSettings = await repo.getSettings();
    final currentConfigSettings = currentSettings.fieldConfig;

    //get the config for the specified table/col pair
    final config = currentConfigSettings.getConfig(table: table, col: column);

    return config ?? FieldConfig.defaultInstance();
  }

}