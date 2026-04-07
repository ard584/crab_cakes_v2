import 'package:flutter_riverpod/flutter_riverpod.dart';

//importing the active database (project) provider
import 'package:ui_prototype/infrastructure/providers/active_database_connection_provider.dart';

//importing use cases
import 'package:ui_prototype/application/settings/usecases/get_settings.dart';
import 'package:ui_prototype/application/settings/usecases/update_settings.dart';
import 'package:ui_prototype/application/settings/usecases/update_scanner_target.dart';  
import 'package:ui_prototype/application/settings/usecases/update_field_config.dart';

//importing interfaces 
import 'package:ui_prototype/application/settings/interfaces/project_settings_repo.dart';

//importing concrete infrastructure implementations
import 'package:ui_prototype/infrastructure/settings/project_settings_sqlite_repo.dart';

//importing domain-level types
import 'package:ui_prototype/domain/entities/settings/project_settings.dart';



//wiring infrastructure providers
final projectSettingsRepoProvider = Provider<ProjectSettingsRepo?>((ref) {
  final projectDb = ref.watch(activeDatabaseConnectionProvider);

  if (projectDb == null) return null;

  return ProjectSettingsSqliteRepo(projectDb);
});


//wiring the usecases together 
final getSettingsUsecaseProvider = Provider<GetSettings?>((ref) {
  final repo  = ref.watch(projectSettingsRepoProvider);

  if(repo == null) return null;

  return GetSettings(repo);
});

final updateSettingsUsecaseProvider = Provider<UpdateSettings?>((ref) {
  final repo = ref.watch(projectSettingsRepoProvider);

  if(repo == null) return null;

  return UpdateSettings(repo);
});

final updateScannerTargetUsecaseProvider = Provider<UpdateScannerTarget?>((ref) {
  final repo = ref.watch(projectSettingsRepoProvider);

  if(repo == null) return null;

  return UpdateScannerTarget(repo);
});

final updateFieldConfigUsecaseProvider = Provider<UpdateFieldConfig?>((ref) {
  final repo = ref.watch(projectSettingsRepoProvider);

  if(repo == null) return null;

  return UpdateFieldConfig(repo);
});

// Wiring complete


//exposing the settings
final projectSettingsProvider = FutureProvider<ProjectSettings?>((ref) async {
  final getSettingsUsecase = ref.watch(getSettingsUsecaseProvider);

  if(getSettingsUsecase == null) return null;

  return await getSettingsUsecase.execute();
});


