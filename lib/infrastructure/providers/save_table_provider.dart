import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_prototype/application/use_cases/project/save_table.dart';
import 'package:ui_prototype/infrastructure/providers/project_database_provider.dart';

final saveTableProvider = Provider<SaveTable>((ref) {
  final table = ref.watch(projectDatabaseProvider);
  return SaveTable(table);
});