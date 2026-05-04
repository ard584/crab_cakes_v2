import 'package:crab_cakes/application/settings/interfaces/project_settings_repo.dart';

class UpdateColumnOrderUsecase {
  final ProjectSettingsRepo repository;

  UpdateColumnOrderUsecase(this.repository);

  Future<void> execute({
    required String tableName,
    required List<String> columnOrder,
  }) async {
    final currentSettings = await repository.getSettings();
    
    final updatedColumnOrder = Map<String, List<String>>.from(
      currentSettings.columnOrder,
    );
    updatedColumnOrder[tableName] = columnOrder;

    final updatedSettings = currentSettings.copyWith(
      columnOrder: updatedColumnOrder,
    );

    await repository.updateSettings(updatedSettings);
  }
}