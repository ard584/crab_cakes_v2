abstract class UpdateGenerator {
  ({String sql, List<dynamic> data}) generate(
    String table,
    Map<String, dynamic> data,
    dynamic identifier,
    dynamic key
  );
}
