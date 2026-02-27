abstract class ProjectDatabaseBuilder {
  Future<String> buildFromSchema(List<String> statements);
}