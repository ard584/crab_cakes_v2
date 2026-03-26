import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_prototype/infrastructure/providers/save_table_provider.dart';
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
    // Clear all fields after save
    for (final attribute in table.attributes.values) {
      attribute.controller.clear();
    }
    });
  }
}