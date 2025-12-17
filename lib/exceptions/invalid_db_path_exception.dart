class InvalidDbPathException implements Exception {
  final InvalidDbPathErrorType type;
  final String message;
  final String? additionalMessage;
  final Object? cause;
  final StackTrace? stackTrace;

  InvalidDbPathException({
    required this.type,
    required this.message,
    this.additionalMessage,
    this.cause,
    this.stackTrace,
  });

  @override
  String toString() {
    var result = 'InvalidDbPathException($type): $message'
    '${additionalMessage != null ? ', $additionalMessage' : ''}';
    if (cause != null) result += '\nCause: $cause';
    return result;
  }
  
}

enum InvalidDbPathErrorType {
  invalidPath,
  dbDoesNotExist
}