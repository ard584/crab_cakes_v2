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
  String _peek() => sql[_pos];

  // Function for advancing (returns current character then advances)
  String _advance() => sql[_pos++];

  // Function for looking ahead a certain number of characters
  // Returns NULL character if bounds exceeded
  String _lookahead(int n) =>
  _pos + n < sql.length ? sql[_pos + n] : '\x00';
}