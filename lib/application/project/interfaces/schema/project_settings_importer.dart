abstract interface class ProjectSettingsImporter {
  Future<void> replaceSettingsJson({
    required String dbPath,
    required String settingsJson,
  });
}