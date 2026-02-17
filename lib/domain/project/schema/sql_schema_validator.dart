abstract class SqlSchemaValidator {
  bool isSafe(String schema);
  List<String> getValidStatements(String sql);
}