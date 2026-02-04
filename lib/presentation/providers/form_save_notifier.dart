import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_prototype/presentation/providers/save_table_provider.dart';
import 'package:ui_prototype/presentation/view_models/project_input.dart';

final formSaveProvider = AsyncNotifierProvider<FormSaveNotifier, void>(() {
  return FormSaveNotifier();
});

class FormSaveNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> saveTable(TableInput table) async {
    state = const AsyncLoading();

    try {
      final saveTable = ref.read(saveTableProvider);
      await saveTable(table);
      state = const AsyncData(null);
    }
    catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}