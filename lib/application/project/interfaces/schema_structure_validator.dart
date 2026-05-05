
/// This class intends to provide a method for ensuring schema structures do not
/// contain any structure aside from chain or single table structures
/// 
/// *NOTE: THIS ASSUME INDIVIDUAL STATEMENTS HAVE ALREADY BEEN VALIDATED*
abstract class SchemaStructureValidator {
  Future<bool> isValid(List<String> statements);
}