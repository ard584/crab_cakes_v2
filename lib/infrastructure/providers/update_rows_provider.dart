import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crab_cakes/application/project/use_cases/update_rows.dart';
import 'package:crab_cakes/infrastructure/providers/project_database_provider.dart';

final updateRowsProvider = Provider<UpdateRowsUseCase>((ref) {
  final repo = ref.watch(projectDatabaseProvider);
  final useCase = UpdateRowsUseCase(repo: repo);
  return useCase;

});