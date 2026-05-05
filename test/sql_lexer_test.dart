import 'package:crab_cakes/infrastructure/project/sqlite/sql_lexer.dart';
import 'package:flutter_test/flutter_test.dart';

void expectToken(Token token, TokenType type, String text) {
  expect(token.type, type);
  expect(token.text, text);
}

  const Set<String> keywords = {
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

void main() {
  group('SqlLexer - tokenize', () {
    test('tokenizes simple CREATE TABLE statement', () {
      final tokens = SqlLexer('CREATE TABLE users;', keywords: keywords).tokenize();

      expect(tokens.length, 4);

      expectToken(tokens[0], TokenType.keyword, 'CREATE');
      expectToken(tokens[1], TokenType.keyword, 'TABLE');
      expectToken(tokens[2], TokenType.identifier, 'users');
      expectToken(tokens[3], TokenType.symbol, ';');
    });

    test('keywords are case-insensitive', () {
      final tokens = SqlLexer('cReAtE tAbLe users;', keywords: keywords).tokenize();

      expectToken(tokens[0], TokenType.keyword, 'cReAtE');
      expectToken(tokens[1], TokenType.keyword, 'tAbLe');
    });

    test('identifiers that contain keywords are not keywords', () {
      final tokens = SqlLexer('CREATE TABLE select_data;', keywords: keywords).tokenize();

      expectToken(tokens[2], TokenType.identifier, 'select_data');
    });

    test('tokenizes single-quoted string', () {
      final tokens = SqlLexer("DEFAULT 'hello'", keywords: keywords).tokenize();

      final stringToken = tokens.firstWhere((t) => t.type == TokenType.string);

      expectToken(stringToken, TokenType.string, "'hello'");
    });

    test('tokenizes escaped single quote in string', () {
      final tokens = SqlLexer("DEFAULT 'it''s fine'", keywords: keywords).tokenize();

      final stringToken = tokens.firstWhere((t) => t.type == TokenType.string);

      expectToken(stringToken, TokenType.string, "'it''s fine'");
    });

    test('throws on unterminated string literal', () {
      expect(
        () => SqlLexer("DEFAULT 'oops", keywords: keywords).tokenize(),
        throwsA(isA<FormatException>()),
      );
    });

    test('tokenizes single-line comment', () {
      final tokens = SqlLexer('-- comment\nCREATE TABLE x;', keywords: keywords).tokenize();

      final comment = tokens.firstWhere((t) => t.type == TokenType.comment);

      expect(comment.text.startsWith('--'), isTrue);
    });

    test('tokenizes multi-line comment', () {
      final tokens = SqlLexer('/* hello */ CREATE TABLE x;', keywords: keywords).tokenize();

      final comment = tokens.firstWhere((t) => t.type == TokenType.comment);

      expect(comment.text, '/* hello */');
    });

    test('throws on unterminated multi-line comment', () {
      expect(
        () => SqlLexer('/* hello', keywords: keywords).tokenize(),
        throwsA(isA<FormatException>()),
      );
    });

    test('comment markers inside strings do not start comments', () {
      final tokens = SqlLexer(
        "CREATE TABLE x (c TEXT DEFAULT '/* not a comment */');", keywords: keywords
      ).tokenize();

      expect(tokens.where((t) => t.type == TokenType.comment), isEmpty);
    });

    test('quotes inside comments do not start strings', () {
      final tokens = SqlLexer(
        "/* 'not a string' */ CREATE TABLE x;", keywords: keywords
      ).tokenize();

      expect(tokens.where((t) => t.type == TokenType.string), isEmpty);
    });

    test('tokenizes symbols correctly', () {
      final tokens = SqlLexer('(a, b);', keywords: keywords).tokenize();

      expectToken(tokens[0], TokenType.symbol, '(');
      expectToken(tokens[1], TokenType.identifier, 'a');
      expectToken(tokens[2], TokenType.symbol, ',');
      expectToken(tokens[3], TokenType.identifier, 'b');
      expectToken(tokens[4], TokenType.symbol, ')');
      expectToken(tokens[5], TokenType.symbol, ';');
    });

    test('empty input produces no tokens', () {
      final tokens = SqlLexer('', keywords: keywords).tokenize();
      expect(tokens, isEmpty);
    });

    test('whitespace-only input produces no tokens', () {
      final tokens = SqlLexer('   \n\t ', keywords: keywords).tokenize();
      expect(tokens, isEmpty);
    });

    test('does not tokenize keywords inside longer identifiers', () {
      final tokens = SqlLexer('CREATE TABLE dropdown_selection;', keywords: keywords).tokenize();

      expectToken(tokens[0], TokenType.keyword, 'CREATE');
      expectToken(tokens[1], TokenType.keyword, 'TABLE');

      // "drop" is a substring but must NOT be treated as DROP
      expectToken(tokens[2], TokenType.identifier, 'dropdown_selection');

      // No DROP keyword token should exist
      expect(
        tokens.any(
          (t) => t.type == TokenType.keyword && t.text.toUpperCase() == 'DROP',
        ),
        isFalse,
      );
    });
  });
}
