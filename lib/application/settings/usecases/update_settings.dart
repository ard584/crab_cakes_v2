import 'package:crab_cakes/application/settings/interfaces/project_settings_repo.dart';
import 'package:crab_cakes/domain/entities/settings/project_settings.dart';

class UpdateSettings {

  final ProjectSettingsRepo repo;

  UpdateSettings(this.repo);

  Future<void> execute(ProjectSettings newSettings) async {
    return repo.updateSettings(newSettings);
  }
}