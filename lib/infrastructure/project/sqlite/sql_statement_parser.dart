import 'package:ui_prototype/domain/project/schema/schema_parser.dart';

class SqlSchemaParser implements SchemaParser {

  String _removeComments(String sql) {
    final pattern = RegExp(
      r"("
      // Scan through anything surrounded by single quotes,
      // ignore two consecutive single quotes
      r"'(?:''|[^'])*'"
      // Scan through anything surrounded by double quotes,
      // ignore two consecutive single quotes
      r'|"(?:""|[^"])*"'
      // Match "/*" up to "*/"
      // (need \ escape character for regex parser to look for *)
      // [\s\S] matches everything (consume everything up to */)
      // *? Makes it consume everything up to the first occurrence of */
      // (matches smallest block it can find)
      r"|/\*[\s\S]*?\*/"
      // Match single line character up to newline
      r"|--.*"
      r")",
      multiLine: true,
    );

    return sql.splitMapJoin(
      pattern,
      onMatch: (Match match) {
        final text = match.group(0)!;
        // If it starts with a quote, it's a string literal — KEEP IT
        if (text.startsWith("'")) {
          return text;
        }
        // Otherwise, it's a comment — DISCARD IT
        return '';
      },
      onNonMatch: (String text) => text,
    );
  }

  String _normalizeSql(sql) {
    return sql.replaceAll(RegExp(r'\s+'), ' ').toUpperCase();
  }

    @override
    List<String> getStatements(sql) {
    // Clean & split
    final clean = _removeComments(sql);
    var split = _splitSqlStatements(clean);

    split = split.map((statement) => _normalizeSql(statement)).toList();

    return split;
  }

  List<String> _splitSqlStatements(String sql) {
    // Pattern matches:
    // 1. Single quoted strings: '(?:''|[^'])*'
    // 2. Double quoted identifiers: "(?:""|[^"])*"
    // 3. Semicolons: ;
    final pattern = RegExp(
      r"('(?:''|[^'])*'"
      r'|"(?:""|[^"])*"'
      r"|;)",
    );

    List<String> statements = [];
    int lastStart = 0;

    for (final match in pattern.allMatches(sql)) {
      final matchedText = match.group(0)!;

      if (matchedText == ';') {
        // Found a delimiter
        // Add everything from the last semicolon to this one.
        statements.add(sql.substring(lastStart, match.start).trim());
        lastStart = match.end;
      }
    }

    // Add the final chunk (if any) after the last semicolon
    final remainder = sql.substring(lastStart).trim();
    if (remainder.isNotEmpty) {
      statements.add(remainder);
    }

    return statements.where((s) => s.isNotEmpty).toList();
  }

}