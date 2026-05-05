import 'package:crab_cakes/application/project/interfaces/schema/schema_parser.dart';

class SqlSchemaParser implements SchemaParser {
  final Set<(String, String)> _delimiters = {
    ("'", "'"),
    ('"', '"'),
    ('`', '`'),
    ('[', ']'),
  };

  List<String> _buildRegexIdentifierParts() {
    final parts = _delimiters.map((pair) {
      final start = RegExp.escape(pair.$1);
      final end = RegExp.escape(pair.$2);

      if (start == end) {
        return "$start(?:$start$start|[^$start])*$end";
      } else {
        return '$start[^$end]*$end';
      }
    }).toList();

    return parts;
  }

  String _removeComments(String sql) {
    final parts = _buildRegexIdentifierParts();

    // Single-line comment
    parts.add(r"--.*");

    // Multi-line comment
    parts.add(r"/\*[\s\S]*?\*/");

    final patternString = "(${parts.join("|")})";

    final pattern = RegExp(patternString, multiLine: true);

    final startCharacters = _delimiters.map((delim) {
      return delim.$1;
    }).toSet();

    return sql.splitMapJoin(
      pattern,
      onMatch: (Match match) {
        final text = match.group(0)!;
        // If it starts with any start characters from the delim set, it's a string literal, keep
        if (startCharacters.any((startChar) {
          return text.startsWith(startChar);
        })) {
          return text;
        }

        // Otherwise, it's a comment, discard
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
    final parts = _buildRegexIdentifierParts();
    parts.add(';');

    final patternRegex = RegExp("(${parts.join("|")})");

    List<String> statements = [];
    int lastStart = 0;

    for (final match in patternRegex.allMatches(sql)) {
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
