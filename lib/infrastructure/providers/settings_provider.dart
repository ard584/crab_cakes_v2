import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_prototype/application/settings/usecases/update_export_settings.dart';

//importing the active database (project) provider
import 'package:ui_prototype/infrastructure/providers/active_database_connection_provider.dart';

//importing use cases
import 'package:ui_prototype/application/settings/usecases/get_settings.dart';
import 'package:ui_prototype/application/settings/usecases/update_settings.dart';
import 'package:ui_prototype/application/settings/usecases/update_scanner_target.dart';  
import 'package:ui_prototype/application/settings/usecases/export_settings.dart';

//importing interfaces 
import 'package:ui_prototype/application/settings/interfaces/project_settings_repo.dart';
import 'package:ui_prototype/application/settings/interfaces/project_settings_exporter.dart';
import 'package:ui_prototype/application/export/interfaces/save_location_picker.dart';

//importing concrete infrastructure implementations
import 'package:ui_prototype/infrastructure/settings/project_settings_sqlite_repo.dart';
import 'package:ui_prototype/infrastructure/settings/settings_exporter.dart';
import 'package:ui_prototype/infrastructure/export/native_save_location_picker.dart';

//importing domain-level types
import 'package:ui_prototype/domain/entities/settings/project_settings.dart';


import 'package:ui_prototype/application/catch_history/usecases/update_column_order_usecase.dart';

//wiring infrastructure providers

final saveLocationPickerProvider = Provider<SaveLocationPicker>((ref) {
  return NativeSaveLocationPicker();
});

final projectSettingsRepoProvider = Provider<ProjectSettingsRepo?>((ref) {
  final projectDb = ref.watch(activeDatabaseConnectionProvider);

  if (projectDb == null) return null;

  return ProjectSettingsSqliteRepo(projectDb);
});

final projcetSettingsExporterProvider = Provider<ProjectSettingsExporter?>((ref) {
  final projectDb = ref.watch(activeDatabaseConnectionProvider);

  if(projectDb == null) return null;

  return SettingsExporter(projectDb);
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

final updateExportSettingsUsecaseProvider = Provider<UpdateExportSettings?>((ref) {
  final repo = ref.watch(projectSettingsRepoProvider);

  if(repo == null) return null;

  return UpdateExportSettings(repo);
});

final exportSettingsUsecaseProvider = Provider<ExportSettings?>((ref) {
  final saveLocationPicker = ref.watch(saveLocationPickerProvider);
  final exporter = ref.watch(projcetSettingsExporterProvider);

  if(exporter == null) return null;

  return ExportSettings(exporter, saveLocationPicker);
});

final updateColumnOrderUsecaseProvider = Provider<UpdateColumnOrderUsecase?>((ref) {
  final repo = ref.watch(projectSettingsRepoProvider);
  return repo != null ? UpdateColumnOrderUsecase(repo) : null;
});


// Wiring complete


//exposing the settings
final projectSettingsProvider = FutureProvider<ProjectSettings>((ref) async {
  final getSettingsUsecase = ref.watch(getSettingsUsecaseProvider);

  if(getSettingsUsecase == null) return ProjectSettings.empty();

  return await getSettingsUsecase.execute();
});



