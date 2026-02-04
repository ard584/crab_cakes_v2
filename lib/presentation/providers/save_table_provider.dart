import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_prototype/application/use_cases/project/save_table.dart';
import 'package:ui_prototype/presentation/providers/project_database_provider.dart';

final saveTableProvider = Provider<SaveTable>((ref) {
  final db = ref.watch(projectDatabaseProvider);
  return SaveTable(db);
});