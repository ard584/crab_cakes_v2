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
      throw Exception("Error: Key $tableName does not exist in project's tables: ${project.tables.keys.join(', ')}");
    }

    _table = project.tables[tableName]!;

  }

  String generateColumns() {

    String columns = _table.attributes.keys.join(", ");
    return columns;

  }

  String generatePlaceholders() {

    int placeholderCount = _table.attributes.length;
    return List.filled(placeholderCount, '?').join(', ');
  }



  String generateInsertIntoTable() {

    String columns = generateColumns();
    String placeholders = generatePlaceholders();

    String statement = "INSERT INTO $tableName ( $columns ) VALUES ( $placeholders )";
    return statement;
  }
}

class FormSaveNotifier extends AsyncNotifier {

  @override
  FutureOr<dynamic> build() {

    state = const AsyncLoading();

    throw UnimplementedError();


    // TODO: implement build
    
  }
}