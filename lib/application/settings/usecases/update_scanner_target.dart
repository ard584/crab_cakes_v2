import 'package:crab_cakes/application/settings/interfaces/project_settings_repo.dart';

class UpdateScannerTarget {
  final ProjectSettingsRepo repo;
  
  const UpdateScannerTarget(this.repo );

  Future<void> execute({String? targetTable, String? targetColumn}) async {
    final current = await repo.getSettings();

    //copy the current settings changing only the scanner settings
    final updated = current.copyWith(
      scanner: current.scanner.copyWith(
          targetTable: targetTable,
          targetColumn: targetColumn,
      ));

    await repo.updateSettings(updated);
  }
}