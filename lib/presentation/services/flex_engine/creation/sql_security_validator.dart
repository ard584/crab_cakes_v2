import 'package:ui_prototype/presentation/services/flex_engine/creation/sql_lexer.dart';
/*
ATTACH is harmful as it attaches another database
DETACH only makes sense to be used with ATTACH
PRAGMA makes changes to SQLite behavior

VACUUM, REINDEX, ANALYZE are all functions that are irrelevant to creation

INSERT, UPDATE, DELETE, REPLACE, UPSERT are all for inserting data, which
should not happen in the creation flow. This can happen after.

DROP deletes tables, not needed in creation flow, dangerous if somehow gets
access to another database file

BEGIN, COMMIT, ROLLBACK, SAVEPOINT, RELEASE all relate to transactions. User
should not be able to start or stop transactions, may break safety features.

TRIGGER runs database operations automatically, not needed

SELECT for data leakage
*/

class SqlSecurityValidator {
  static const Set<String> keywordSet = {
    // DDL
    'CREATE',
    'ALTER',
    'DROP',
    'TRUNCATE',

    // Tables / schema
    'TABLE',
    'INDEX',
    'VIEW',
    'TRIGGER',

    // Constraints / modifiers
    'UNIQUE',
    'PRIMARY',
    'KEY',
    'FOREIGN',
    'REFERENCES',
    'WITHOUT',
    'ROWID',

    // DML
    'SELECT',
    'INSERT',
    'UPDATE',
    'DELETE',

    // Clauses
    'FROM',
    'WHERE',
    'JOIN',
    'INNER',
    'LEFT',
    'RIGHT',
    'ON',
    'GROUP',
    'BY',
    'HAVING',
    'ORDER',
    'LIMIT',
    'OFFSET',

    // SQLite-specific / dangerous
    'PRAGMA',
    'VACUUM',
    'ATTACH',
    'DETACH',

    // Control / meta
    'WITH',
    'AS',
  };

  // All tokens are already normalized to UPPERCASE
  // Example in SqlSecurityValidator
  static const Set<List<String>> allowedKeywordSequences = {
    ['ON', 'DELETE'],
    ['ON', 'UPDATE'],
  };

  static final Set<String> allowedSequenceStarters = allowedKeywordSequences
      .map((seq) => seq.first)
      .toSet();

  static const Set<String> disallowedKeywords = {
    "ATTACH",
    "DETACH",
    "PRAGMA",
    "LOAD_EXTENSION",
    "VACUUM",
    "REINDEX",
    "ANALYZE",
    "INSERT",
    "UPDATE",
    "DELETE",
    "REPLACE",
    "UPSERT",
    "DROP",
    "BEGIN",
    "COMMIT",
    "ROLLBACK",
    "SAVEPOINT",
    "RELEASE",
    "TRIGGER",
    "SELECT",
  };

  static const Set<List<String>> allowedKeywords = {
    ["CREATE", "TABLE"],
    ["ALTER", "TABLE"],
    ["CREATE", "INDEX"],
    ["CREATE", "UNIQUE", "INDEX"],
  };

  bool _containsForbiddenKeywords(List<Token> tokens) {
    int i = 0;

    while (i < tokens.length) {
      final token = tokens[i];

      // 1. PRIORITY: Check if we are standing at the start of a Safe Sequence.
      // e.g., We are at "ON", and the sequence is ["ON", "DELETE", "CASCADE"]
      final safeSequenceLength = _getMatchedSequenceLength(tokens, i);

      if (safeSequenceLength > 0) {
        // Found a whitelisted sequence!
        // "Consume" these tokens by skipping our index forward.
        // We skip the check entirely for these tokens.
        i += safeSequenceLength;
        continue;
      }

      // 2. CHECK: If not safe, is this individual token forbidden?
      if (token.type == TokenType.keyword &&
          disallowedKeywords.contains(token.text)) {
        return true; // Found a naked forbidden keyword
      }

      // Move to next token
      i++;
    }

    return false;
  }

  /// Returns the length of the matched sequence, or 0 if no match.
  int _getMatchedSequenceLength(List<Token> tokens, int startIndex) {
    final currentText = tokens[startIndex].text;

    // FAST FAIL: If the current token isn't the start of ANY allowed sequence, stop.
    // (You would need a Set<String> of all starting words, e.g. {"ON", "PRIMARY"})
    if (!allowedSequenceStarters.contains(currentText)) return 0;

    for (final sequence in allowedKeywordSequences) {
      // Optimization: Don't check if the sequence won't fit
      if (startIndex + sequence.length > tokens.length) continue;

      if (_isSequenceAt(tokens, startIndex, sequence)) {
        return sequence.length;
      }
    }
    return 0;
  }

  /// Checks if the tokens starting at [index] match the [sequence] exactly
  bool _isSequenceAt(List<Token> tokens, int index, List<String> sequence) {
    for (int offset = 0; offset < sequence.length; offset++) {
      final token = tokens[index + offset];

      // Strict check: Must be a keyword and must match text
      if (token.type != TokenType.keyword || token.text != sequence[offset]) {
        return false;
      }
    }
    return true;
  }

  String _normalizeSql(sql) {
    return sql.replaceAll(RegExp(r'\s+'), ' ').toUpperCase();
  }

  bool _hasModifier(List<Token> tokens) {
    if (tokens.isEmpty) return false;

    // Find last meaningful token
    Token? lastToken;
    for (final token in tokens.reversed) {
      if (token.type != TokenType.comment) {
        lastToken = token;
        break;
      }
    }

    if (lastToken == null) return false;

    // If last token is not a symbol that is a closing parenthesis,
    // Return true
    return !(lastToken.type == TokenType.symbol && lastToken.text == ')');
  }

  bool _startsWithAllowedPrefix(List<Token> tokens) {
    for (final prefix in allowedKeywords) {
      if (tokens.length < prefix.length) continue;

      bool matches = true;
      for (int i = 0; i < prefix.length; i++) {
        final token = tokens[i];

        if (token.type != TokenType.keyword || token.text != prefix[i]) {
          matches = false;
          break;
        }
      }

      if (matches) return true;
    }

    return false;
  }

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

  List<String> getValidStatements(sql) {
    // Clean & split
    final clean = _removeComments(sql);
    var split = _splitSqlStatements(clean);

    split = split.map((statement) => _normalizeSql(statement)).toList();

    return split;
  }

  bool isSafe(rawSql) {
    final statements = getValidStatements(rawSql);

    // Iterate through statements
    for (final statement in statements) {
      List<Token> tokens;

      // Tokenize
      try {
        tokens = SqlLexer(statement, keywords: keywordSet).tokenize();
      } catch (e) {
        if (e is FormatException) return false;
        rethrow; // rethrow other unexpected errors
      }

      // Check if statement is not allowed or has disallowed keywords
      if (_containsForbiddenKeywords(tokens)) return false;
      if (!_startsWithAllowedPrefix(tokens)) return false;
      if (_hasModifier(tokens)) return false;
    }

    return true;
  }
}