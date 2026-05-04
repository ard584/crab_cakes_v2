import 'package:ui_prototype/application/project/interfaces/schema/project_database_builder.dart';
import 'package:ui_prototype/application/project/interfaces/schema/schema_parser.dart';
import 'package:ui_prototype/application/project/interfaces/schema/schema_validator.dart';
import 'package:ui_prototype/application/project/interfaces/schema_structure_validator.dart';

// Project File Path typedef for clarity
typedef ProjectFilePath = String;

// Custom exception for unsafe schema statements
class UnsafeSchemaException implements Exception {
  final String? message;

  // Brackets mean positional optional parameter
  UnsafeSchemaException([this.message]);

  @override
  String toString() {
    return "UnsafeSchemaException: $message";
  }
}

// Custom exception invalid schema structures (trees, multi parent, etc.)
class InvalidSchemaException implements Exception {
  final String? message;

  // Brackets mean positional optional parameter
  InvalidSchemaException([this.message]);

  @override
  String toString() {
    return "InvalidSchemaException: $message";
  }
}

class CreateProjectUseCase {
  final SchemaParser parser;
  final SchemaValidator statementValidator;
  final SchemaStructureValidator structureValidator;
  final ProjectDatabaseBuilder dbBuilder;

  CreateProjectUseCase({
    required this.statementValidator,
    required this.structureValidator, 
    required this.dbBuilder, 
    required this.parser});

  Future<ProjectFilePath> execute(String userSchema) async {

    // Parse sql
    final List<String> statements = parser.getStatements(userSchema);

    // validate the individual statements
    if (!statementValidator.isSafe(statements)) {
      throw UnsafeSchemaException();
    }

    // validate the overall structure of the schema
    final bool validStructure = await structureValidator.isValid(statements);
    if (!validStructure) {
      throw InvalidSchemaException(
        "Schemas should only be individual tables or chain structures!");
    }

    return dbBuilder.buildFromSchema(statements);
  }
}
