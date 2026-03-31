//Dynamic class to store the results of a parsing operation
// Note: This class is extended to allow for:
//        Parse Success: The object simply stores whatever type it was created with
//        Parse Failure: The object simply stores an error message


class ParseResult<T> {
  const ParseResult();
}

class ParseOk<T> extends ParseResult<T> {
  final T value;

  ParseOk(this.value);
}

class ParseErr<T> extends ParseResult<T> {
  final String message;

  const ParseErr(this.message);
}