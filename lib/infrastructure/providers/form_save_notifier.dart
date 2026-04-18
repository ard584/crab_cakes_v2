import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_prototype/infrastructure/providers/save_table_provider.dart';
import 'package:ui_prototype/infrastructure/providers/settings_provider.dart';
import 'package:ui_prototype/presentation/view_models/project_input.dart';

final formSaveProvider = AsyncNotifierProvider<FormSaveNotifier, void>(() {
  return FormSaveNotifier();
});

class FormSaveNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> saveTable(TableInput table) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final saveTable = ref.read(saveTableProvider);
      saveTable(table);

      //fetch the CACHED project settings to extract the config map
      final settings = await ref.read(projectSettingsProvider.future);


      final configSettings = settings.fieldConfig;


      // Clear all fields after save except for sticky fields
      for (final attribute in table.attributes.values) {
        
        //Fetch the domain-level configuration for this specific field
        final config = configSettings.getConfig(
          table: table.name, 
          col: attribute.fields.name
        );
        

        final isSticky = config?.isSticky ?? false;

        if (!isSticky) {
          attribute.controller.clear();
        }
      }
    });
  }
}