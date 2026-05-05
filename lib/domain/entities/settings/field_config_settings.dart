import 'package:crab_cakes/domain/entities/settings/field_config.dart';

class FieldConfigSettings {
 
  final Map<String, Map<String, FieldConfig>> configMap;

  FieldConfigSettings({required this.configMap});

  //method for getting all of the settings for a specific table
  Map<String, FieldConfig> getConfigsForTable({required String table}) {
    //returning a COPY of the specific table map
    return Map<String, FieldConfig>.from(configMap[table] ?? {});
  }

  //method for getting the setting of a specific table, column pair
  FieldConfig? getConfig({required String table, required String col}) {
    return configMap[table]?[col];
  }

  //Method that returns a NEW FieldConfigSettings instance
  //Reminder: SETTINGS CLASSES ARE INTENDED TO BE IMMUTABLE
  FieldConfigSettings setConfig({
    required String table,
    required String col,
    required FieldConfig config,
  }) {
    final newOuterMap = <String, Map<String, FieldConfig>>{};

    //recreating the current map
    for(final entry in configMap.entries) {
      newOuterMap[entry.key] = Map<String, FieldConfig>.from(entry.value);
    }

    //updating (or adding if not already present) specified table:config pair
    final tableMap = newOuterMap.putIfAbsent(table, ()=>{});
    tableMap[col] = config;

    //returning NEW INSTANCE of the FieldConfigSettings object
    return FieldConfigSettings(configMap: newOuterMap);
  }

  //method for converting the known map to JSON
  Map<String, dynamic> toJson() {
    final Map<String, Map<String, dynamic>> outMap = {};

    for(final tableEntry in configMap.entries) {
      //initializing the inner map
      final table = tableEntry.key;
      final colMap = outMap.putIfAbsent(table, () => {});

      for(final colEntry in tableEntry.value.entries) {
        final col = colEntry.key;
        final config = colEntry.value;

        colMap[col] = config.toJson();
      }
    }

    return outMap;
  }

  //method for taking json-like data and turning it into an instance of FieldConfigSettings
  factory FieldConfigSettings.fromJson(Map<String, dynamic> json) {
    final Map<String, Map<String, FieldConfig>> parsedConfigMap = {};

    //iterating over every entry
    for(final tableEntry in json.entries) {
      final table = tableEntry.key;
      final rawColMap = Map<String, dynamic>.from(tableEntry.value as Map);

      final Map<String, FieldConfig> parsedColMap = {};

      //iterating over the columns
      for( final colEntry in rawColMap.entries) {
        final col = colEntry.key;
        final rawConfig = Map<String, dynamic>.from(colEntry.value as Map);

        //creating a FieldConfig object for this specific column
        parsedColMap[col] = FieldConfig.fromJson(rawConfig);
      }
    
    //inserting the parsed column map for this specific table
    parsedConfigMap[table] = parsedColMap;
    }

    return FieldConfigSettings(configMap: parsedConfigMap);
  }

  factory FieldConfigSettings.empty() {
    return FieldConfigSettings(configMap: {});
  }

}