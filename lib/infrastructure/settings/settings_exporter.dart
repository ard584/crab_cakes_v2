import 'dart:convert';
import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

import 'package:ui_prototype/application/settings/interfaces/project_settings_exporter.dart';
import 'package:ui_prototype/infrastructure/project/project_json_integrity_service.dart';

class SettingsExporter implements ProjectSettingsExporter {
  final Database db;
  final ProjectJsonIntegrityService integrityService;

  SettingsExporter(
    this.db,
    this.integrityService,
  );

  // putting the name of the settings table as a variable to make changing it
  // (if necessary) in the future easier.
  final String settingsTableName = "__project_settings";

  @override
  Future<void> export(String filePath) async {
    final result = db.select(
      "SELECT settings_json FROM $settingsTableName WHERE id = 1",
    );

    if (result.isEmpty) return;

    final settingsJson = result.first['settings_json'] as String;

    // Decode first so the integrity service signs a normalized JSON payload,
    // not whatever whitespace/formatting happened to be stored.
    final payload = jsonDecode(settingsJson) as Map<String, dynamic>;

    final exportedJson = integrityService.createSignedJson(payload);

    // add extension to the end of the file name
    if (!filePath.toLowerCase().endsWith('.json')) {
      filePath = "$filePath.json";
    }

    final file = File(filePath);
    final sink = file.openWrite();

    try {
      sink.write(exportedJson);
    } finally {
      await sink.close();
    }
  }
}