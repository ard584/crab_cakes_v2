import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_prototype/presentation/providers/flex_form_provider.dart';

class SQLInsertGenerator {
  final ProjectInput project;
  final String tableName;
  late TableInput _table;

  SQLInsertGenerator({required this.project, required this.tableName}) {
    print("PROJECT TABLES: ${project.tables.keys}");

    // Check if tableName exists in project
    if (!project.tables.containsKey(tableName)) {
      throw Exception(
        "Error: Key $tableName does not exist in project's tables: ${project.tables.keys.join(', ')}",
      );
    }

    _table = project.tables[tableName]!;
  }

  String _generateColumns() {
    String columns = _table.attributes.keys.map((key) => "'$key'").join(', ');
    return columns;
  }

  String _generatePlaceholders() {
    int placeholderCount = _table.attributes.length;
    return List.filled(placeholderCount, '?').join(', ');
  }

  String generateInsertIntoTable() {
    String columns = _generateColumns();
    String placeholders = _generatePlaceholders();

    String statement =
        "INSERT INTO $tableName ( $columns ) VALUES ( $placeholders )";
    return statement;
  }
}

final formSaveProvider = AsyncNotifierProvider<FormSaveNotifier, void>(() {
  return FormSaveNotifier();
});

class FormSaveNotifier extends AsyncNotifier {
  @override
  FutureOr<dynamic> build() {
    return false;
  }

  Future<void> saveProject(
    final ProjectInput project,
    final String tableName,
  ) async {
    // Create SQLInsertGenerator
    final generator = SQLInsertGenerator(
      project: project,
      tableName: tableName,
    );
    print(generator.generateInsertIntoTable());
  }

  // TODO: implement build
}
