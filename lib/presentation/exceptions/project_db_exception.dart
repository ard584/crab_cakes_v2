class ProjectDbException implements Exception {
  final ProjectDbErrorType type;
  final String message;
  final String? additionalMessage;
  final Object? cause;
  final StackTrace? stackTrace;

  ProjectDbException({
    required this.type,
    required this.message,
    this.additionalMessage,
    this.cause,
    this.stackTrace,
  });

  @override
    String toString() {
    var result = 'ProjectDbException($type): $message'
    '${additionalMessage != null ? ', $additionalMessage' : ''}';
    if (cause != null) result += '\nCause: $cause';
    return result;
  }
  
}

enum ProjectDbErrorType {
  openFailed,
  invalidSchema,
  readFailed,
}