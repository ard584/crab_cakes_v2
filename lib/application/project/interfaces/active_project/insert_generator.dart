abstract class InsertGenerator {
  ({String sql, List<dynamic> data}) generate(
    String table,
    Map<String, dynamic> data,
  );
}
