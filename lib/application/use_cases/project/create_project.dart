import 'package:ui_prototype/application/interfaces/project/project_database_builder.dart';
import 'package:ui_prototype/application/interfaces/project/schema/schema_parser.dart';
import 'package:ui_prototype/application/interfaces/project/schema/schema_validator.dart';

// Project File Path typedef for clarity
typedef ProjectFilePath = String;

// Custom exception for clarity
class UnsafeSchemaException implements Exception {
  final String? message;

  // Brackets mean positional optional parameter
  UnsafeSchemaException([this.message]);

  @override
  String toString() {
    return "UnsafeSchemaException: $message";
  }
}

class CreateProjectUseCase {
  final SchemaParser parser;
  final SchemaValidator validator;
  final ProjectDatabaseBuilder dbBuilder;

  CreateProjectUseCase({required this.validator, required this.dbBuilder, required this.parser});

  Future<ProjectFilePath> execute(String userSchema) async {

    // Parse sql
    final List<String> statements = parser.getStatements(userSchema);

    if (!validator.isSafe(statements)) {
      throw UnsafeSchemaException();
    }

    return dbBuilder.buildFromSchema(statements);
  }
}
