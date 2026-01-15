// Define enum for token type
enum TokenType { keyword, identifier, string, symbol, comment, unknown }

// Define class for token
class Token {
  final TokenType type;
  final String text;

  Token(this.type, this.text);

  @override
  String toString() {
    return "$type($text)";
  }
}

// Define class for lexer
class SqlLexer {
  final String sql;
  int _pos = 0;

  SqlLexer(this.sql);

  // Getter for checking if is at end of sql
  bool get isAtEnd => _pos >= sql.length;

  // Function for checking current character without advancing
  String _peek() => isAtEnd ? '\x00' : sql[_pos];

  // Function for advancing (returns current character then advances)
  String _advance() => sql[_pos++];

  // Function for looking ahead a certain number of characters
  // Returns NULL character if bounds exceeded
  String _lookahead(int n) => _pos + n < sql.length ? sql[_pos + n] : '\x00';

  // Functions for identifying tokens
  bool _isWhitespace(String c) => RegExp(r'\s').hasMatch(c);
  bool _isIdentifierStart(String c) => RegExp(r'[A-Za-z_]').hasMatch(c);
  bool _isIdentifierPart(String c) => RegExp(r'[A-Za-z0-9_]').hasMatch(c);
  bool _isSymbol(String c) => '(),;'.contains(c);

  // Consumer functions
  Token _consumeIdentifierOrKeyword() {
    // Get identifier parts
    final buffer = StringBuffer();
    while (!isAtEnd && _isIdentifierPart(_peek())) {
      buffer.write(_advance());
    }

    // Form to text and define keyword list
    final text = buffer.toString();
    final upper = text.toUpperCase();
    final Set<String> keywords = {
      'CREATE',
      'TABLE',
      'ALTER',
      'INDEX',
      'UNIQUE',
      'DROP',
      'PRAGMA',
      'SELECT',
    };

    if (keywords.contains(upper)) {
      return Token(TokenType.keyword, buffer.toString());
    }

    return Token(TokenType.identifier, buffer.toString());
  }

  Token _consumeString(String quoteChar) {
    // Consume the quote
    final buffer = StringBuffer();
    buffer.write(_advance());
    bool closed = false;

    // Iterate through
    while (!isAtEnd) {
      final c = _advance();
      buffer.write(c);

      // Check for another quote char
      if (c == quoteChar) {
        // Check if another quoteChar follows (escaped quotechar)
        if (!isAtEnd && _peek() == quoteChar) {
          // Write the quote char
          // Skip rest of this iteration
          // (Should not mark string as closed)
          buffer.write(_advance());
          continue;
        }

        // Otherwise, close the string
        closed = true;
        break;
      }
    }

    // If isAtEnd and not closed, assume unterminated string
    if (!closed) {
      throw FormatException('Unterminated string literal');
    }

    return Token(TokenType.string, buffer.toString());
  }

  Token _consumeSingleLineComment() {
    final buffer = StringBuffer();

    // Write the two comment characters
    buffer.write(_advance());
    buffer.write(_advance());

    // Iterate and write until newline character
    while (!isAtEnd && _peek() != '\n') {
      buffer.write(_advance());
    }

    // Return
    return Token(TokenType.comment, buffer.toString());
  }

  Token _consumeMultiLineComment() {
    final buffer = StringBuffer();

    // Consume the /* characters
    buffer.write(_advance());
    buffer.write(_advance());
    bool closed = false;

    // Iterate until find */ characters
    while (!isAtEnd) {
      final c = _advance();
      buffer.write(c);

      if (c == '*' && _peek() == '/') {
        // Consume the clash (ast already consumed)
        buffer.write(_advance());
        closed = true;
        break;
      }
    }

    // If is at end and not closed,
    // assume unterminated Multiline Comment
    if (!closed) {
      throw FormatException('Unterminated Multiline Comment');
    }

    return Token(TokenType.comment, buffer.toString());
  }
}
