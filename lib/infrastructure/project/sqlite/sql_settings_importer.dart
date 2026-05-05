import 'package:sqlite3/sqlite3.dart';
import 'package:crab_cakes/application/project/interfaces/schema/project_settings_importer.dart';

class SqlSettingsImporter implements ProjectSettingsImporter{

  @override
  Future<void> replaceSettingsJson({
    required String dbPath, 
    required String settingsJson
    }) async {
    
    // open newly created project database
    final db = sqlite3.open(dbPath);
    
    //try to execute a fetch
    try {

      db.execute(''' 
      UPDATE __project_settings
      SET settings_json = ?
      WHERE id = 1
      ''', [settingsJson],
      );

      final changes = db.updatedRows;

      if (changes == 0) {
        throw Exception('No project settings row found to update.');
      }
      
    } finally {
      db.dispose();
    }
  }

}