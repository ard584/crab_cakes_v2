

import 'package:crab_cakes/application/settings/interfaces/project_settings_repo.dart';
import 'package:crab_cakes/domain/entities/settings/project_settings.dart';

class GetSettings {

  final ProjectSettingsRepo repo;

  GetSettings(this.repo);

  Future<ProjectSettings> execute() async {
    return repo.getSettings();
  }

}