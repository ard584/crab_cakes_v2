import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_prototype/infrastructure/providers/settings_provider.dart';

//importing app level usecases
import 'package:ui_prototype/application/settings/usecases/get_field_config.dart';
import 'package:ui_prototype/application/settings/usecases/update_field_config.dart';

//importing domain level entities
import 'package:ui_prototype/domain/entities/settings/field_config.dart';


final updateFieldConfigUsecaseProvider = Provider<UpdateFieldConfig?>((ref) {
  final repo = ref.watch(projectSettingsRepoProvider);

  if(repo == null) return null;

  return UpdateFieldConfig(repo);
});

final getFieldConfigUsecaseProvider = Provider<GetFieldConfig?>((ref) {
  final repo = ref.watch(projectSettingsRepoProvider);
  if(repo == null) return null;

  return GetFieldConfig(repo);
});


//Provider to expose a field configuration object, regardless of upstream nulls
final effectiveFieldConfigProvider =
    FutureProvider.family<FieldConfig, FieldConfigKey>((ref, key) {
  
  //NOTE: We are depending on the CACHED version of the projectSettings here. 
  //      This is to prevent having to fetch the same settings from the DB, 
  //      translate from JSON to a class, and then return that class for EVERY
  //      one of the (potentially huge amount of) generated fields.
  //      INSTEAD, we use the cached project settings and derive the field 
  //      field config from THAT.
  //      NOTE2: while efficient, this does mean projectSettingsProvider needs to 
  //            be manually invalidated upon updating settings to ensure the 
  //            derived field configs are the most up-to-date 
  final settingsAsync = ref.watch(projectSettingsProvider);

  return settingsAsync.when(
    data: (settings) {
      return settings.fieldConfig.getConfig(table: key.tableName, col: key.colName) 
        ?? FieldConfig.defaultInstance();
    },
    loading: () => FieldConfig.defaultInstance(),
    error: (_, __) => FieldConfig.defaultInstance()
  );

});



//============================ HELPER CLASSES ==================================
class FieldConfigKey {
  final String tableName;
  final String colName;

  const FieldConfigKey({
    required this.tableName,
    required this.colName,
  });

  //AI SUGGESTED FUNCTIONS  V V V 
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FieldConfigKey &&
            runtimeType == other.runtimeType &&
            tableName == other.tableName &&
            colName == other.colName;
  }

  @override
  int get hashCode => Object.hash(tableName, colName);
}