import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_prototype/infrastructure/providers/active_database_connection_provider.dart';

import 'package:ui_prototype/application/export/interfaces/data_exporter.dart';
import 'package:ui_prototype/application/export/interfaces/save_location_picker.dart';

import 'package:ui_prototype/application/export/usecases/export_data.dart';

import 'package:ui_prototype/infrastructure/export/native_save_location_picker.dart';
import 'package:ui_prototype/infrastructure/export/sqlite_data_exporter.dart';


final saveLocationPickerProvider = Provider<SaveLocationPicker>((ref) {
  return NativeSaveLocationPicker();
});

final dataExporterProvider = Provider<DataExporter?>((ref) {

  final db = ref.watch(activeDatabaseConnectionProvider);
  
  if(db == null) return null;

  return SqliteDataExporter(db);
});


final exportDataUsecaseProvider = Provider<ExportData?>((ref) {
  final picker = ref.watch(saveLocationPickerProvider);
  final exporter = ref.watch(dataExporterProvider);

  if(exporter == null) return null;

  return ExportData(picker, exporter);
});

final exportBaseTablesProvider = FutureProvider<List<String>>((ref) async {
  final exporter = ref.watch(dataExporterProvider);

  if (exporter == null) return [];

  return exporter.getBaseTables();
});