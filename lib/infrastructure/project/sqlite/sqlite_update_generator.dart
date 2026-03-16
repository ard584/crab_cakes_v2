import 'package:ui_prototype/application/project/interfaces/active_project/update_generator.dart';

class SqliteUpdateGenerator implements UpdateGenerator {
  String _generateUpdateStatement(
    String table,
    Map<String, dynamic> data,
    dynamic identifier,
    dynamic key
  ) {
    String sql = "UPDATE $table ";

    List<String> sets = [];

    for (final String columnName in data.keys) {
      sets.add("SET $columnName = ?");
    }

    sql += sets.join(", ");
    sql += " WHERE $identifier = $key";
    sql += ";\n";
    return sql;
  }

  List<dynamic> _generateValues(Map<String, dynamic> data) {
    return data.values.toList();
  }

  @override
  ({List<dynamic> data, String sql}) generate(
    String table,
    Map<String, dynamic> data,
    dynamic identifier,
    dynamic key
  ) {
    final sql = _generateUpdateStatement(table, data, identifier, key);
    final values = _generateValues(data);

    return (sql: sql, data: values);
  }
}
