import 'package:crab_cakes/application/project/interfaces/active_project/insert_generator.dart';

class SQLInsertGenerator implements InsertGenerator {
  bool _isValid(dynamic value) {
    if (value == null) return false;
    if (value is String && value.isEmpty) return false;
    return true;
  }

  Map<String, dynamic> _filterValues(Map<String, dynamic> values) {
    final map = <String, dynamic>{};

    for (final value in values.entries) {
      if (_isValid(value.value)) {
        map[value.key] = value.value;
      }
    }

    return map;
  }

  List<dynamic> _generateValues(Map<String, dynamic> values) {
    final filtered = _filterValues(values);
    return filtered.values.toList();
  }

  String _generateInsertStatement({
    required String tableName,
    required Map<String, dynamic> values,
  }) {
    final filtered = _filterValues(values);

    if (filtered.entries.isEmpty) {
      throw Exception("Insert statement value map is empty");
    }

    final columns = filtered.keys.join(', ');
    final placeholders = List.filled(filtered.length, '?').join(', ');

    return "INSERT INTO $tableName ($columns) VALUES ($placeholders)";
  }

  @override
  ({List<dynamic> data, String sql}) generate(
    String table,
    Map<String, dynamic> data,
  ) {
    final statement = _generateInsertStatement(tableName: table, values: data);
    final values = _generateValues(data);

    return (sql: statement, data: values);
  }
}
