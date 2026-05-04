import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crab_cakes/application/project/use_cases/save_table.dart';
import 'package:crab_cakes/infrastructure/providers/project_database_provider.dart';

final saveTableProvider = Provider<SaveTable>((ref) {
  final table = ref.watch(projectDatabaseProvider);
  return SaveTable(table);
});