import 'package:crab_cakes/domain/entities/settings/project_settings.dart';

abstract class ProjectSettingsRepo {
  Future<ProjectSettings> getSettings();
  Future<void> updateSettings(ProjectSettings newSettings);
}