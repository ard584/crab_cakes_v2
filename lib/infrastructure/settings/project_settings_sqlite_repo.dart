import 'dart:convert';
import 'package:sqlite3/sqlite3.dart';
import 'package:ui_prototype/application/settings/interfaces/project_settings_repo.dart';
import 'package:ui_prototype/domain/entities/settings/project_settings.dart';


class ProjectSettingsSqliteRepo implements ProjectSettingsRepo {
  final Database db;

  //putting the name of the settings table as a variable to make changing it
  //(if necessary) in the future easier.
  final String settingsTableName = "__project_settings";


  ProjectSettingsSqliteRepo(this.db);

  @override
  Future<ProjectSettings> getSettings() async {
    final result = db.select("SELECT settings_json FROM $settingsTableName WHERE id=1 ",);

    if(result.isEmpty) {
      //return an EMPTY project settings object
      return ProjectSettings.empty();
    }

    final rawSettings = result.first;
    final jsonString = rawSettings['settings_json'] as String;
    final decoded = jsonDecode(jsonString) as Map<String, dynamic>;    
    final settings = ProjectSettings.fromJson(decoded);

    return settings;
  }
 
  @override
  Future<void> updateSettings(ProjectSettings newSettings) async {
    final settingsString = jsonEncode(newSettings.toJson());

    //insert the new row, but also handle if the row doesn't exist (for some reason)
    db.execute('''
      INSERT INTO $settingsTableName (id, settings_json)
      VALUES (1, ?)
      ON CONFLICT(id) DO UPDATE SET settings_json = excluded.settings_json
      ''',
      [settingsString],
    );
  }
}