class SqliteProjectCreateRequest {
  final String title;
  final String? description;
  final String sql;

  SqliteProjectCreateRequest({
    required this.title,
    this.description,
    required this.sql,
  });
}