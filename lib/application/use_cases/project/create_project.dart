import 'package:ui_prototype/domain/project/database_builder/project_database_builder.dart';
import 'package:ui_prototype/domain/project/schema/sql_schema_validator.dart';

class CreateProjecUseCase {

  final SqlSchemaValidator validator;
  final ProjectDatabaseBuilder dbBuilder;

  CreateProjecUseCase({
    required this.validator,
    required this.dbBuilder
  });


  Future<ProjectFilePath> execute(String userSchema) async {
    if (!validator.isSafe(userSchema)) {
      throw UnsafeSchemaException();
    }

    return dbBuilder.buildFromSchema(userSchema);
  }
}