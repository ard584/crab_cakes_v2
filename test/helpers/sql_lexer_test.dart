import 'package:ui_prototype/services/helpers/sql_lexer.dart';
import 'package:flutter_test/flutter_test.dart';

void expectToken(Token token, TokenType type, String text) {
  expect(token.type, type);
  expect(token.text, text);
}

void main() {
  group('SqlLexer - tokenize', () {
    test('tokenizes simple CREATE TABLE statement', () {
      final tokens = SqlLexer('CREATE TABLE users;').tokenize();

      expect(tokens.length, 4);

      expectToken(tokens[0], TokenType.keyword, 'CREATE');
      expectToken(tokens[1], TokenType.keyword, 'TABLE');
      expectToken(tokens[2], TokenType.identifier, 'users');
      expectToken(tokens[3], TokenType.symbol, ';');
    });

    test('keywords are case-insensitive', () {
      final tokens = SqlLexer('cReAtE tAbLe users;').tokenize();

      expectToken(tokens[0], TokenType.keyword, 'cReAtE');
      expectToken(tokens[1], TokenType.keyword, 'tAbLe');
    });

    test('identifiers that contain keywords are not keywords', () {
      final tokens = SqlLexer('CREATE TABLE select_data;').tokenize();

      expectToken(tokens[2], TokenType.identifier, 'select_data');
    });

    test('tokenizes single-quoted string', () {
      final tokens = SqlLexer("DEFAULT 'hello'").tokenize();

      final stringToken = tokens.firstWhere((t) => t.type == TokenType.string);

      expectToken(stringToken, TokenType.string, "'hello'");
    });

    test('tokenizes escaped single quote in string', () {
      final tokens = SqlLexer("DEFAULT 'it''s fine'").tokenize();

      final stringToken = tokens.firstWhere((t) => t.type == TokenType.string);

      expectToken(stringToken, TokenType.string, "'it''s fine'");
    });

    test('throws on unterminated string literal', () {
      expect(
        () => SqlLexer("DEFAULT 'oops").tokenize(),
        throwsA(isA<FormatException>()),
      );
    });

    test('tokenizes single-line comment', () {
      final tokens = SqlLexer('-- comment\nCREATE TABLE x;').tokenize();

      final comment = tokens.firstWhere((t) => t.type == TokenType.comment);

      expect(comment.text.startsWith('--'), isTrue);
    });

    test('tokenizes multi-line comment', () {
      final tokens = SqlLexer('/* hello */ CREATE TABLE x;').tokenize();

      final comment = tokens.firstWhere((t) => t.type == TokenType.comment);

      expect(comment.text, '/* hello */');
    });

    test('throws on unterminated multi-line comment', () {
      expect(
        () => SqlLexer('/* hello').tokenize(),
        throwsA(isA<FormatException>()),
      );
    });

    test('comment markers inside strings do not start comments', () {
      final tokens = SqlLexer(
        "CREATE TABLE x (c TEXT DEFAULT '/* not a comment */');",
      ).tokenize();

      expect(tokens.where((t) => t.type == TokenType.comment), isEmpty);
    });

    test('quotes inside comments do not start strings', () {
      final tokens = SqlLexer(
        "/* 'not a string' */ CREATE TABLE x;",
      ).tokenize();

      expect(tokens.where((t) => t.type == TokenType.string), isEmpty);
    });

    test('tokenizes symbols correctly', () {
      final tokens = SqlLexer('(a, b);').tokenize();

      expectToken(tokens[0], TokenType.symbol, '(');
      expectToken(tokens[1], TokenType.identifier, 'a');
      expectToken(tokens[2], TokenType.symbol, ',');
      expectToken(tokens[3], TokenType.identifier, 'b');
      expectToken(tokens[4], TokenType.symbol, ')');
      expectToken(tokens[5], TokenType.symbol, ';');
    });

    test('empty input produces no tokens', () {
      final tokens = SqlLexer('').tokenize();
      expect(tokens, isEmpty);
    });

    test('whitespace-only input produces no tokens', () {
      final tokens = SqlLexer('   \n\t ').tokenize();
      expect(tokens, isEmpty);
    });
  });
}
