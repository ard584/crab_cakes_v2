import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_prototype/application/project/use_cases/delete_rows.dart';
import 'package:ui_prototype/infrastructure/providers/project_database_provider.dart';

final deleteRowsProvider = Provider<DeleteRowsUseCase>((ref) {
  final repo = ref.watch(projectDatabaseProvider);
  final useCase = DeleteRowsUseCase(repo: repo);
  return useCase;

});